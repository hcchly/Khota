import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The shared Khota surface, drawn with the sidewalk mark's angled geometry.
class BrandSurface extends StatelessWidget {
  const BrandSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.ink, AppColors.ocean],
          ),
        ),
        child: CustomPaint(
          painter: const _PavingPattern(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PavingPattern extends CustomPainter {
  const _PavingPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 19;

    for (var i = 0; i < 3; i++) {
      paint.color = AppColors.mint.withValues(alpha: 0.13 - i * 0.025);
      final x = size.width * 0.10 + i * 19;
      final y = size.height * 0.25 + i * 43;
      final path = Path()
        ..moveTo(x - 42, y + 28)
        ..lineTo(x + 17, y)
        ..lineTo(x + 75, y + 33);
      canvas.drawPath(path, paint);
    }
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.mint.withValues(alpha: 0.28),
              AppColors.mint.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.08, size.height),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_PavingPattern oldDelegate) => false;
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
                      color: AppColors.mint,
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
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.ink, size: 26),
          ),
        ],
      ),
    );
  }
}
