import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../state/meal_list_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets/meal_card.dart';
import '../ui/widgets/skeleton.dart';
import '../ui/widgets/state_message.dart';
import 'detail_screen.dart';

/// Colunas da grade conforme a largura: 2 no celular em pé, mais em
/// paisagem/tablet.
int gridColumnsFor(double width) => (width / 190).floor().clamp(2, 5);

/// Features 1 (lista), 3 (busca) e 4 (categoria).
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
      body: Semantics(
        identifier: 'item-list-screen',
        child: Column(
          children: [
            _SearchField(controller: _search),
            const _CategoryChips(),
            const _LetterChips(),
            const _OfflineCacheBanner(),
            const SizedBox(height: AppTokens.space2),
            const Expanded(child: _ListBody()),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final list = context.read<MealListController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space1,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: Semantics(
        identifier: 'search-input',
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: list.setSearch,
            decoration: InputDecoration(
              hintText: 'Buscar receita pelo nome',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        list.setSearch('');
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<MealListController>();
    if (list.categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
        children: [
          _chip(context, list, null, 'Todas'),
          for (final category in list.categories)
            _chip(context, list, category, categoryLabel(category)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    MealListController list,
    String? category,
    String label,
  ) {
    final selected =
        list.selectedLetter == null && list.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
      child: Semantics(
        identifier: category == null
            ? 'category-chip-all'
            : 'category-chip-${category.toLowerCase()}',
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => list.selectCategory(category),
        ),
      ),
    );
  }
}

class _LetterChips extends StatelessWidget {
  const _LetterChips();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<MealListController>();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
        children: [
          for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                key: ValueKey('letter-$letter'),
                label: Text(letter),
                visualDensity: VisualDensity.compact,
                selected: list.selectedLetter == letter,
                onSelected: (_) => list.selectLetter(letter),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineCacheBanner extends StatelessWidget {
  const _OfflineCacheBanner();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<MealListController>();
    if (!list.fromCache || list.status != LoadStatus.ready) {
      return const SizedBox.shrink();
    }
    return MaterialBanner(
      content: const Text('Sem internet — mostrando receitas salvas'),
      actions: [
        TextButton(onPressed: list.retry, child: const Text('Tentar de novo')),
      ],
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<MealListController>();
    final columns = gridColumnsFor(MediaQuery.sizeOf(context).width);

    switch (list.status) {
      case LoadStatus.loading:
        return SkeletonGrid(crossAxisCount: columns);
      case LoadStatus.error:
        return StateMessage(
          icon: list.offline ? Icons.wifi_off : Icons.cloud_off,
          title: list.offline
              ? 'Você está sem internet'
              : 'Não deu para carregar as receitas',
          message: list.errorMessage ?? 'Tente novamente em instantes.',
          actionLabel: 'Tentar de novo',
          onAction: list.retry,
        );
      case LoadStatus.ready:
        final meals = list.visible;
        if (meals.isEmpty && list.searching) {
          return SkeletonGrid(crossAxisCount: columns);
        }
        if (meals.isEmpty) {
          return StateMessage(
            icon: Icons.search_off,
            title: 'Nenhuma receita encontrada',
            message: list.searchText.trim().isEmpty
                ? 'Esta categoria não tem receitas no momento.'
                : 'Nada com "${list.searchText.trim()}" por aqui. '
                      'Tente outro nome ou outra categoria.',
          );
        }
        return Column(
          children: [
            // Busca na API em andamento: a grade já mostra o filtro local.
            SizedBox(
              height: 2,
              child: list.searching ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: list.load,
                child: _MealGrid(meals: meals, columns: columns),
              ),
            ),
          ],
        );
    }
  }
}

class _MealGrid extends StatelessWidget {
  final List<MealSummary> meals;
  final int columns;

  const _MealGrid({required this.meals, required this.columns});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            0,
            AppTokens.space4,
            AppTokens.space2,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              meals.length == 1 ? '1 receita' : '${meals.length} receitas',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            0,
            AppTokens.space4,
            AppTokens.space5,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppTokens.space3,
              crossAxisSpacing: AppTokens.space3,
              childAspectRatio: 0.78,
            ),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return MealCard(
                meal: meal,
                onTap: () {
                  // Fecha o teclado da busca; senão ele reabre ao voltar.
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DetailScreen(meal: meal)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
