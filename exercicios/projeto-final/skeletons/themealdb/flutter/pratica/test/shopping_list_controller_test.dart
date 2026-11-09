import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/models/shopping_item.dart';
import 'package:themeal_final/state/shopping_list_controller.dart';
import 'package:themeal_final/storage/shopping_list_store.dart';

const meal = MealDetail(
  id: '1',
  name: 'Arroz',
  category: '',
  area: '',
  thumbUrl: '',
  instructions: '',
  tags: [],
  ingredients: [
    Ingredient(name: 'Arroz', measure: '1 xícara'),
    Ingredient(name: 'Água', measure: '2 xícaras'),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'adicionar receita cria um item por ingrediente e agrupa pelo id',
    () async {
      final controller = ShoppingListController(ShoppingListStore());
      await controller.addMeal(meal);
      expect(controller.items.map((i) => i.ingredient), ['Arroz', 'Água']);
      expect(controller.items.map((i) => i.measure), ['1 xícara', '2 xícaras']);
      expect(controller.items.every((i) => !i.checked), isTrue);
      expect(controller.groupedByMeal['1']?.length, 2);
      expect(controller.containsMeal('1'), isTrue);
    },
  );

  test('limpar comprados remove somente os marcados', () async {
    final controller = ShoppingListController(ShoppingListStore());
    await controller.addMeal(meal);
    await controller.toggle(controller.items.first);
    expect(controller.items.first.checked, isTrue);
    await controller.clearChecked();
    expect(controller.items.single.ingredient, 'Água');
    expect(controller.items.single.checked, isFalse);
    await controller.removeMeal('1');
    expect(controller.items, isEmpty);
    expect(controller.containsMeal('1'), isFalse);
  });

  test(
    'nova instância restaura ingredientes e checkboxes após fechar o app',
    () async {
      final first = ShoppingListController(ShoppingListStore());
      await first.addMeal(meal);
      await first.toggle(first.items.first);
      first.dispose();
      final reopened = ShoppingListController(ShoppingListStore());
      await reopened.load();
      expect(reopened.items.map((i) => i.ingredient), ['Arroz', 'Água']);
      expect(reopened.items.first.checked, isTrue);
      expect(reopened.items.last.checked, isFalse);
    },
  );

  test(
    'adicionar a mesma receita duas vezes não duplica nem desmarca',
    () async {
      final controller = ShoppingListController(ShoppingListStore());
      await controller.addMeal(meal);
      await controller.toggle(controller.items.first);
      await controller.addMeal(meal);
      expect(controller.items.length, 2);
      expect(controller.items.first.checked, isTrue);
    },
  );

  test('entradas corrompidas são ignoradas e preservam as válidas', () async {
    final item = ShoppingItem(
      mealId: '1',
      mealName: 'Arroz',
      ingredient: 'Água',
      measure: '',
      checked: true,
    );
    SharedPreferences.setMockInitialValues({
      ShoppingListStore.key: [
        jsonEncode(item.toJson()),
        'inválido',
        '{"checked": "sim"}',
      ],
    });
    final controller = ShoppingListController(ShoppingListStore());
    await controller.load();
    expect(controller.items.single.ingredient, 'Água');
    expect(controller.items.single.checked, isTrue);
  });

  test('ação durante carregamento preserva a lista já salva', () async {
    final initial = ShoppingListController(ShoppingListStore());
    await initial.addMeal(meal);
    final controller = ShoppingListController(ShoppingListStore());
    final loading = controller.load();
    await controller.addMeal(meal);
    await loading;
    expect(controller.items.length, 2);
  });

  test(
    'gravações rápidas aguardam a anterior e a UI atualiza antes do disco',
    () async {
      final store = DelayedStore();
      final controller = ShoppingListController(store);
      await controller.load();
      final adding = controller.addMeal(meal);
      await Future<void>.delayed(Duration.zero);
      expect(controller.items.length, 2);
      final clearing = controller.removeMeal('1');
      await Future<void>.delayed(Duration.zero);
      expect(controller.items, isEmpty);
      expect(store.snapshots.length, 1);
      store.firstWrite.complete();
      await Future.wait([adding, clearing]);
      expect(store.snapshots.last, isEmpty);
    },
  );
}

class DelayedStore extends ShoppingListStore {
  final firstWrite = Completer<void>();
  final snapshots = <List<ShoppingItem>>[];

  @override
  Future<List<ShoppingItem>> load() async => [];

  @override
  Future<void> save(List<ShoppingItem> items) async {
    snapshots.add(items);
    if (snapshots.length == 1) await firstWrite.future;
  }
}
