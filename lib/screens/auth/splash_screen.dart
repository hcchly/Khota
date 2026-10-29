import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// New splash:
/// - dark brand look
/// - logo reveals tile-by-tile like sidewalk blocks
/// - wordmark appears separately for a cleaner result
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _auth = widget.auth ?? FirebaseAuthService.instance;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  late final Animation<double> _logoReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.00, 0.58, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _nameFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.78, curve: Curves.easeOut),
  );

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 0.92, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      Future<void>.delayed(const Duration(milliseconds: 800), _goNext);
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(const Duration(milliseconds: 500), _goNext);
      });
    }
  }

  void _goNext() {
    if (!mounted) return;
    final next =
        _auth.currentUser == null ? const LoginScreen() : const MainShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackgroundPattern()),
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoWidth = constraints.maxWidth > 500 ? 220.0 : 180.0;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TileRevealLogo(
                            width: logoWidth,
                            progress: _logoReveal.value,
                          ),
                          const SizedBox(height: 28),
                          Opacity(
                            opacity: _nameFade.value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - _nameFade.value)),
                              child: Text(
                                'خُطى',
                                style: text.displayMedium?.copyWith(
                                  color: AppColors.mist,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: _taglineFade.value,
                            child: Transform.translate(
                              offset:
                                  Offset(0, 10 * (1 - _taglineFade.value)),
                              child: Text(
                                'معاً لأرصفة أفضل',
                                style: text.titleMedium?.copyWith(
                                  color: AppColors.mint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileRevealLogo extends StatelessWidget {
  const _TileRevealLogo({
    required this.width,
    required this.progress,
  });

  final double width;
  final double progress;

  static const int cols = 4;
  static const int rows = 3;
  static const double imageAspectRatio = 512 / 278;

  @override
  Widget build(BuildContext context) {
    final height = width / imageAspectRatio;
    final tileWidth = width / cols;
    final tileHeight = height / rows;
    final totalTiles = rows * cols;

    return Semantics(
      label: 'شعار خُطى',
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: List.generate(totalTiles, (index) {
            final row = index ~/ cols;
            final col = index % cols;

            final start = index * 0.05;
            const duration = 0.28;
            final raw = ((progress - start) / duration).clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(raw);

            return Positioned(
              left: col * tileWidth,
              top: row * tileHeight,
              width: tileWidth,
              height: tileHeight,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - t)),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment(
                        -1 + ((col * 2 + 1) / cols),
                        -1 + ((row * 2 + 1) / rows),
                      ),
                      widthFactor: 1 / cols,
                      heightFactor: 1 / rows,
                      child: Image.asset(
                         'assets/images/khota_symbol_original.png',
                        width: width,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SplashBackgroundPattern extends StatelessWidget {
  const _SplashBackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SplashPatternPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.ink;
    canvas.drawRect(Offset.zero & size, base);

    final lines = Paint()
      ..color = AppColors.mist.withValues(alpha: 0.05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        lines,
      );
    }

    final glow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.ocean,
          AppColors.mint,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..color = Colors.white.withValues(alpha: 0.10);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.78,
        height: size.height * 0.42,
      ),
      const Radius.circular(36),
    );

    canvas.drawRRect(
      rect,
      glow..color = AppColors.ocean.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
