import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/themealdb_api.dart';
import '../models/meal.dart';
import '../models/meal_share.dart';
import '../state/favorites_controller.dart';
import '../state/meal_detail_controller.dart';
import '../state/shopping_list_controller.dart';
import '../state/meal_list_controller.dart' show LoadStatus;
import '../storage/meals_cache.dart';
import '../ui/theme.dart';
import '../ui/widgets/meal_image.dart';
import '../ui/widgets/skeleton.dart';
import '../ui/widgets/state_message.dart';

/// Feature 2 (detalhe) e o botão da feature 5 (favoritos).
///
/// Recebe o resumo da lista para mostrar foto e nome na hora, enquanto o
/// detalhe completo (ingredientes e preparo) carrega.
class DetailScreen extends StatelessWidget {
  final MealSummary meal;

  const DetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MealDetailController(
        context.read<TheMealDbApi>(),
        meal.id,
        cache: context.read<MealsCache>(),
      )..load(),
      child: _DetailView(meal: meal),
    );
  }
}

class _DetailView extends StatelessWidget {
  final MealSummary meal;

  const _DetailView({required this.meal});

  @override
  Widget build(BuildContext context) {
    final detailState = context.watch<MealDetailController>();
    final isFavorite = context.select<FavoritesController, bool>(
      (c) => c.isFavorite(meal.id),
    );
    final scheme = Theme.of(context).colorScheme;
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      220.0,
      380.0,
    );

    return Scaffold(
      body: Semantics(
        identifier: 'detail-screen',
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: heroHeight,
              pinned: true,
              stretch: true,
              backgroundColor: scheme.surface,
              leading: Semantics(
                identifier: 'detail-back-button',
                child: _RoundIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Semantics(
                  identifier: 'detail-favorite-button',
                  child: _RoundIconButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? scheme.primary : null,
                    tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
                    onPressed: () => _toggleFavorite(context, isFavorite),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: MealImage(url: meal.thumbUrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  AppTokens.space5,
                  AppTokens.space5,
                  AppTokens.space2,
                ),
                child: Semantics(
                  identifier: 'detail-title',
                  child: Text(
                    detailState.detail?.name ?? meal.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
            ..._content(context, detailState),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, MealDetailController state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const [SliverToBoxAdapter(child: _DetailSkeleton())];
      case LoadStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StateMessage(
              icon: state.offline ? Icons.wifi_off : Icons.cloud_off,
              title: state.offline
                  ? 'Você está sem internet'
                  : 'Não deu para abrir a receita',
              message: state.errorMessage ?? 'Tente novamente em instantes.',
              actionLabel: 'Tentar de novo',
              onAction: state.load,
            ),
          ),
        ];
      case LoadStatus.ready:
        final detail = state.detail!;
        return [
          if (state.offline)
            SliverToBoxAdapter(
              child: MaterialBanner(
                content: const Text('Sem internet — mostrando detalhes salvos'),
                actions: [
                  TextButton(
                    onPressed: state.load,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          SliverToBoxAdapter(child: _InfoChips(detail: detail)),
          SliverToBoxAdapter(child: _ShoppingButton(detail: detail)),
          SliverToBoxAdapter(child: _RecipeActions(detail: detail)),
          _sectionTitle(context, 'Ingredientes', detail.ingredients.length),
          SliverList.builder(
            itemCount: detail.ingredients.length,
            itemBuilder: (context, i) =>
                _IngredientRow(ingredient: detail.ingredients[i]),
          ),
          _sectionTitle(context, 'Modo de preparo', null),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              0,
              AppTokens.space5,
              AppTokens.space6,
            ),
            sliver: SliverList.builder(
              itemCount: detail.steps.length,
              itemBuilder: (context, i) =>
                  _StepRow(number: i + 1, text: detail.steps[i]),
            ),
          ),
        ];
    }
  }

  Widget _sectionTitle(BuildContext context, String title, int? count) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space5,
        AppTokens.space5,
        AppTokens.space3,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (count != null) ...[
              const SizedBox(width: AppTokens.space2),
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, bool wasFavorite) async {
    final favorites = context.read<FavoritesController>();
    final messenger = ScaffoldMessenger.of(context);
    // Usa o detalhe se já carregou (nome/foto oficiais), senão o resumo.
    final summary =
        context.read<MealDetailController>().detail?.toSummary() ?? meal;
    await favorites.toggle(summary);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite ? 'Removida dos favoritos' : 'Salva nos favoritos',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _ShoppingButton extends StatelessWidget {
  final MealDetail detail;

  const _ShoppingButton({required this.detail});

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingListController>();
    final included = shopping.containsMeal(detail.id);
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: FilledButton.tonalIcon(
        onPressed: !shopping.loaded || detail.ingredients.isEmpty
            ? null
            : () async {
                try {
                  if (included) {
                    await shopping.removeMeal(detail.id);
                  } else {
                    await shopping.addMeal(detail);
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        included
                            ? 'Receita removida da lista de compras'
                            : 'Ingredientes adicionados à lista de compras',
                      ),
                    ),
                  );
                } on Object {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não foi possível salvar a lista. Tente novamente.',
                      ),
                    ),
                  );
                }
              },
        icon: Icon(included ? Icons.check : Icons.add_shopping_cart),
        label: Text(
          included ? 'Na lista de compras' : 'Adicionar à lista de compras',
        ),
      ),
    );
  }
}

class _RecipeActions extends StatelessWidget {
  final MealDetail detail;

  const _RecipeActions({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        0,
        AppTokens.space5,
        AppTokens.space2,
      ),
      child: Wrap(
        spacing: AppTokens.space3,
        runSpacing: AppTokens.space2,
        children: [
          Builder(
            builder: (buttonContext) {
              return OutlinedButton.icon(
                onPressed: () => _share(buttonContext),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar'),
              );
            },
          ),
          if (detail.youtubeUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _openVideo(context),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Ver vídeo'),
            ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: shareText(detail),
          subject: detail.name,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      if (!context.mounted) return;
      _showError(
        context,
        'Não foi possível compartilhar a receita. Tente novamente.',
      );
    }
  }

  Future<void> _openVideo(BuildContext context) async {
    try {
      final url = Uri.tryParse(detail.youtubeUrl);
      if (url == null || url.scheme != 'https' || url.host.isEmpty) {
        _showError(context, 'O link do vídeo é inválido.');
        return;
      }
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showError(
          context,
          'Não foi possível abrir o vídeo. Verifique se há um navegador instalado.',
        );
      }
    } on Object {
      if (!context.mounted) return;
      _showError(context, 'Não foi possível abrir o vídeo. Tente novamente.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space1),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: color ?? scheme.onSurface),
        ),
      ),
    );
  }
}

class _InfoChips extends StatelessWidget {
  final MealDetail detail;

  const _InfoChips({required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <Widget>[
      if (detail.category.isNotEmpty)
        _infoChip(
          context,
          Icons.restaurant_menu,
          categoryLabel(detail.category),
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      if (detail.area.isNotEmpty)
        _infoChip(
          context,
          Icons.public,
          detail.area,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      for (final tag in detail.tags)
        _infoChip(
          context,
          Icons.tag,
          tag,
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
      child: Wrap(
        spacing: AppTokens.space2,
        runSpacing: AppTokens.space2,
        children: chips,
      ),
    );
  }

  Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;

  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space5,
        vertical: AppTokens.space1,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
            child: SizedBox(
              width: 44,
              height: 44,
              child: MealImage(
                url: ingredient.imageUrl,
                fit: BoxFit.contain,
                fallbackIcon: Icons.eco_outlined,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(ingredient.name, style: theme.textTheme.bodyLarge),
          ),
          if (ingredient.measure.isNotEmpty)
            Flexible(
              child: Text(
                ingredient.measure,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary,
            child: Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(width: 110, height: 30),
              SizedBox(width: AppTokens.space2),
              SkeletonBox(width: 80, height: 30),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          const SkeletonBox(width: 160, height: 22),
          const SizedBox(height: AppTokens.space3),
          for (var i = 0; i < 5; i++) ...[
            const Row(
              children: [
                SkeletonBox(width: 44, height: 44),
                SizedBox(width: AppTokens.space3),
                Expanded(child: SkeletonBox(height: 16)),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
          ],
        ],
      ),
    );
  }
}
