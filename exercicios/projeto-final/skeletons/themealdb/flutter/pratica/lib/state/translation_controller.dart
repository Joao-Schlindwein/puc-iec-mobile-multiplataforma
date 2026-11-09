import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';
import '../translation/recipe_translator.dart';

enum TranslationStatus { preparing, ready, unavailable }

/// Mostra as receitas em português sem mexer nos dados.
///
/// Os dados (API, cache, favoritos, compras) continuam em inglês, o idioma da
/// fonte; só o que aparece na tela é traduzido. Assim as fotos dos
/// ingredientes, que a API monta pelo nome em inglês, continuam funcionando, e
/// desligar a tradução mostra o original na hora.
///
/// [text] é síncrono para as telas: devolve a tradução se ela já existe; se
/// não, devolve o original, agenda a tradução e avisa quando ela chega.
class TranslationController extends ChangeNotifier {
  static const prefKey = 'translate_recipes_pt';

  final RecipeTranslator _translator;

  TranslationController(this._translator);

  bool _enabled = true;
  TranslationStatus _status = TranslationStatus.preparing;
  final Map<String, String> _cache = {};
  final List<String> _queue = [];
  final Set<String> _queued = {};
  Completer<void>? _draining;
  bool _disposed = false;

  bool get enabled => _enabled;
  TranslationStatus get status => _status;

  /// `true` quando a tela está, de fato, em português.
  bool get translating => _enabled && _status == TranslationStatus.ready;

  /// Para os testes esperarem a fila de traduções esvaziar.
  @visibleForTesting
  Future<void> get idle => _draining?.future ?? Future.value();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(prefKey) ?? true;
    _notify();
    if (_enabled) await _prepare();
  }

  /// Liga/desliga e lembra a escolha. Ligar de novo tenta baixar o modelo,
  /// se da última vez não deu.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, value);
    if (value && _status != TranslationStatus.ready) await _prepare();
  }

  /// Texto para mostrar agora.
  String text(String original) {
    if (!_enabled || original.trim().isEmpty) return original;
    final cached = _cache[original];
    if (cached != null) return cached;
    if (_status != TranslationStatus.unavailable && _queued.add(original)) {
      _queue.add(original);
      _drain();
    }
    return original;
  }

  /// Só consulta: a tradução que já existe, sem agendar nada. Usado pela
  /// busca local, que roda durante o desenho da tela.
  String peek(String original) =>
      _enabled ? (_cache[original] ?? original) : original;

  /// A receita inteira traduzida, esperando todas as partes (para
  /// compartilhar um texto já pronto).
  Future<MealDetail> translateDetail(MealDetail d) async {
    if (!translating) return d;
    final steps = await Future.wait(d.steps.map(_translate));
    final names = await Future.wait(
      d.ingredients.map((i) => _translate(i.name)),
    );
    final measures = await Future.wait(
      d.ingredients.map((i) => _translate(i.measure)),
    );
    return MealDetail(
      id: d.id,
      name: await _translate(d.name),
      category: d.category,
      area: await _translate(d.area),
      thumbUrl: d.thumbUrl,
      instructions: steps.join('\n'),
      tags: await Future.wait(d.tags.map(_translate)),
      ingredients: [
        for (var i = 0; i < d.ingredients.length; i++)
          Ingredient(name: names[i], measure: measures[i]),
      ],
      youtubeUrl: d.youtubeUrl,
      sourceUrl: d.sourceUrl,
    );
  }

  /// O texto da busca em inglês, para a API (que só conhece inglês).
  /// Sem tradutor, a busca vai como foi digitada.
  Future<String> toEnglish(String query) async {
    if (!translating || query.trim().isEmpty) return query;
    try {
      return (await _translator.toEnglish(query)).trim();
    } on Object {
      return query;
    }
  }

  Future<void> _prepare() async {
    _status = TranslationStatus.preparing;
    _notify();
    try {
      await _translator.prepare();
      _status = TranslationStatus.ready;
    } on Object {
      _status = TranslationStatus.unavailable;
      _queue.clear();
      _queued.clear();
    }
    _notify();
    if (_status == TranslationStatus.ready) _drain();
  }

  Future<String> _translate(String original) async {
    if (original.trim().isEmpty) return original;
    final cached = _cache[original];
    if (cached != null) return cached;
    try {
      return _cache[original] = await _translator.toPortuguese(original);
    } on Object {
      return original;
    }
  }

  /// Traduz a fila um texto por vez e redesenha a cada lote.
  Future<void> _drain() async {
    if (_draining != null || _status != TranslationStatus.ready) return;
    final done = _draining = Completer<void>();
    // `text()` é chamado enquanto a tela desenha: começa só depois, para
    // nunca avisar a tela no meio do próprio desenho.
    await Future<void>.value();
    var sinceNotify = 0;
    while (_queue.isNotEmpty &&
        !_disposed &&
        _status == TranslationStatus.ready) {
      final original = _queue.removeAt(0);
      try {
        _cache[original] = await _translator.toPortuguese(original);
      } on Object {
        // Falhou só este texto: fica o original, e não tenta de novo.
        _cache[original] = original;
      }
      _queued.remove(original);
      if (++sinceNotify >= 8) {
        sinceNotify = 0;
        _notify();
      }
    }
    _draining = null;
    _notify();
    done.complete();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _translator.dispose();
    super.dispose();
  }
}
