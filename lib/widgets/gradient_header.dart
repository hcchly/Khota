import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand_surface.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 30,
  });

  final Widget child;
  final double bottomRadius;

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
          alignment: Alignment.topCenter,
          child: SafeArea(bottom: false, child: child),
        ),
      ),
    );
  }
}
