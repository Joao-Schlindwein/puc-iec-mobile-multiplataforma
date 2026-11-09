import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../state/favorites_controller.dart';
import '../state/translation_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets/meal_image.dart';
import '../ui/widgets/state_message.dart';
import '../ui/widgets/translation_toggle.dart';
import 'detail_screen.dart';

/// Feature 5: receitas favoritadas, salvas no aparelho. Abre sem internet
/// (nome e foto ficam guardados; a foto vem do cache de imagens quando há).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final items = favorites.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: const [TranslationToggle()],
      ),
      body: !favorites.loaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const StateMessage(
              icon: Icons.favorite_border,
              title: 'Nenhum favorito ainda',
              message:
                  'Toque no coração de uma receita para guardá-la '
                  'aqui. Ela continua salva mesmo se você fechar o app.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTokens.space4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTokens.space3),
              itemBuilder: (context, index) =>
                  _FavoriteTile(meal: items[index], index: index),
            ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final MealSummary meal;
  final int index;

  const _FavoriteTile({required this.meal, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey('favorite-${meal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => _remove(context),
      child: Semantics(
        identifier: 'favorite-item-${meal.id}',
        child: Card(
          child: InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => DetailScreen(meal: meal))),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: MealImage(url: meal.thumbUrl),
                ),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  child: Text(
                    context.watch<TranslationController>().text(meal.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover dos favoritos',
                  icon: Icon(Icons.favorite, color: scheme.primary),
                  onPressed: () => _remove(context),
                ),
                const SizedBox(width: AppTokens.space1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _remove(BuildContext context) {
    final favorites = context.read<FavoritesController>();
    favorites.remove(meal.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '"${context.read<TranslationController>().peek(meal.name)}" saiu dos favoritos',
          ),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => favorites.add(meal, index: index),
          ),
        ),
      );
  }
}
