import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand_surface.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 30,
    this.pattern = 6,
  });

  final Widget child;
  final double bottomRadius;
  final int pattern;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        child: BrandSurface(
          radius: 0,
          padding: EdgeInsets.zero,
          child: SafeArea(bottom: false, child: child),
        ),
      ),
    );
  }
}

/// Existing full-page art remains available to the pages that use it.
DecorationImage brandBackground(int pattern) {
  final index = pattern.clamp(4, 6);
  return DecorationImage(
    image: AssetImage('assets/images/brand_bg_$index.jpg'),
    fit: BoxFit.cover,
    alignment: Alignment.centerRight,
    filterQuality: FilterQuality.medium,
  );
}
