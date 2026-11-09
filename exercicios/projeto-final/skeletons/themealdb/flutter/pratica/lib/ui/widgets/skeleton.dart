import 'package:flutter/material.dart';

import '../theme.dart';

/// Bloco que pulsa suavemente enquanto o conteúdo carrega (skeleton), no
/// lugar de um spinner solto.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppTokens.radiusS,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (reduceMotion) return box;
    return FadeTransition(opacity: _pulse, child: box);
  }
}

/// Grade de cards-esqueleto com o mesmo formato da grade de receitas.
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;

  const SkeletonGrid({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTokens.space4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppTokens.space3,
        crossAxisSpacing: AppTokens.space3,
        childAspectRatio: 0.78,
      ),
      itemCount: crossAxisCount * 4,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: SkeletonBox(radius: AppTokens.radiusM)),
          SizedBox(height: AppTokens.space2),
          SkeletonBox(height: 14, width: 120),
          SizedBox(height: AppTokens.space1),
          SkeletonBox(height: 14, width: 70),
        ],
      ),
    );
  }
}
