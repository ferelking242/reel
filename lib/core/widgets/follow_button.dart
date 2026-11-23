import 'package:flutter/material.dart';

import '../haptics.dart';
import '../icons/reel_icons.dart';
import '../theme/tokens.dart';

/// Animated follow control.
///
/// [compact] renders the small pill used in lists, the default renders the
/// 36px high call to action used on profiles.
class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    this.initialFollowing = false,
    this.compact = false,
    this.onChanged,
    this.label = 'Suivre',
    this.followingLabel = 'Suivi(e)',
  });

  final bool initialFollowing;
  final bool compact;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String followingLabel;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late bool _following = widget.initialFollowing;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: durationNormal,
  );

  @override
  void initState() {
    super.initState();
    if (_following) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFollowing != widget.initialFollowing &&
        widget.initialFollowing != _following) {
      setState(() => _following = widget.initialFollowing);
      if (_following) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _following = !_following);
    _following ? _controller.forward() : _controller.reverse();
    Haptics.medium();
    widget.onChanged?.call(_following);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 28.0 : 36.0;
    final radius = BorderRadius.circular(radiusSm);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final following = _following;
          return AnimatedContainer(
            duration: durationNormal,
            curve: ReelCurves.emphasized,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? space12 : space20,
            ),
            decoration: BoxDecoration(
              color: following ? Colors.transparent : colorBrand,
              border: following
                  ? Border.all(color: colorDivider, width: 1)
                  : null,
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: durationFast,
                  child: following
                      ? ReelIcon(
                          ReelGlyph.check,
                          key: const ValueKey('check'),
                          size: widget.compact ? 12 : 14,
                          color: colorTextSecondary,
                        )
                      : ReelIcon(
                          ReelGlyph.plus,
                          key: const ValueKey('plus'),
                          size: widget.compact ? 12 : 14,
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                ),
                SizedBox(width: widget.compact ? space4 : space6),
                Text(
                  following ? widget.followingLabel : widget.label,
                  style: (widget.compact
                          ? AppTokens.labelM
                          : AppTokens.titleS)
                      .copyWith(
                    color: following ? colorTextSecondary : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
