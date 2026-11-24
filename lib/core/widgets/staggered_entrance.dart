import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Fades and slides a child in, offset in time by its position in a list.
///
/// Used by lists that appear as a whole (notifications, search results) so the
/// first paint reads as a single cascade instead of everything popping at once.
/// Items far down the list skip the delay so scrolling never feels laggy.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 38),
    this.duration = const Duration(milliseconds: 380),
    this.slide = 14,
    this.maxAnimated = 10,
  });

  final int index;
  final Widget child;
  final Duration step;
  final Duration duration;
  final double slide;
  final int maxAnimated;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.index >= widget.maxAnimated) {
      _controller.value = 1;
      return;
    }
    final delay = widget.step * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: ReelCurves.emphasized,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.slide / 100),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
