import 'package:flutter/material.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';
import '../storage/meals_cache.dart';
import 'detail_screen.dart';

const List<String> _categories = ['Dessert', 'Beef', 'Seafood', 'Vegetarian'];
const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, this.api, this.cache});

  final TheMealDbApi? api;
  final MealsCache? cache;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final TheMealDbApi _api = widget.api ?? TheMealDbApi();
  late final MealsCache _cache = widget.cache ?? MealsCache();

  List<MealSummary> _all = [];
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  String _searchText = '';
  String? _selectedCategory;
  String? _selectedLetter;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meals = await _api.fetchList();
      await _cache.saveList(meals);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _all = meals;
        _selectedCategory = null;
        _selectedLetter = null;
        _fromCache = false;
        _loading = false;
      });
    } catch (error) {
      final cached = error is ApiException && error.offline
          ? await _cache.loadList()
          : null;
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        if (cached != null) {
          _all = cached;
          _selectedCategory = null;
          _selectedLetter = null;
          _fromCache = true;
          _error = null;
        } else {
          _error = error is ApiException && error.offline
              ? 'Você está sem internet e ainda não há receitas salvas.'
              : 'Não foi possível carregar as receitas.';
        }
      });
    }
  }

  Future<void> _selectCategory(String? category) async {
    if (category == null) {
      setState(() {
        _selectedCategory = null;
        _selectedLetter = null;
        _all = [];
      });
      await _loadList();
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _selectedCategory = category;
      _selectedLetter = null;
      _loading = true;
      _error = null;
      _fromCache = false;
    });
    try {
      final meals = await _api.fetchByCategory(category);
      await _cache.saveCategory(category, meals);
      await _cache.saveCategories(meals);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _all = meals;
        _loading = false;
      });
    } catch (error) {
      final cached = error is ApiException && error.offline
          ? await _cache.loadCategory(category)
          : null;
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        if (cached != null) {
          _all = cached;
          _fromCache = true;
        } else {
          _error = error is ApiException && error.offline
              ? 'Você está sem internet e não há receitas salvas para esta categoria.'
              : 'Não foi possível carregar esta categoria.';
        }
      });
    }
  }

  Future<void> _selectLetter(String? letter) async {
    if (letter == null) {
      setState(() {
        _selectedLetter = null;
        _selectedCategory = null;
      });
      await _loadList();
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _selectedLetter = letter;
      _selectedCategory = null;
      _loading = true;
      _error = null;
      _fromCache = false;
    });
    try {
      final meals = await _api.fetchByLetter(letter);
      await _cache.saveLetter(letter, meals);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _all = meals;
        _loading = false;
      });
    } catch (error) {
      final cached = error is ApiException && error.offline
          ? await _cache.loadLetter(letter)
          : null;
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        if (cached != null) {
          _all = cached;
          _fromCache = true;
        } else {
          _error = error is ApiException && error.offline
              ? 'Você está sem internet e não há receitas salvas para esta letra.'
              : 'Não foi possível carregar as receitas.';
        }
      });
    }
  }

  List<MealSummary> get _filtered {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return _all;
    return _all
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TheMealDB')),
      body: Semantics(identifier: 'item-list-screen', child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_fromCache)
          MaterialBanner(
            content: const Text('Sem internet — mostrando receitas salvas'),
            actions: [
              TextButton(
                onPressed: _retry,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Semantics(
            identifier: 'search-input',
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar receita',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildCategoryChip(null, 'Todos'),
              for (final category in _categories)
                _buildCategoryChip(category, category),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final letter in _alphabet.split(''))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    key: ValueKey('letter-$letter'),
                    label: Text(letter),
                    visualDensity: VisualDensity.compact,
                    selected: _selectedLetter == letter,
                    onSelected: (_) => _selectLetter(letter),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _retry,
            child: _filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          _searchText.isEmpty
                              ? 'Nenhuma receita encontrada.'
                              : 'Nenhuma receita corresponde à busca.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final meal = _filtered[index];
                      return Semantics(
                        identifier: 'item-card-${meal.id}',
                        child: ListTile(
                          leading: meal.thumbUrl.isNotEmpty
                              ? Image.network(
                                  meal.thumbUrl,
                                  width: 40,
                                  height: 40,
                                )
                              : null,
                          title: Text(meal.name),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(mealId: meal.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _retry() async {
    if (_selectedCategory case final category?) {
      await _selectCategory(category);
    } else if (_selectedLetter case final letter?) {
      await _selectLetter(letter);
    } else {
      await _loadList();
    }
  }

  Widget _buildCategoryChip(String? category, String label) {
    final selected = _selectedCategory == category && _selectedLetter == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        identifier: category == null
            ? 'category-chip-all'
            : 'category-chip-${category.toLowerCase()}',
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => _selectCategory(category),
        ),
      ),
    );
  }
}
