import 'package:flutter/material.dart';

import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';

/// Heart animation played on a double tap.
///
/// Mirrors the reference app: a single big white heart pops at [position],
/// overshoots slightly, holds, then lifts and fades while a soft shockwave
/// expands behind it.
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
    duration: const Duration(milliseconds: 820),
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
      left: widget.position.dx - 70,
      top: widget.position.dy - 70,
      width: 140,
      height: 140,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _BurstPainter(progress: _controller.value),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final center = size.center(Offset.zero);

    // 0 → 22% pop in with overshoot, 22 → 58% hold, 58 → 100% lift and fade.
    final popIn = Curves.easeOutBack.transform((t / 0.22).clamp(0.0, 1.0));
    final settle = t <= 0.22 ? 0.0 : ((t - 0.22) / 0.36).clamp(0.0, 1.0);
    final fade = t < 0.58 ? 0.0 : ((t - 0.58) / 0.42).clamp(0.0, 1.0);

    final scale = (0.35 + popIn * 0.75) - settle * 0.10 + fade * 0.16;
    final opacity = popIn * (1 - Curves.easeIn.transform(fade));
    final lift = Curves.easeIn.transform(fade) * -14;
    final rotation = (1 - popIn) * -0.12;

    final ring = (t / 0.42).clamp(0.0, 1.0);
    if (ring < 1) {
      canvas.drawCircle(
        center,
        18 + Curves.easeOutCubic.transform(ring) * 52,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - ring) * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + (1 - ring) * 2.5,
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy + lift);
    canvas.rotate(rotation);
    canvas.scale(scale);
    final heart = _heartPath(64);
    canvas.drawPath(
      heart,
      Paint()
        ..color = Colors.black.withValues(alpha: opacity * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      heart,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  Path _heartPath(double size) {
    final s = size / 24;
    return Path()
      ..moveTo(12 * s, 21.1 * s)
      ..cubicTo(11.4 * s, 21.1 * s, 10.8 * s, 20.8 * s, 10.2 * s, 20.3 * s)
      ..cubicTo(6.5 * s, 17.4 * s, 2.8 * s, 14.0 * s, 2.8 * s, 9.5 * s)
      ..cubicTo(2.8 * s, 6.2 * s, 5.4 * s, 3.8 * s, 8.5 * s, 3.8 * s)
      ..cubicTo(10.2 * s, 3.8 * s, 11.4 * s, 4.6 * s, 12 * s, 5.5 * s)
      ..cubicTo(12.6 * s, 4.6 * s, 13.8 * s, 3.8 * s, 15.5 * s, 3.8 * s)
      ..cubicTo(18.6 * s, 3.8 * s, 21.2 * s, 6.2 * s, 21.2 * s, 9.5 * s)
      ..cubicTo(21.2 * s, 14.0 * s, 17.5 * s, 17.4 * s, 13.8 * s, 20.3 * s)
      ..cubicTo(13.2 * s, 20.8 * s, 12.6 * s, 21.1 * s, 12 * s, 21.1 * s)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress;
}

/// Play mark shown while the video is paused: a bare glyph that scales in,
/// no dark disc.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: durationFast,
        child: AnimatedScale(
          scale: visible ? 1 : 1.28,
          duration: durationNormal,
          curve: Curves.easeOutCubic,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Color(0x66000000), blurRadius: 22),
                ],
              ),
              child: ReelIcon(
                ReelGlyph.play,
                size: 78,
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
