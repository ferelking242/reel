import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Pulsing « LIVE » pill.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.compact = false});

  final bool compact;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion ? 1.0 : 0.72 + _controller.value * 0.28;
        return Opacity(
          opacity: t,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? space6 : space8,
              vertical: widget.compact ? 1.5 : 2.5,
            ),
            decoration: BoxDecoration(
              color: colorLiveRed,
              borderRadius: BorderRadius.circular(radiusXs),
            ),
            child: Text(
              'LIVE',
              style: AppTokens.caption.copyWith(
                color: Colors.white,
                fontSize: widget.compact ? 9 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small red dot used in lists to signal a live stream.
class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: colorLiveRed,
        shape: BoxShape.circle,
      ),
    );
  }
}
