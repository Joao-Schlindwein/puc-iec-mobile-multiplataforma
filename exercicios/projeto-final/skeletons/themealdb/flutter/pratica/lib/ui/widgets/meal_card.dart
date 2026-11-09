import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../state/favorites_controller.dart';
import '../../state/translation_controller.dart';
import '../theme.dart';
import 'meal_image.dart';

/// Card da grade: foto quadrada, nome e coração para favoritar sem precisar
/// abrir o detalhe.
class MealCard extends StatelessWidget {
  final MealSummary meal;
  final VoidCallback onTap;

  const MealCard({super.key, required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = context.watch<TranslationController>().text(meal.name);
    final isFavorite = context.select<FavoritesController, bool>(
      (c) => c.isFavorite(meal.id),
    );

    return Semantics(
      identifier: 'item-card-${meal.id}',
      button: true,
      label: name,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MealImage(url: meal.thumbUrl),
                    Positioned(
                      top: AppTokens.space2,
                      right: AppTokens.space2,
                      child: _FavoriteBadge(
                        isFavorite: isFavorite,
                        onPressed: () =>
                            context.read<FavoritesController>().toggle(meal),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space3,
                  AppTokens.space2,
                  AppTokens.space3,
                  AppTokens.space3,
                ),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteBadge extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteBadge({required this.isFavorite, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
        onPressed: onPressed,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? scheme.primary : scheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
