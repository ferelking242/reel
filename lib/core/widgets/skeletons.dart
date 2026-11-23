import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Animated shimmer used by skeletons and image placeholders.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final base = widget.baseColor ?? colorBgCard;
    final highlight = widget.highlightColor ?? const Color(0xFF2C2C2E);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + t * 3.2, -0.4),
              end: Alignment(-0.6 + t * 3.2, 0.4),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// A rounded rectangle placeholder used while content loads.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = radiusMd,
    this.margin,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton row used by lists (comments, inbox, search results).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.avatarSize = 40,
    this.lines = 2,
    this.padding = const EdgeInsets.symmetric(
      horizontal: gutter,
      vertical: space12,
    ),
  });

  final double avatarSize;
  final int lines;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: avatarSize,
            height: avatarSize,
            radius: avatarSize / 2,
          ),
          const SizedBox(width: space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 12, radius: radiusSm),
                for (var i = 0; i < lines; i++) ...[
                  const SizedBox(height: space8),
                  FractionallySizedBox(
                    widthFactor: i.isEven ? 0.9 : 0.65,
                    child: const SkeletonBox(
                      height: 10,
                      radius: radiusSm,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
