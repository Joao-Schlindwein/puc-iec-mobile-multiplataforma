import 'package:flutter/material.dart';

/// Foto de rede com placeholder enquanto carrega e ícone de fallback se a
/// URL estiver vazia ou a imagem falhar (sem internet, 404…).
class MealImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;

  const MealImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(fallbackIcon, color: scheme.onSurfaceVariant, size: 32),
      ),
    );
    if (url.isEmpty) return placeholder;

    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: frame == null
              ? ColoredBox(
                  key: const ValueKey('loading'),
                  color: scheme.surfaceContainerHighest,
                  child: const SizedBox.expand(),
                )
              : child,
        );
      },
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
