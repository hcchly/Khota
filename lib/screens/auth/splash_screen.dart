
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Khota animated brand introduction.
/// Dark splash only. The rest of the app stays light.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.auth,
  });

  final AuthService? auth;

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AuthService _auth =
      widget.auth ?? FirebaseAuthService.instance;

  late final AnimationController _controller =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  late final Animation<double> _logoReveal =
      CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      0.05,
      0.80,
      curve: Curves.easeOutCubic,
    ),
  );

  late final Animation<double> _taglineFade =
      CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      0.55,
      0.95,
      curve: Curves.easeOut,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;

      Future<void>.delayed(
        const Duration(milliseconds: 800),
        _goNext,
      );
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(
          const Duration(milliseconds: 500),
          _goNext,
        );
      });
    }
  }

  void _goNext() {
    if (!mounted) return;

    final next = _auth.currentUser == null
        ? const LoginScreen()
        : const MainShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 450),

        pageBuilder: (_, __, ___) => next,

        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(
          opacity: animation,
          child: child,
        ),
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

      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.43, 0.80, 1.0],
            colors: [
              AppColors.ink,
              AppColors.ink,
              AppColors.ocean,
              AppColors.mint,
            ],
          ),
        ),

        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              final logoWidth =
                  math.min(width * 0.84, 410.0);

              final backgroundSymbolSize =
                  math.min(width * 3.2, 1400.0);

              return Stack(
                fit: StackFit.expand,
                children: [

                  // Large transparent symbol at the top
                  Positioned(
                    top: -backgroundSymbolSize * 0.40,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.09,
                        child: Center(
                          child: Image.asset(
                            'assets/images/khota_symbol_original.png',
                            width: backgroundSymbolSize,
                            height: backgroundSymbolSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Full original logo revealed tile by tile
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return _PavingTileLogo(
                          width: logoWidth,
                          progress: _logoReveal.value,
                        );
                      },
                    ),
                  ),

                  // Bottom tagline
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: math.max(
                      30.0,
                      height * 0.065,
                    ),
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'معًا لأرصفة أفضل',
                        textAlign: TextAlign.center,
                        style:
                            text.titleMedium?.copyWith(
                          color: AppColors.mist,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Reveal the real full logo through paving-shaped tiles.
class _PavingTileLogo extends StatelessWidget {
  const _PavingTileLogo({
    required this.width,
    required this.progress,
  });

  final double width;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // The source PNG is square with transparent space.
    // This crop makes the actual logo larger and clearer.
    final height = width * 0.45;
    final imageSize = width * 1.5;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: ClipPath(
          clipper: _SidewalkTileClipper(progress),
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: imageSize,
            maxWidth: imageSize,
            minHeight: imageSize,
            maxHeight: imageSize,
            child: Image.asset(
              'assets/images/khota_logo_new.png',
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              semanticLabel: 'شعار خُطى',
            ),
          ),
        ),
      ),
    );
  }
}

/// 6 columns × 3 rows = 18 rectangular tiles.
class _SidewalkTileClipper
    extends CustomClipper<Path> {

  const _SidewalkTileClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    const columns = 6;
    const rows = 3;

    final tileWidth = size.width / columns;
    final tileHeight = size.height / rows;

    final mask = Path();

    for (var row = 0; row < rows; row++) {
      for (var column = 0;
          column < columns;
          column++) {

        final tile = row * columns + column;

        final raw = (
          (progress - tile * 0.025) / 0.42
        ).clamp(0.0, 1.0).toDouble();

        final reveal =
            Curves.easeOutCubic.transform(raw);

        if (reveal > 0) {
          mask.addRect(
            Rect.fromLTWH(
              column * tileWidth,
              row * tileHeight +
                  tileHeight * (1 - reveal),
              tileWidth,
              tileHeight * reveal,
            ),
          );
        }
      }
    }

    return mask;
  }

  @override
  bool shouldReclip(
    covariant _SidewalkTileClipper oldClipper,
  ) {
    return oldClipper.progress != progress;
  }
}
