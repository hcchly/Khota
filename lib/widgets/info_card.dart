import 'package:flutter/material.dart';

import '../theme/khota_colors.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Card fill; the theme's card colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color, this.size = 48});

  final IconData icon;

  /// Icon colour; the theme's accent when null.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final color = this.color ?? colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colors.tint(color, 0.16), colors.tint(color, 0.06)],
        ),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}
