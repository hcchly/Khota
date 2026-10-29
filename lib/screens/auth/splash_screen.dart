import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Khota animated splash.
///
/// Motion:
///  1. The chevron mark is laid like sidewalk pavers: small tiles drop in
///     and settle, from the bottom-left to the top-right.
///  2. A small pulse when the mark is complete.
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

  /// Progress (0..1) of a segment between [from] and [to] seconds.
  double _seg(double from, double to) {
    final t = _controller.value * _total;
    return ((t - from) / (to - from)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: [Color(0xFF0D2A33), AppColors.ink, Color(0xFF0A2F2C)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final logoWidth = math.min(w * 0.74, 380.0);
            final watermark = w * 1.05;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Mint glow rising from the bottom-left corner.
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.bottomLeft,
                          radius: 1.25,
                          colors: [
                            Color(0xF240BA87),
                            Color(0x5940BA87),
                            Color(0x0040BA87),
                          ],
                          stops: [0.0, 0.38, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),

                // Large faint mark, top-right, partly off-screen.
                Positioned(
                  top: -watermark * 0.10,
                  right: -watermark * 0.22,
                  width: watermark,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.07,
                      child: Image.asset(
                        'assets/images/khota_mark_mist.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),

                // Logo.
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.08),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _KhotaLogo(
                        width: logoWidth,
                        time: _controller.value * _total,
                        wordProgress: _seg(1.15, 1.75),
                      ),
                    ),
                  ),
                ),

                // Tagline.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: math.max(40.0, h * 0.09),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final p = Curves.easeOut.transform(_seg(1.75, 2.35));
                      return Opacity(
                        opacity: p,
                        child: Transform.translate(
                          offset: Offset(0, 6 * (1 - p)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'معًا لأرصفة أفضل',
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: AppColors.mist,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Word on the left, mark on the right (brand lockup, always left-to-right).
/// Proportions come from the original logo artwork (811 x 250 units).
class _KhotaLogo extends StatelessWidget {
  const _KhotaLogo({
    required this.width,
    required this.time,
    required this.wordProgress,
  });

  final double width;
  final double time;
  final double wordProgress;

  static const double _unitsW = 811, _unitsH = 250;
  static const double _wordW = 445, _wordH = 215, _wordTop = 0;
  static const double _markW = 338, _markH = 248, _markTop = 2;

  @override
  Widget build(BuildContext context) {
    final s = width / _unitsW;
    final p = Curves.easeOutCubic.transform(wordProgress);

    return Semantics(
      label: 'شعار خُطى',
      image: true,
      child: SizedBox(
        width: width,
        height: _unitsH * s,
        child: Stack(
          clipBehavior: Clip.none,
          textDirection: TextDirection.ltr,
          children: [
            // Word: smooth reveal from the side next to the mark.
            Positioned(
              left: 0,
              top: _wordTop * s,
              width: _wordW * s,
              height: _wordH * s,
              child: Opacity(
                opacity: p,
                child: Transform.translate(
                  offset: Offset(10 * (1 - p), 0),
                  child: ClipRect(
                    clipper: _RevealFromRight(p),
                    child: Image.asset(
                      'assets/images/khota_word_mist.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
            // Mark: laid tile by tile.
            Positioned(
              right: 0,
              top: _markTop * s,
              width: _markW * s,
              height: _markH * s,
              child: _PaverMark(time: time),
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
      size.width * (1 - progress), 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_RevealFromRight old) => old.progress != progress;
}

/// The chevron mark built from 11 x 8 "paver" tiles.
class _PaverMark extends StatelessWidget {
  const _PaverMark({required this.time});

  final double time;

  static const int cols = 11, rows = 8;

  /// Cells that contain part of the mark (1) or are empty (0).
  static const List<String> _mask = [
    '00001111100',
    '01111111110',
    '11111111111',
    '11110111111',
    '00111111111',
    '11111111111',
    '11111011110',
    '11000001110',
  ];

  static const double _tileDuration = 0.38;
  static const double _doneAt = 1.12;

  static final List<_Tile> _tiles = () {
    final rnd = math.Random(7);
    final list = <_Tile>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_mask[r][c] != '1') continue;
        final delay =
            ((rows - 1 - r) * 0.75 + c) * 0.045 + rnd.nextDouble() * 0.05;
        list.add(_Tile(r, c, delay));
      }
    }
    return list;
  }();

  static double _easeOutBack(double t) {
    const s = 1.6;
    final x = t - 1;
    return 1 + (s + 1) * x * x * x + s * x * x;
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/khota_mark_mist.png',
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );

    // Small pulse once every tile is in place.
    var pulse = 1.0;
    if (time > 1.1 && time < 1.35) {
      pulse = 1 + 0.04 * math.sin((time - 1.1) / 0.25 * math.pi);
    }

    // After the last tile lands, draw the whole image (no tile seams).
    if (time >= _doneAt + 0.05) {
      return Transform.scale(scale: pulse, child: image);
    }

    return Transform.scale(
      scale: pulse,
      child: LayoutBuilder(
        builder: (context, box) {
          final tw = box.maxWidth / cols;
          final th = box.maxHeight / rows;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tile in _tiles)
                _buildTile(tile, tw, th, box.biggest, image),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTile(_Tile tile, double tw, double th, Size size, Widget image) {
    final raw =
        ((time - tile.delay) / _tileDuration).clamp(0.0, 1.0).toDouble();
    if (raw == 0) return const SizedBox.shrink();

    final e = _easeOutBack(raw);
    final dy = (1 - e) * 18;
    final scale = 0.55 + 0.45 * math.min(1.0, e);
    final rect = Rect.fromLTWH(tile.c * tw, tile.r * th, tw + 0.6, th + 0.6);

    return Positioned.fill(
      child: Opacity(
        opacity: math.min(1.0, raw * 1.6),
        child: Transform(
          // Scale each tile around its own centre and drop it into place.
          transform: Matrix4.identity()
            ..translateByDouble(rect.center.dx, rect.center.dy + dy, 0, 1)
            ..scaleByDouble(scale, scale, 1, 1)
            ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1),
          child: ClipRect(clipper: _TileClip(rect), child: image),
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.r, this.c, this.delay);
  final int r, c;
  final double delay;
}

class _TileClip extends CustomClipper<Rect> {
  const _TileClip(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_TileClip old) => old.rect != rect;
}
