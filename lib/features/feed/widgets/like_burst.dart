import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';

/// Heart animation played on a double tap.
///
/// A big heart pops at [position] while small hearts burst outwards.
class LikeBurst extends StatefulWidget {
  const LikeBurst({
    super.key,
    required this.position,
    this.onDone,
  });

  final Offset position;
  final VoidCallback? onDone;

  @override
  State<LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<LikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 80,
      top: widget.position.dy - 80,
      width: 160,
      height: 160,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _BurstPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  static const _particles = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = progress.clamp(0.0, 1.0);

    // Main heart: pop in, hold, fade out.
    final scale = t < 0.28
        ? Curves.easeOutBack.transform(t / 0.28) * 1.15
        : 1.15 - (t - 0.28) * 0.25;
    final opacity = t < 0.65 ? 1.0 : 1 - (t - 0.65) / 0.35;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final heart = _heartPath(52);
    canvas.drawPath(
      heart,
      Paint()
        ..color = colorLike.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      heart,
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.92),
    );
    canvas.restore();

    // Particles fly outwards then fade.
    final particleT = ((t - 0.05) / 0.7).clamp(0.0, 1.0);
    if (particleT > 0) {
      for (var i = 0; i < _particles; i++) {
        final angle = (i / _particles) * math.pi * 2 - math.pi / 2;
        final distance = 26 + particleT * (34 + (i.isEven ? 16 : 0));
        final offset = center +
            Offset(math.cos(angle), math.sin(angle)) * distance -
            const Offset(7, 7);
        final particleOpacity = (1 - particleT).clamp(0.0, 1.0);
        final scaleParticle = 0.55 + (1 - particleT) * 0.45;
        canvas.save();
        canvas.translate(offset.dx + 7, offset.dy + 7);
        canvas.scale(scaleParticle);
        canvas.translate(-7, -7);
        canvas.drawPath(
          _heartPath(14),
          Paint()
            ..color = (i.isEven ? colorBrand : Colors.white)
                .withValues(alpha: particleOpacity),
        );
        canvas.restore();
      }
    }
  }

  Path _heartPath(double size) {
    final s = size / 24;
    return Path()
      ..moveTo(12 * s, 20.6 * s)
      ..cubicTo(9.1 * s, 18.2 * s, 3.1 * s, 13.8 * s, 3.1 * s, 8.9 * s)
      ..cubicTo(3.1 * s, 5.9 * s, 5.3 * s, 3.7 * s, 8.1 * s, 3.7 * s)
      ..cubicTo(9.9 * s, 3.7 * s, 11.3 * s, 4.7 * s, 12 * s, 6 * s)
      ..cubicTo(12.7 * s, 4.7 * s, 14.1 * s, 3.7 * s, 15.9 * s, 3.7 * s)
      ..cubicTo(18.7 * s, 3.7 * s, 20.9 * s, 5.9 * s, 20.9 * s, 8.9 * s)
      ..cubicTo(20.9 * s, 13.8 * s, 14.9 * s, 18.2 * s, 12 * s, 20.6 * s)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}

/// Small icon shown when the user pauses a video.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: durationNormal,
        child: AnimatedScale(
          scale: visible ? 1 : 1.25,
          duration: durationNormal,
          curve: ReelCurves.decelerate,
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0x4D000000),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.play,
                  size: 34,
                  color: Color(0xE6FFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
