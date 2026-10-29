
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Animated Khota splash screen.
/// The rest of the application remains in Light Mode.
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
    duration: const Duration(milliseconds: 3500),
  );

  late final Animation<double> _logoProgress =
      CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      0.03,
      0.80,
      curve: Curves.linear,
    ),
  );

  late final Animation<double> _taglineFade =
      CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      0.63,
      0.94,
      curve: Curves.easeOut,
    ),
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

      Future<void>.delayed(
        const Duration(milliseconds: 800),
        _goNext,
      );
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(
          const Duration(milliseconds: 650),
          _goNext,
        );
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
    final width = MediaQuery.sizeOf(context).width;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.46, 1.0],
            colors: [
              AppColors.ink,
              AppColors.ink,
              AppColors.ocean,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;

              final logoWidth =
                  math.min(screenWidth * 0.86, 420.0);

              final symbolSize =
                  math.min(screenWidth * 3.2, 1450.0);

              final glowSize =
                  math.min(screenWidth * 1.5, 600.0);

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Bright turquoise glow at bottom right.
                  Positioned(
                    right: -glowSize * 0.28,
                    bottom: -glowSize * 0.35,
                    width: glowSize,
                    height: glowSize,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.72,
                            colors: [
                              AppColors.mint.withValues(
                                alpha: 0.86,
                              ),
                              AppColors.mint.withValues(
                                alpha: 0.34,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [
                              0.0,
                              0.48,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Large faded original symbol.
                  Positioned(
                    top: -symbolSize * 0.36,
                    left: (screenWidth - symbolSize) / 2,
                    width: symbolSize,
                    height: symbolSize,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.13,
                        child: Image.asset(
                          'assets/images/khota_symbol_original.png',
                          width: symbolSize,
                          height: symbolSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),

                  // The logo assembles from 18 pieces.
                  Positioned.fill(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return _AssemblingKhotaLogo(
                            width: logoWidth,
                            progress: _logoProgress.value,
                          );
                        },
                      ),
                    ),
                  ),

                  // Slogan at bottom.
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: math.max(
                      28.0,
                      screenHeight * 0.06,
                    ),
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(_taglineFade),
                        child: Text(
                          'معًا لأرصفة أفضل',
                          textAlign: TextAlign.center,
                          style:
                              text.titleMedium?.copyWith(
                            color: AppColors.mist,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
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

/// The complete original logo, assembled from individual
/// rectangular sidewalk-like pieces.
class _AssemblingKhotaLogo extends StatelessWidget {
  const _AssemblingKhotaLogo({
    required this.width,
    required this.progress,
  });

  final double width;
  final double progress;

  static const int columns = 6;
  static const int rows = 3;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.40;

    return Semantics(
      label: 'شعار خُطى',
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0;
                index < columns * rows;
                index++)
              _buildTile(index),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(int index) {
    final row = index ~/ columns;
    final column = index % columns;

    // Stagger each tile so the pieces are visible.
    final start = index * 0.033;

    final raw =
        ((progress - start) / 0.30)
            .clamp(0.0, 1.0)
            .toDouble();

    final eased = Curves.easeOutCubic.transform(raw);

    // Pieces travel toward their final locations.
    final horizontalDistance =
        (column - (columns - 1) / 2) * 17.0;

    final verticalDistance =
        (row - (rows - 1) / 2) * 36.0;

    final dx =
        horizontalDistance * (1 - eased);

    final dy =
        verticalDistance * (1 - eased);

    return Positioned.fill(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: ClipRect(
              clipper: _LogoTileClipper(
                row: row,
                column: column,
              ),
              child: _FullLogoArtwork(
                width: width,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draw the full original image at the same size
/// for every tile, preserving exact alignment.
class _FullLogoArtwork extends StatelessWidget {
  const _FullLogoArtwork({
    required this.width,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    // The original 1241x1241 PNG has transparent
    // padding, so enlarge it without modifying it.
    final imageSize = width * 1.49;

    return OverflowBox(
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
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Each rectangle reveals its own section of the logo.
class _LogoTileClipper extends CustomClipper<Rect> {
  const _LogoTileClipper({
    required this.row,
    required this.column,
  });

  final int row;
  final int column;

  static const int columns = 6;
  static const int rows = 3;

  @override
  Rect getClip(Size size) {
    final tileWidth = size.width / columns;
    final tileHeight = size.height / rows;

    return Rect.fromLTWH(
      column * tileWidth,
      row * tileHeight,
      tileWidth,
      tileHeight,
    );
  }

  @override
  bool shouldReclip(
    covariant _LogoTileClipper oldClipper,
  ) {
    return oldClipper.row != row ||
        oldClipper.column != column;
  }
}
