import 'package:flutter/foundation.dart';

import '../models/meal.dart';
import '../storage/favorites_store.dart';

/// Favoritos compartilhados por todas as telas (grade, detalhe e aba
/// Favoritos), persistidos a cada mudança.
class FavoritesController extends ChangeNotifier {
  final FavoritesStore _store;

  FavoritesController(this._store);

  List<MealSummary> _items = const [];
  bool _loaded = false;

  /// Mais recentes primeiro.
  List<MealSummary> get items => _items;
  bool get loaded => _loaded;

  bool isFavorite(String id) => _items.any((m) => m.id == id);

  Future<void> load() async {
    _items = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(MealSummary meal) async {
    if (isFavorite(meal.id)) {
      await remove(meal.id);
    } else {
      await add(meal);
    }
  }

  Future<void> add(MealSummary meal, {int index = 0}) async {
    if (isFavorite(meal.id)) return;
    final next = [..._items];
    next.insert(index.clamp(0, next.length), meal);
    await _commit(next);
  }

  Future<void> remove(String id) =>
      _commit(_items.where((m) => m.id != id).toList());

  Future<void> _commit(List<MealSummary> next) async {
    // Atualiza a tela na hora e grava em seguida.
    _items = List.unmodifiable(next);
    notifyListeners();
    await _store.save(_items);
  }
}
