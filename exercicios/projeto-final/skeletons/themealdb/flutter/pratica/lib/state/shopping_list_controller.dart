import 'package:flutter/foundation.dart';

import '../models/meal.dart';
import '../models/shopping_item.dart';
import '../storage/shopping_list_store.dart';

/// Estado único da aba Compras e do botão no detalhe.
class ShoppingListController extends ChangeNotifier {
  final ShoppingListStore _store;
  List<ShoppingItem> _items = const [];
  Future<void>? _loading;
  Future<void> _pendingSave = Future.value();
  bool _loaded = false;
  bool _disposed = false;

  ShoppingListController(this._store);

  List<ShoppingItem> get items => _items;
  bool get loaded => _loaded;

  /// Chaves são ids: receitas com o mesmo nome continuam separadas.
  Map<String, List<ShoppingItem>> get groupedByMeal {
    final groups = <String, List<ShoppingItem>>{};
    for (final item in _items) {
      (groups[item.mealId] ??= []).add(item);
    }
    return Map.unmodifiable(
      groups.map(
        (id, items) => MapEntry(id, List<ShoppingItem>.unmodifiable(items)),
      ),
    );
  }

  bool containsMeal(String id) => _items.any((item) => item.mealId == id);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _items = List.unmodifiable(await _store.load());
    _loaded = true;
    _notify();
  }

  Future<void> addMeal(MealDetail meal) async {
    await load();
    if (containsMeal(meal.id)) return;
    await _commit([
      ..._items,
      for (final ingredient in meal.ingredients)
        ShoppingItem(
          mealId: meal.id,
          mealName: meal.name,
          ingredient: ingredient.name,
          measure: ingredient.measure,
        ),
    ]);
  }

  Future<void> removeMeal(String id) async {
    await load();
    await _commit(_items.where((item) => item.mealId != id).toList());
  }

  Future<void> toggle(ShoppingItem item) async {
    await load();
    final index = _items.indexOf(item);
    if (index < 0) return;
    final next = [..._items];
    next[index] = item.withChecked(!item.checked);
    await _commit(next);
  }

  Future<void> clearChecked() async {
    await load();
    await _commit(_items.where((item) => !item.checked).toList());
  }

  Future<void> _commit(List<ShoppingItem> next) {
    final snapshot = List<ShoppingItem>.unmodifiable(next);
    _items = snapshot;
    _notify();
    // Serializa gravações: toques rápidos não deixam uma versão antiga no disco.
    final save = _pendingSave.then((_) => _store.save(snapshot));
    _pendingSave = save.catchError((Object _) {});
    return save;
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
