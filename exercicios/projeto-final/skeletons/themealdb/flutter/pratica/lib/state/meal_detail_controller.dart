import 'package:flutter/foundation.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';
import '../storage/meals_cache.dart';
import 'meal_list_controller.dart' show LoadStatus;

/// Estado da tela de detalhe de uma receita.
class MealDetailController extends ChangeNotifier {
  final TheMealDbApi _api;
  final MealsCache _cache;
  final String mealId;

  MealDetailController(this._api, this.mealId, {MealsCache? cache})
    : _cache = cache ?? MealsCache();

  LoadStatus _status = LoadStatus.loading;
  MealDetail? _detail;
  String? _errorMessage;
  bool _offline = false;

  LoadStatus get status => _status;
  MealDetail? get detail => _detail;
  String? get errorMessage => _errorMessage;
  bool get offline => _offline;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _offline = false;
    notifyListeners();
    try {
      final detail = await _api.fetchDetail(mealId);
      await _cache.saveDetail(detail);
      _detail = detail;
      _status = LoadStatus.ready;
    } on ApiException catch (e) {
      final cached = e.offline ? await _cache.loadDetail(mealId) : null;
      if (cached != null) {
        _detail = cached;
        _status = LoadStatus.ready;
        _offline = true;
        _errorMessage = null;
      } else {
        _status = LoadStatus.error;
        _errorMessage = e.message;
        _offline = e.offline;
      }
    }
    notifyListeners();
  }
}
