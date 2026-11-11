import 'package:flutter/material.dart';

import '../theme/khota_colors.dart';

/// Which brand pattern a [BrandSurface] shows.
enum BrandArt {
  /// Headers, app bars and intro cards.
  header,

  /// The full-screen splash.
  splash,
}

/// The shared Khota surface: the brand pattern image for the current theme,
/// with the brand gradient behind it as a fallback while the image loads.
class BrandSurface extends StatelessWidget {
  const BrandSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(22),
    this.art = BrandArt.header,
    this.alignment = Alignment.centerLeft,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final BrandArt art;

  /// Where the pattern is anchored when cropped (cover).
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final image = art == BrandArt.splash
        ? colors.splashImage
        : colors.headerImage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: colors.headerFallback,
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            alignment: alignment,
            filterQuality: FilterQuality.medium,
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BrandIntro extends StatelessWidget {
  const BrandIntro({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.eyebrow,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BrandSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: text.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  description,
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
