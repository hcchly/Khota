import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indigo-to-teal header with a faint paving pattern and a curved bottom.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 28,
  });

  final Widget child;
  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.indigo, AppColors.teal],
          ),
        ),
        child: CustomPaint(
          painter: _PavingPatternPainter(),
          child: SafeArea(bottom: false, child: child),
        ),
      ),
    );
  }
}

class _PavingPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        lines,
      );
    }

    // Curved line, like the one under the pedestrian in the logo.
    final curve = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.55,
        size.width,
        size.height * 0.85,
      );
    canvas.drawPath(path, curve);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
