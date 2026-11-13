import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/brand_surface.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Khota animated splash.
///
/// Motion:
///  1. Sidewalk pavers assemble the chevron mark row by row.
///  2. The completed mark briefly settles into place.
///  3. The Arabic word "خطى" is revealed smoothly (never split).
///  4. The tagline fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _auth = widget.auth ?? FirebaseAuthService.instance;

  /// Whole intro timeline in seconds.
  static const double _total = 2.6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _started = false;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up the header pattern for the current mode so the first screen's
    // header shows the image straight away, not the fallback colour.
    precacheImage(AssetImage(context.khota.headerImage), context);
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      Future<void>.delayed(const Duration(milliseconds: 1800), _goNext);
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(const Duration(milliseconds: 1300), _goNext);
      });
    }
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final next = _auth.currentUser == null
        ? const LoginScreen()
        : const MainShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress (0..1) of a segment between [from] and [to] seconds.
  double _seg(double from, double to) {
    final t = _controller.value * _total;
    return ((t - from) / (to - from)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.khota.isDark
            ? context.khota.background
            : AppColors.gradientTop,
        body: BrandSurface(
          radius: 0,
          padding: EdgeInsets.zero,
          art: BrandArt.splash,
          alignment: Alignment.center,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compact logo: about half the screen width, at most 220.
                final width = math.min(constraints.maxWidth * 0.52, 220.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _KhotaLogo(
                          width: width,
                          time: _controller.value * _total,
                          wordProgress: _seg(1.73, 2.16),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 42,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) =>
                            Opacity(opacity: _seg(2.02, 2.48), child: child),
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'أرصفة أفضل تبدأ بخطوة',
                              textAlign: TextAlign.center,
                              style: text.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The assembled mark appears above the original Arabic wordmark.
class _KhotaLogo extends StatelessWidget {
  const _KhotaLogo({
    required this.width,
    required this.time,
    required this.wordProgress,
  });

  final double width;
  final double time;
  final double wordProgress;

  @override
  Widget build(BuildContext context) {
    final progress = Curves.easeOutCubic.transform(wordProgress);
    return Semantics(
      label: 'شعار خُطى',
      image: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width * 0.66,
              height: width * 0.66 * 248 / 338,
              child: _PaverMark(time: time),
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - progress)),
                child: ClipRect(
                  clipper: _RevealFromRight(progress),
                  child: Image.asset(
                    'assets/images/khota_word_mist.png',
                    width: width * 0.62,
                    height: width * 0.62 * 215 / 445,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealFromRight extends CustomClipper<Rect> {
  const _RevealFromRight(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    size.width * (1 - progress),
    0,
    size.width * progress,
    size.height,
  );

  @override
  bool shouldReclip(_RevealFromRight old) => old.progress != progress;
}

/// Four courses of pavers laid from the bottom of the original mark.
class _PaverMark extends StatelessWidget {
  const _PaverMark({required this.time});

  final double time;

  static const _columns = 4;
  static const _rows = 4;
  static const _tileCount = _columns * _rows;
  static const _stagger = 0.085;
  static const _landingDuration = 0.36;
  static const _finished = (_tileCount - 1) * _stagger + _landingDuration;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/khota_mark_mist.png',
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );

    if (time >= _finished) {
      final settle = ((time - _finished) / 0.25).clamp(0.0, 1.0);
      return Transform.scale(
        scale: 1 + 0.035 * math.sin(settle * math.pi),
        child: image,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / _columns;
        final height = constraints.maxHeight / _rows;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _tileCount; i++)
              if (time > i * _stagger) _paver(i, width, height, image),
          ],
        );
      },
    );
  }

  Widget _paver(int index, double width, double height, Widget image) {
    final row = _rows - 1 - index ~/ _columns;
    final step = index % _columns;
    final column = row.isEven ? _columns - 1 - step : step;
    final progress = ((time - index * _stagger) / _landingDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final travel = 1 - Curves.easeOutCubic.transform(progress);
    final highlight = math.sin(progress * math.pi);
    final area = Rect.fromLTWH(
      column * width,
      row * height,
      width + (column < _columns - 1 ? 0.5 : 0),
      height + (row < _rows - 1 ? 0.5 : 0),
    );

    return Positioned.fill(
      child: Opacity(
        opacity: math.min(1.0, progress * 3),
        child: Transform.translate(
          offset: Offset((column.isEven ? -10 : 10) * travel, -26 * travel),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(clipper: _TileClip(area), child: image),
              ),
              Positioned.fromRect(
                rect: area.deflate(1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11 * highlight),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.425 * highlight),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileClip extends CustomClipper<Rect> {
  const _TileClip(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_TileClip old) => old.rect != rect;
}
