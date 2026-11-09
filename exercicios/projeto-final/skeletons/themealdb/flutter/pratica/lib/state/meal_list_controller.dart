import 'package:flutter/foundation.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';
import '../storage/meals_cache.dart';

enum LoadStatus { loading, ready, error }

/// Filtro local por nome, sem diferenciar maiúsculas e minúsculas.
List<MealSummary> filterMeals(
  List<MealSummary> meals,
  String query, {
  String Function(String name)? alias,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return meals;
  return meals.where((m) {
    if (m.name.toLowerCase().contains(q)) return true;
    // Também acha pelo nome traduzido ("frango" encontra "Chicken Handi").
    return alias != null && alias(m.name).toLowerCase().contains(q);
  }).toList();
}

/// Estado da tela de receitas: lista inicial, categorias, letras e busca.
class MealListController extends ChangeNotifier {
  final TheMealDbApi _api;
  final MealsCache _cache;
  final Duration _searchDebounce;

  /// Traduz o texto da busca para o idioma da API (inglês). Opcional: sem
  /// ele, a busca vai como foi digitada.
  final Future<String> Function(String query)? _queryToApiLanguage;

  /// Nome como aparece na tela (traduzido), para a busca local.
  final String Function(String name)? _displayName;

  MealListController(
    this._api, {
    MealsCache? cache,
    Duration searchDebounce = const Duration(milliseconds: 400),
    Future<String> Function(String query)? queryToApiLanguage,
    String Function(String name)? displayName,
  }) : _cache = cache ?? MealsCache(),
       _searchDebounce = searchDebounce,
       _queryToApiLanguage = queryToApiLanguage,
       _displayName = displayName;

  LoadStatus _status = LoadStatus.loading;
  String? _errorMessage;
  bool _offline = false;
  bool _fromCache = false;

  List<MealSummary> _all = const [];
  List<MealSummary> _categoryMeals = const [];
  List<MealSummary> _letterMeals = const [];
  List<String> _categories = const [];
  String? _selectedCategory;
  String? _selectedLetter;

  String _searchText = '';
  List<MealSummary>? _searchResults;
  bool _searching = false;
  Future<void>? _pendingSearch;

  int _categoryRequestId = 0;
  int _letterRequestId = 0;
  int _searchRequestId = 0;
  bool _disposed = false;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get offline => _offline;
  bool get fromCache => _fromCache;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String? get selectedLetter => _selectedLetter;
  String get searchText => _searchText;
  bool get searching => _searching;

  /// O que a grade mostra, com busca local aplicada à origem selecionada.
  List<MealSummary> get visible {
    if (_selectedCategory != null) {
      return filterMeals(_categoryMeals, _searchText, alias: _displayName);
    }
    if (_selectedLetter != null) {
      return filterMeals(_letterMeals, _searchText, alias: _displayName);
    }
    if (_searchText.trim().isEmpty) return _all;
    return _searchResults ??
        filterMeals(_all, _searchText, alias: _displayName);
  }

  @visibleForTesting
  Future<void> get pendingSearch => _pendingSearch ?? Future.value();

  /// Carrega ou atualiza a origem atualmente escolhida.
  Future<void> load() async {
    if (_selectedCategory case final category?) {
      await _loadCategory(category);
      return;
    }
    if (_selectedLetter case final letter?) {
      await _loadLetter(letter);
      return;
    }

    _setLoading();
    try {
      _all = await _api.fetchList();
      await _cache.saveList(_all);
      _fromCache = false;
      _status = LoadStatus.ready;
      try {
        _categories = await _api.fetchCategories();
        await _cache.saveCategories(_categories);
      } catch (_) {
        _categories = await _cache.loadCategories() ?? const [];
      }
    } on ApiException catch (error) {
      if (error.offline) {
        final cached = await _cache.loadList();
        if (cached != null) {
          _all = cached;
          _categories = await _cache.loadCategories() ?? const [];
          _fromCache = true;
          _status = LoadStatus.ready;
          _errorMessage = null;
          _offline = false;
        } else {
          _setError(error);
        }
      } else {
        _setError(error);
      }
    }
    _notify();
    _scheduleSearch();
  }

  Future<void> selectCategory(String? category) async {
    if (category == _selectedCategory && category != null) return;
    _selectedCategory = category;
    _selectedLetter = null;
    _letterRequestId++;
    _searchResults = null;
    if (category == null) {
      _categoryMeals = const [];
      if (_all.isEmpty) {
        await load();
      } else {
        _status = LoadStatus.ready;
        _fromCache = false;
        _notify();
        _scheduleSearch();
      }
      return;
    }
    await _loadCategory(category);
  }

  Future<void> _loadCategory(String category) async {
    final requestId = ++_categoryRequestId;
    _setLoading();
    _notify();
    try {
      final meals = await _api.fetchByCategory(category);
      await _cache.saveCategory(category, meals);
      if (requestId != _categoryRequestId) return;
      _categoryMeals = meals;
      _fromCache = false;
      _status = LoadStatus.ready;
    } on ApiException catch (error) {
      if (requestId != _categoryRequestId) return;
      final cached = error.offline ? await _cache.loadCategory(category) : null;
      if (requestId != _categoryRequestId) return;
      if (cached != null) {
        _categoryMeals = cached;
        _fromCache = true;
        _status = LoadStatus.ready;
      } else {
        _setError(error);
      }
    }
    _notify();
  }

  Future<void> selectLetter(String? letter) async {
    if (letter == _selectedLetter && letter != null) return;
    _selectedLetter = letter?.toUpperCase();
    _selectedCategory = null;
    _categoryRequestId++;
    _searchResults = null;
    if (letter == null) {
      _letterMeals = const [];
      if (_all.isEmpty) {
        await load();
      } else {
        _status = LoadStatus.ready;
        _fromCache = false;
        _notify();
        _scheduleSearch();
      }
      return;
    }
    await _loadLetter(letter);
  }

  Future<void> _loadLetter(String letter) async {
    final requestId = ++_letterRequestId;
    _setLoading();
    _notify();
    try {
      final meals = await _api.fetchByLetter(letter);
      await _cache.saveLetter(letter, meals);
      if (requestId != _letterRequestId) return;
      _letterMeals = meals;
      _fromCache = false;
      _status = LoadStatus.ready;
    } on ApiException catch (error) {
      if (requestId != _letterRequestId) return;
      final cached = error.offline ? await _cache.loadLetter(letter) : null;
      if (requestId != _letterRequestId) return;
      if (cached != null) {
        _letterMeals = cached;
        _fromCache = true;
        _status = LoadStatus.ready;
      } else {
        _setError(error);
      }
    }
    _notify();
  }

  void setSearch(String text) {
    if (text == _searchText) return;
    _searchText = text;
    _notify();
    _scheduleSearch();
  }

  Future<void> retry() => load();

  void _scheduleSearch() {
    final query = _searchText.trim();
    final requestId = ++_searchRequestId;
    _searchResults = null;
    _searching =
        query.isNotEmpty &&
        _selectedCategory == null &&
        _selectedLetter == null &&
        _status == LoadStatus.ready;
    if (!_searching) {
      _pendingSearch = null;
      return;
    }
    _pendingSearch = Future.delayed(_searchDebounce, () async {
      if (requestId != _searchRequestId || _disposed) return;
      try {
        final apiQuery =
            await (_queryToApiLanguage?.call(query) ?? Future.value(query));
        if (requestId != _searchRequestId || _disposed) return;
        _searchResults = await _api.search(apiQuery);
      } on ApiException {
        // A busca local continua disponível se a rede falhar.
      }
      if (requestId != _searchRequestId || _disposed) return;
      _searching = false;
      _notify();
    });
  }

  void _setLoading() {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _offline = false;
  }

  void _setError(ApiException error) {
    _status = LoadStatus.error;
    _errorMessage = error.message;
    _offline = error.offline;
    _fromCache = false;
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
