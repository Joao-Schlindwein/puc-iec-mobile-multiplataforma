import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

/// Cache local das listas obtidas da API, separadas pela origem dos dados.
class MealsCache {
  static const _listKey = 'cache_list';
  static const _categoriesKey = 'cache_categories';

  String _categoryKey(String category) =>
      'cache_category_${category.trim().toLowerCase()}';

  Future<void> saveList(List<MealSummary> meals) => _save(_listKey, meals);

  Future<List<MealSummary>?> loadList() => _load(_listKey);

  Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  Future<List<String>?> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey);
  }

  Future<void> saveCategory(String category, List<MealSummary> meals) =>
      _save(_categoryKey(category), meals);

  Future<List<MealSummary>?> loadCategory(String category) =>
      _load(_categoryKey(category));

  Future<void> saveLetter(String letter, List<MealSummary> meals) =>
      _save('cache_letter_${letter.toLowerCase()}', meals);

  Future<List<MealSummary>?> loadLetter(String letter) =>
      _load('cache_letter_${letter.toLowerCase()}');

  Future<void> saveDetail(MealDetail detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detailKey(detail.id), jsonEncode(detail.toJson()));
  }

  Future<MealDetail?> loadDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_detailKey(id));
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      return MealDetail.fromJson(decoded);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> _save(String key, List<MealSummary> meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(meals.map((meal) => meal.toJson()).toList()),
    );
  }

  String _detailKey(String id) => 'cache_detail_${Uri.encodeComponent(id)}';

  Future<List<MealSummary>?> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(key);
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return null;
      final meals = <MealSummary>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          meals.add(MealSummary.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // Ignore malformed entries while retaining valid cached recipes.
        }
      }
      return meals;
    } on FormatException {
      return null;
    }
  }
}
