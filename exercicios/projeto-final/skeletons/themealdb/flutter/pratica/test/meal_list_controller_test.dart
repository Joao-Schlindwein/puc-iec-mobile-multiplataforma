import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/state/meal_list_controller.dart';
import 'package:themeal_final/storage/meals_cache.dart';

import 'fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('filterMeals (busca)', () {
    final meals = [
      const MealSummary(id: '1', name: 'Sushi', thumbUrl: ''),
      const MealSummary(id: '2', name: 'Salmon Avocado Salad', thumbUrl: ''),
    ];

    test('ignora maiúsculas e espaços nas pontas', () {
      expect(filterMeals(meals, '  SUSHI ').map((m) => m.id), ['1']);
    });

    test('busca vazia devolve tudo', () {
      expect(filterMeals(meals, '   '), meals);
    });
  });

  group('MealListController', () {
    test(
      'categoria troca a lista pelo resultado da API e combina com a busca',
      () async {
        final list = MealListController(
          fakeApi(
            byCategory: {
              'Dessert': [
                mealJson('10', 'Flan'),
                mealJson('11', 'Apple Frangipan Tart'),
              ],
            },
          ),
          searchDebounce: Duration.zero,
        );
        await list.load();
        expect(list.visible.map((m) => m.name), ['Burek', 'Sushi']);

        await list.selectCategory('Dessert');
        expect(list.visible.map((m) => m.name), [
          'Flan',
          'Apple Frangipan Tart',
        ]);

        list.setSearch('flan');
        expect(list.visible.map((m) => m.id), ['10']);

        await list.selectCategory(null);
        await list.pendingSearch;
        expect(list.visible, isEmpty, reason: 'busca "flan" continua ativa');
      },
    );

    test('busca em "Todas" procura no catálogo inteiro da API', () async {
      final list = MealListController(
        fakeApi(
          catalog: [
            mealJson('20', 'Chicken Handi'),
            mealJson('21', 'Chicken Karaage'),
            mealJson('22', 'Beef Stew'),
          ],
        ),
        searchDebounce: Duration.zero,
      );
      await list.load();

      list.setSearch('chicken');
      expect(list.searching, isTrue);
      expect(
        list.visible,
        isEmpty,
        reason: 'antes da resposta, só o filtro local (nada na lista inicial)',
      );

      await list.pendingSearch;
      expect(list.searching, isFalse);
      expect(list.visible.map((m) => m.id), ['20', '21']);
    });

    test(
      'categoria sem receitas ("meals": null) vira lista vazia, não erro',
      () async {
        final list = MealListController(fakeApi());
        await list.load();
        await list.selectCategory('Goat');

        expect(list.status, LoadStatus.ready);
        expect(list.visible, isEmpty);
      },
    );

    test('sem internet vira erro com mensagem e flag offline', () async {
      final list = MealListController(fakeApi(failWith: 'offline'));
      await list.load();

      expect(list.status, LoadStatus.error);
      expect(list.offline, isTrue);
      expect(list.errorMessage, 'Sem conexão com a internet.');
    });

    test('erro HTTP não é tratado como falta de internet', () async {
      final list = MealListController(fakeApi(failWith: 500));
      await list.load();

      expect(list.status, LoadStatus.error);
      expect(list.offline, isFalse);
      expect(list.errorMessage, contains('500'));
    });

    test('online saves the initial list in cache', () async {
      final cache = MealsCache();
      final list = MealListController(fakeApi(), cache: cache);
      await list.load();

      expect((await cache.loadList())?.map((meal) => meal.name), [
        'Burek',
        'Sushi',
      ]);
      expect(list.fromCache, isFalse);
    });

    test('offline loads the saved initial list', () async {
      final cache = MealsCache();
      await cache.saveList([
        const MealSummary(id: '8', name: 'Saved recipe', thumbUrl: ''),
      ]);
      final list = MealListController(
        fakeApi(failWith: 'offline'),
        cache: cache,
      );
      await list.load();

      expect(list.status, LoadStatus.ready);
      expect(list.fromCache, isTrue);
      expect(list.visible.single.name, 'Saved recipe');
    });

    test('offline without cache remains an error', () async {
      final list = MealListController(fakeApi(failWith: 'offline'));
      await list.load();

      expect(list.status, LoadStatus.error);
      expect(list.offline, isTrue);
    });

    test('offline category loads that category cache', () async {
      final cache = MealsCache();
      await cache.saveList([
        const MealSummary(id: '1', name: 'Burek', thumbUrl: ''),
      ]);
      await cache.saveCategory('Beef', [
        const MealSummary(id: '9', name: 'Cached beef', thumbUrl: ''),
      ]);
      final list = MealListController(
        fakeApi(failWith: 'offline'),
        cache: cache,
      );
      await list.load();
      await list.selectCategory('Beef');

      expect(list.status, LoadStatus.ready);
      expect(list.fromCache, isTrue);
      expect(list.visible.single.name, 'Cached beef');
    });

    test('selecting a letter shows its results and clears category', () async {
      final list = MealListController(
        fakeApi(
          byLetter: {
            'a': [mealJson('30', 'Apple pie')],
          },
          byCategory: {
            'Dessert': [mealJson('31', 'Flan')],
          },
        ),
      );
      await list.load();
      await list.selectCategory('Dessert');
      await list.selectLetter('A');

      expect(list.selectedCategory, isNull);
      expect(list.selectedLetter, 'A');
      expect(list.visible.single.name, 'Apple pie');

      await list.selectCategory('Dessert');
      expect(list.selectedLetter, isNull);
      expect(list.visible.single.name, 'Flan');
    });

    test('letter without recipes is an empty ready state', () async {
      final list = MealListController(fakeApi());
      await list.load();
      await list.selectLetter('Z');

      expect(list.status, LoadStatus.ready);
      expect(list.visible, isEmpty);
    });

    test('text search filters the selected letter results', () async {
      final list = MealListController(
        fakeApi(
          byLetter: {
            'a': [mealJson('40', 'Apple pie'), mealJson('41', 'Apple tart')],
          },
        ),
      );
      await list.load();
      await list.selectLetter('A');
      list.setSearch('tart');

      expect(list.visible.map((meal) => meal.name), ['Apple tart']);
    });
  });
}
