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
    duration: const Duration(milliseconds: 900),
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

  static const _particles = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = progress.clamp(0.0, 1.0);

    // Main heart: pop past its final size, settle, then fade out.
    final pop = t < 0.3
        ? Curves.easeOutBack.transform(t / 0.3) * 1.22
        : 1.22 - Curves.easeOut.transform((t - 0.3) / 0.7) * 0.16;
    final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
    final rotation = (1 - Curves.easeOut.transform(t.clamp(0.0, 0.35) / 0.35)) *
        -0.22;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(pop);
    final heart = _heartPath(58);
    canvas.drawPath(
      heart,
      Paint()
        ..color = colorLike.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      heart,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
    canvas.drawPath(
      heart,
      Paint()
        ..color = colorLike.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.restore();

    // Expanding ring behind the heart.
    final ringT = (t / 0.55).clamp(0.0, 1.0);
    if (ringT < 1) {
      canvas.drawCircle(
        center,
        26 + ringT * 46,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - ringT) * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - ringT) + 0.5,
      );
    }

    // Particles fly outwards, spin and shrink.
    final particleT = ((t - 0.04) / 0.72).clamp(0.0, 1.0);
    if (particleT > 0) {
      for (var i = 0; i < _particles; i++) {
        final angle = (i / _particles) * math.pi * 2 - math.pi / 2;
        final spread = i.isEven ? 1.0 : 0.72;
        final distance =
            (20 + Curves.easeOutCubic.transform(particleT) * 78) * spread;
        final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;
        final particleOpacity =
            (1 - particleT * particleT).clamp(0.0, 1.0);
        final scaleParticle = 0.5 + (1 - particleT) * 0.7;

        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(angle + particleT * math.pi);
        canvas.scale(scaleParticle);
        canvas.drawPath(
          _heartPath(i.isEven ? 18 : 12),
          Paint()
            ..color = switch (i % 3) {
              0 => colorBrand,
              1 => Colors.white,
              _ => colorBrandCyan,
            }.withValues(alpha: particleOpacity),
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
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress;
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
