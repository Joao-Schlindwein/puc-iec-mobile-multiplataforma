import 'package:flutter_test/flutter_test.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/state/meal_list_controller.dart';

import 'fake_api.dart';

void main() {
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
    test('categoria troca a lista pelo resultado da API e combina com a busca',
        () async {
      final list = MealListController(
        fakeApi(byCategory: {
          'Dessert': [mealJson('10', 'Flan'), mealJson('11', 'Apple Frangipan Tart')],
        }),
        searchDebounce: Duration.zero,
      );
      await list.load();
      expect(list.visible.map((m) => m.name), ['Burek', 'Sushi']);

      await list.selectCategory('Dessert');
      expect(list.visible.map((m) => m.name), ['Flan', 'Apple Frangipan Tart']);

      list.setSearch('flan');
      expect(list.visible.map((m) => m.id), ['10']);

      await list.selectCategory(null);
      await list.pendingSearch;
      expect(list.visible, isEmpty, reason: 'busca "flan" continua ativa');
    });

    test('busca em "Todas" procura no catálogo inteiro da API', () async {
      final list = MealListController(
        fakeApi(catalog: [
          mealJson('20', 'Chicken Handi'),
          mealJson('21', 'Chicken Karaage'),
          mealJson('22', 'Beef Stew'),
        ]),
        searchDebounce: Duration.zero,
      );
      await list.load();

      list.setSearch('chicken');
      expect(list.searching, isTrue);
      expect(list.visible, isEmpty,
          reason: 'antes da resposta, só o filtro local (nada na lista inicial)');

      await list.pendingSearch;
      expect(list.searching, isFalse);
      expect(list.visible.map((m) => m.id), ['20', '21']);
    });

    test('categoria sem receitas ("meals": null) vira lista vazia, não erro',
        () async {
      final list = MealListController(fakeApi());
      await list.load();
      await list.selectCategory('Goat');

      expect(list.status, LoadStatus.ready);
      expect(list.visible, isEmpty);
    });

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
  });
}
