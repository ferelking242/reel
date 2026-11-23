import 'package:flutter/material.dart';

import '../haptics.dart';
import '../theme/tokens.dart';

/// Scales its child down while pressed and fires a light haptic on tap.
///
/// Used for icon buttons across the feed so every control feels tactile.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.88,
    this.haptic = HapticKind.light,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HapticKind haptic;
  final HitTestBehavior behavior;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

enum HapticKind { none, selection, light, medium, heavy }

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case HapticKind.none:
        break;
      case HapticKind.selection:
        Haptics.tap();
      case HapticKind.light:
        Haptics.light();
      case HapticKind.medium:
        Haptics.medium();
      case HapticKind.heavy:
        Haptics.heavy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final content = AnimatedScale(
      scale: _pressed && !reduceMotion ? widget.scale : 1,
      duration: durationFast,
      curve: ReelCurves.decelerate,
      child: widget.child,
    );

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                _fireHaptic();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                Haptics.medium();
                widget.onLongPress!();
              },
        child: content,
      ),
    );
  }
}
