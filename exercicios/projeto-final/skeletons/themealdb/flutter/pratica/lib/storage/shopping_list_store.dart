import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_item.dart';

class ShoppingListStore {
  static const key = 'shopping_list_v1';

  Future<List<ShoppingItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <ShoppingItem>[];
    for (final raw in prefs.getStringList(key) ?? <String>[]) {
      try {
        result.add(
          ShoppingItem.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } on Object {
        // Um registro corrompido não impede recuperar os demais.
      }
    }
    return result;
  }

  Future<void> save(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      key,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (!saved) throw StateError('Não foi possível salvar a lista de compras.');
  }
}
