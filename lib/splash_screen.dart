import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/icons/reel_icons.dart';
import 'core/theme/tokens.dart';

/// Brand splash: the Reel mark pops in, then the feed takes over.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1500), _goToFeed);
  }

  void _goToFeed() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
    );
    final textFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return GestureDetector(
      onTap: _goToFeed,
      child: Scaffold(
        backgroundColor: colorBgBase,
        body: Stack(
          children: [
            // Ambient brand glows.
            const Positioned(
              top: -120,
              right: -80,
              child: _Glow(color: colorBrand, size: 320),
            ),
            const Positioned(
              bottom: -140,
              left: -100,
              child: _Glow(color: colorBrandCyan, size: 300),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final glow = 0.6 + _pulse.value * 0.4;
                      return Opacity(opacity: glow, child: child);
                    },
                    child: ScaleTransition(
                      scale: logoScale,
                      child: const ReelMark(size: 104),
                    ),
                  ),
                  const SizedBox(height: space24),
                  FadeTransition(
                    opacity: textFade,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFD8D8DA)],
                          ).createShader(bounds),
                          child: const Text(
                            'Reel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: space6),
                        Text(
                          'Propulsé par Watchtower',
                          style: AppTokens.labelS.copyWith(
                            color: colorTextSecondaryDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: textFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _entrance,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _entrance.value,
                            backgroundColor: colorDivider,
                            valueColor: const AlwaysStoppedAnimation(
                              colorBrand,
                            ),
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: space12),
                    Text(
                      'Touche pour continuer',
                      style: AppTokens.caption.copyWith(
                        color: colorTextSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
