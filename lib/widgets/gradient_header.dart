import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand header: dark navy with the Khota background art (design pages 4-6)
/// and a curved bottom.
///
/// [pattern] picks the art: 4 = subtle, 5 = diagonal shapes, 6 = chevron arrows.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 28,
    this.pattern = 6,
  });

  final Widget child;
  final double bottomRadius;
  final int pattern;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink,
          image: brandBackground(pattern),
        ),
        child: SafeArea(bottom: false, child: child),
      ),
    );
  }
}

/// The brand background art as a [DecorationImage] (pattern 4, 5 or 6).
DecorationImage brandBackground(int pattern) {
  final p = (pattern < 4 || pattern > 6) ? 6 : pattern;
  return DecorationImage(
    image: AssetImage('assets/images/brand_bg_$p.jpg'),
    fit: BoxFit.cover,
    alignment: Alignment.centerRight,
    filterQuality: FilterQuality.medium,
  );
}
