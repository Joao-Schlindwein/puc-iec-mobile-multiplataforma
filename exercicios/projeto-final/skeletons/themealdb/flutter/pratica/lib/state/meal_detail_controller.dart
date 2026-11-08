import 'package:flutter/foundation.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';
import 'meal_list_controller.dart' show LoadStatus;

/// Estado da tela de detalhe de uma receita.
class MealDetailController extends ChangeNotifier {
  final TheMealDbApi _api;
  final String mealId;

  MealDetailController(this._api, this.mealId);

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
    notifyListeners();
    try {
      _detail = await _api.fetchDetail(mealId);
      _status = LoadStatus.ready;
    } on ApiException catch (e) {
      _status = LoadStatus.error;
      _errorMessage = e.message;
      _offline = e.offline;
    }
    notifyListeners();
  }
}
