import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

/// Persistência local dos favoritos.
///
/// Guarda o resumo de cada receita (id, nome, foto) e não só o id, para a
/// aba Favoritos abrir sem internet e para receitas favoritadas a partir de
/// uma categoria (que não estão na lista inicial) continuarem aparecendo.
class FavoritesStore {
  static const _key = 'favorite_meals_v2';

  Future<List<MealSummary>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const [];
    final result = <MealSummary>[];
    for (final raw in stored) {
      try {
        result.add(
            MealSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } on Object {
        // Entrada corrompida: ignora em vez de derrubar a aba inteira.
      }
    }
    return result;
  }

  Future<void> save(List<MealSummary> meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      meals.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }
}
