import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';


/// Thin, seekable progress bar pinned to the bottom of a feed page.
class FeedProgressBar extends StatefulWidget {
  const FeedProgressBar({super.key, required this.player});

  final Player player;

  @override
  State<FeedProgressBar> createState() => _FeedProgressBarState();
}

class _FeedProgressBarState extends State<FeedProgressBar> {
  double? _dragFraction;
  double _width = 0;

  void _seekTo(double fraction, {required Duration duration}) {
    if (duration.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (duration.inMilliseconds * fraction).round(),
    );
    widget.player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: widget.player.state.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final played = duration.inMilliseconds > 0
                ? (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0;
            final fraction = _dragFraction ?? played;

            return LayoutBuilder(
              builder: (context, constraints) {
                _width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final value =
                        (details.localPosition.dx / _width).clamp(0.0, 1.0);
                    _seekTo(value, duration: duration);
                  },
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _dragFraction =
                          (details.localPosition.dx / _width).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragFraction =
                          (details.localPosition.dx / _width).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    final value = _dragFraction;
                    setState(() => _dragFraction = null);
                    if (value != null) _seekTo(value, duration: duration);
                  },
                  onHorizontalDragCancel: () {
                    setState(() => _dragFraction = null);
                  },
                  child: SizedBox(
                    height: 16,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: _width,
                            height: 2.5,
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          Container(
                            width: _width * fraction,
                            height: 2.5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
                            ),
                          ),
                          if (_dragFraction != null)
                            Positioned(
                              left: (_width * fraction) - 4,
                              top: -2.5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
