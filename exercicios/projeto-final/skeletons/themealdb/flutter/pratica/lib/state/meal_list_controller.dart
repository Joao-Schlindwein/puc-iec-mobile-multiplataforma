import 'package:flutter/foundation.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';

enum LoadStatus { loading, ready, error }

/// Filtro local por nome: mantém quem tem `query` no nome, sem diferenciar
/// maiúsculas/minúsculas e ignorando espaços nas pontas.
List<MealSummary> filterMeals(List<MealSummary> meals, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return meals;
  return meals.where((m) => m.name.toLowerCase().contains(q)).toList();
}

/// Estado da tela de receitas: lista inicial, categorias, categoria
/// escolhida (filtrada pela API) e busca.
///
/// Busca em "Todas": pergunta à API (`search.php?s=`), que procura no
/// catálogo inteiro; enquanto a resposta não chega (ou se falhar), mostra o
/// filtro local da lista já carregada. Busca dentro de uma categoria:
/// filtra localmente o que a categoria trouxe.
class MealListController extends ChangeNotifier {
  final TheMealDbApi _api;
  final Duration _searchDebounce;

  MealListController(
    this._api, {
    Duration searchDebounce = const Duration(milliseconds: 400),
  }) : _searchDebounce = searchDebounce;

  LoadStatus _status = LoadStatus.loading;
  String? _errorMessage;
  bool _offline = false;

  List<MealSummary> _all = const [];
  List<MealSummary> _categoryMeals = const [];
  List<String> _categories = const [];
  String? _selectedCategory;

  String _searchText = '';
  List<MealSummary>? _searchResults;
  bool _searching = false;
  Future<void>? _pendingSearch;

  /// Contadores de requisição: se o usuário trocar de categoria ou continuar
  /// digitando antes da resposta chegar, a resposta antiga é descartada.
  int _categoryRequestId = 0;
  int _searchRequestId = 0;

  bool _disposed = false;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get offline => _offline;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchText => _searchText;

  /// `true` enquanto a busca na API está em andamento.
  bool get searching => _searching;

  /// O que a grade mostra.
  List<MealSummary> get visible {
    if (_selectedCategory != null) {
      return filterMeals(_categoryMeals, _searchText);
    }
    if (_searchText.trim().isEmpty) return _all;
    return _searchResults ?? filterMeals(_all, _searchText);
  }

  /// Para os testes esperarem a busca com debounce terminar.
  @visibleForTesting
  Future<void> get pendingSearch => _pendingSearch ?? Future.value();

  Future<void> load() async {
    _setLoading();
    try {
      final results = await Future.wait([
        _api.fetchList(),
        // Sem as categorias o app ainda funciona (só some o filtro), então
        // uma falha aqui não derruba a lista.
        _api.fetchCategories().catchError((_) => <String>[]),
      ]);
      _all = results[0] as List<MealSummary>;
      _categories = results[1] as List<String>;
      if (_selectedCategory != null) {
        _categoryMeals = await _api.fetchByCategory(_selectedCategory!);
      }
      _status = LoadStatus.ready;
    } on ApiException catch (e) {
      _setError(e);
    }
    _notify();
    _scheduleSearch();
  }

  Future<void> selectCategory(String? category) async {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    final requestId = ++_categoryRequestId;

    if (category == null) {
      _categoryMeals = const [];
      // Volta para a lista inicial; se ela falhou antes, tenta de novo.
      if (_all.isEmpty) return load();
      _status = LoadStatus.ready;
      _notify();
      _scheduleSearch();
      return;
    }

    _setLoading();
    _notify();
    try {
      final meals = await _api.fetchByCategory(category);
      if (requestId != _categoryRequestId) return;
      _categoryMeals = meals;
      _status = LoadStatus.ready;
    } on ApiException catch (e) {
      if (requestId != _categoryRequestId) return;
      _setError(e);
    }
    _notify();
  }

  void setSearch(String text) {
    if (text == _searchText) return;
    _searchText = text;
    _notify();
    _scheduleSearch();
  }

  /// "Tentar de novo" da tela de erro.
  Future<void> retry() {
    final category = _selectedCategory;
    if (_all.isEmpty || category == null) return load();
    _selectedCategory = null;
    return selectCategory(category);
  }

  /// Agenda a busca na API (com debounce) quando faz sentido: há texto e
  /// nenhuma categoria escolhida.
  void _scheduleSearch() {
    final query = _searchText.trim();
    final requestId = ++_searchRequestId;
    _searchResults = null;
    _searching = query.isNotEmpty &&
        _selectedCategory == null &&
        _status == LoadStatus.ready;
    if (!_searching) {
      _pendingSearch = null;
      return;
    }
    _pendingSearch = Future.delayed(_searchDebounce, () async {
      if (requestId != _searchRequestId || _disposed) return;
      try {
        final results = await _api.search(query);
        if (requestId != _searchRequestId) return;
        _searchResults = results;
      } on ApiException {
        // Sem rede: continua valendo o filtro local da lista carregada.
        if (requestId != _searchRequestId) return;
      }
      _searching = false;
      _notify();
    });
  }

  void _setLoading() {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _offline = false;
  }

  void _setError(ApiException e) {
    _status = LoadStatus.error;
    _errorMessage = e.message;
    _offline = e.offline;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
