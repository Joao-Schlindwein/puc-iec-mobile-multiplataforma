import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/state/meal_list_controller.dart';
import 'package:themeal_final/state/translation_controller.dart';
import 'package:themeal_final/translation/recipe_translator.dart';

import 'fake_api.dart';

/// Tradutor falso: um dicionário, no lugar do ML Kit (que precisa do
/// aparelho). Texto fora do dicionário volta igual; `failOn` simula falha.
class FakeTranslator implements RecipeTranslator {
  FakeTranslator({this.available = true, this.failOn = const {}});

  final bool available;
  final Set<String> failOn;
  int calls = 0;

  static const _pt = {
    'Chicken Handi': 'Frango Handi',
    'Indian': 'Indiano',
    'Spicy': 'Picante',
    'chicken': 'frango',
    '2 cups': '2 xícaras',
    'Combine the ingredients.': 'Misture os ingredientes.',
    'Cook until ready.': 'Cozinhe até ficar pronto.',
  };

  @override
  Future<void> prepare() async {
    if (!available) throw const TranslationUnavailable('sem modelo');
  }

  @override
  Future<String> toPortuguese(String english) async {
    calls++;
    if (failOn.contains(english)) throw Exception('falhou');
    return _pt[english] ?? english;
  }

  @override
  Future<String> toEnglish(String portuguese) async =>
      {for (final e in _pt.entries) e.value.toLowerCase(): e.key}[portuguese
          .toLowerCase()] ??
      portuguese;

  @override
  Future<void> dispose() async {}
}

MealDetail handi() => MealDetail.fromJson({
  ...mealDetailJson('1', 'Chicken Handi'),
  'strArea': 'Indian',
  'strTags': 'Spicy',
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('traduz na exibição: primeiro o original, depois o português', () async {
    final tr = TranslationController(FakeTranslator());
    await tr.load();

    expect(tr.text('Chicken Handi'), 'Chicken Handi', reason: 'agendado');
    await tr.idle;
    expect(tr.text('Chicken Handi'), 'Frango Handi');
    expect(tr.text('2 cups'), '2 cups');
    await tr.idle;
    expect(tr.text('2 cups'), '2 xícaras');
  });

  test(
    'receita inteira traduzida para compartilhar, mantendo links e id',
    () async {
      final tr = TranslationController(FakeTranslator());
      await tr.load();

      final pt = await tr.translateDetail(handi());

      expect(pt.name, 'Frango Handi');
      expect(pt.area, 'Indiano');
      expect(pt.tags, ['Picante']);
      expect(pt.ingredients.single.name, 'frango');
      expect(pt.ingredients.single.measure, '2 xícaras');
      expect(pt.steps, [
        'Misture os ingredientes.',
        'Cozinhe até ficar pronto.',
      ]);
      expect(pt.id, '1');
      expect(pt.category, 'Chicken', reason: 'categoria tem tradução própria');
    },
  );

  test(
    'desligar mostra o original e a escolha sobrevive a fechar o app',
    () async {
      final tr = TranslationController(FakeTranslator());
      await tr.load();
      tr.text('Chicken Handi');
      await tr.idle;

      await tr.setEnabled(false);
      expect(tr.text('Chicken Handi'), 'Chicken Handi');
      expect(tr.translating, isFalse);

      final reopened = TranslationController(FakeTranslator());
      await reopened.load();
      expect(reopened.enabled, isFalse);
    },
  );

  test('sem modelo disponível, mostra o original sem erro', () async {
    final translator = FakeTranslator(available: false);
    final tr = TranslationController(translator);
    await tr.load();

    expect(tr.status, TranslationStatus.unavailable);
    expect(tr.text('Chicken Handi'), 'Chicken Handi');
    await tr.idle;
    expect(translator.calls, 0, reason: 'não tenta traduzir sem modelo');
  });

  test('falha num texto mantém o original só dele', () async {
    final tr = TranslationController(FakeTranslator(failOn: {'Indian'}));
    await tr.load();
    tr.text('Indian');
    tr.text('Chicken Handi');
    await tr.idle;

    expect(tr.text('Indian'), 'Indian');
    expect(tr.text('Chicken Handi'), 'Frango Handi');
  });

  test('busca em português: a API recebe o texto em inglês', () async {
    final tr = TranslationController(FakeTranslator());
    await tr.load();
    final list = MealListController(
      fakeApi(
        catalog: [mealJson('20', 'Chicken Handi'), mealJson('21', 'Beef Stew')],
      ),
      searchDebounce: Duration.zero,
      queryToApiLanguage: tr.toEnglish,
      displayName: tr.peek,
    );
    await list.load();

    list.setSearch('frango');
    await list.pendingSearch;

    expect(list.visible.map((m) => m.name), ['Chicken Handi']);
  });

  test('busca local também compara com o nome traduzido', () {
    final meals = [
      const MealSummary(id: '1', name: 'Chicken Handi', thumbUrl: ''),
      const MealSummary(id: '2', name: 'Beef Stew', thumbUrl: ''),
    ];
    final found = filterMeals(
      meals,
      'frango',
      alias: (name) => name == 'Chicken Handi' ? 'Frango Handi' : name,
    );

    expect(found.map((m) => m.id), ['1']);
  });
}
