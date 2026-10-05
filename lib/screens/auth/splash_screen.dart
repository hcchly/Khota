import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_header.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Animated intro: the pedestrian walks in, the name and tagline fade in,
/// then the app opens the login screen (or the home screen if signed in).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _auth = widget.auth ?? MockAuthService.instance;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // Timeline (0 → 1).
  late final Animation<double> _walk = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
  );
  late final Animation<double> _nameFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.75, curve: Curves.easeIn),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Respect the phone's "reduce motion" setting.
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
    final next = _auth.currentUser == null
        ? const LoginScreen()
        : const MainShell();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
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
      body: GradientHeader(
        bottomRadius: 0,
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _walk.value;
                  // Walk in from the left (the pedestrian faces right),
                  // with a small up-and-down step while moving.
                  final dx = -width * 0.6 * (1 - t);
                  final dy = -math.sin(t * math.pi * 8).abs() * 6 * (1 - t);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.translate(
                          offset: Offset(dx, dy),
                          child: Image.asset(
                            'assets/images/khota_logo.png',
                            width: math.min(width * 0.7, 320),
                            semanticLabel: 'شعار خُطى',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: _nameFade.value,
                        child: Text(
                          'خُطى',
                          style: text.displayMedium?.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Text(
                          'معاً لأرصفة أفضل',
                          style: text.titleMedium?.copyWith(
                            color: AppColors.tealLight,
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
    );
  }
}
