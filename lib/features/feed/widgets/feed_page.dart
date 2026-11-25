import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/haptics.dart';
import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/reel_sheet.dart';
import '../models/feed_item.dart';
import '../providers/engagement_provider.dart';
import 'feed_overlay_bottom.dart';
import 'feed_progress_bar.dart';
import 'feed_sidebar.dart';
import 'like_burst.dart';

/// One full-screen page of the vertical feed.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({
    super.key,
    required this.item,
    required this.isActive,
    required this.onOpenComments,
    required this.onOpenShare,
    this.player,
    this.muted = true,
  });

  final FeedItem item;
  final bool isActive;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenShare;
  final Player? player;
  final bool muted;

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  VideoController? _controller;
  StreamSubscription<bool>? _completedSub;

  bool _pausedByUser = false;
  bool _holdPaused = false;

  Offset? _burstPosition;
  int _burstId = 0;

  Player? get _player => widget.player;

  @override
  void initState() {
    super.initState();
    final player = _player;
    if (player != null) {
      _controller = VideoController(player);
      _applyVolume();
      _completedSub = player.stream.completed.listen((completed) {
        if (completed && widget.isActive) {
          player.seek(Duration.zero);
          player.play();
        }
      });
    }
    if (widget.isActive) _startPlayback();
  }

  @override
  void didUpdateWidget(covariant FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) _applyVolume();
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _startPlayback();
      } else {
        _pausePlayback(reset: true);
      }
    }
    if (oldWidget.player != widget.player) {
      _controller = widget.player == null
          ? null
          : VideoController(widget.player!);
    }
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    super.dispose();
  }

  void _applyVolume() {
    _player?.setVolume(widget.muted ? 0 : 100);
  }

  void _startPlayback() {
    _applyVolume();
    _player?.play();
  }

  void _pausePlayback({bool reset = false}) {
    final player = _player;
    if (player == null) return;
    player.pause();
    if (reset) player.seek(Duration.zero);
    _pausedByUser = false;
    _holdPaused = false;
  }

  void _togglePlayback() {
    final player = _player;
    if (player == null) {
      showReelToast(
        context,
        'Aucune vidéo chargée pour ce post',
        icon: ReelGlyph.effects,
      );
      return;
    }
    Haptics.light();
    if (player.state.playing) {
      player.pause();
      setState(() => _pausedByUser = true);
    } else {
      player.play();
      setState(() => _pausedByUser = false);
    }
  }

  void _likeFromDoubleTap(Offset position) {
    final engagement = ref.read(engagementProvider);
    if (!engagement.isLiked(widget.item.id)) {
      ref.read(engagementProvider.notifier).toggleLike(widget.item.id);
    }
    Haptics.medium();
    setState(() {
      _burstPosition = position;
      _burstId++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      onDoubleTapDown: (details) =>
          _burstPosition = details.localPosition,
      onDoubleTap: () {
        final position = _burstPosition ??
            Offset(
              MediaQuery.sizeOf(context).width / 2,
              MediaQuery.sizeOf(context).height / 2,
            );
        _likeFromDoubleTap(position);
      },
      onLongPressStart: (_) {
        if (_player == null) return;
        _player!.pause();
        setState(() => _holdPaused = true);
        Haptics.medium();
      },
      onLongPressEnd: (_) {
        if (_player == null) return;
        if (!_pausedByUser) _player!.play();
        setState(() => _holdPaused = false);
      },
      onLongPressCancel: () {
        if (_player == null) return;
        if (!_pausedByUser) _player!.play();
        setState(() => _holdPaused = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FeedBackground(
            item: item,
            player: _player,
            controller: _controller,
          ),
          const _Scrims(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !widget.isActive,
              child: AnimatedOpacity(
                opacity: widget.isActive ? 1 : 0,
                duration: durationNormal,
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: widget.isActive
                      ? Offset.zero
                      : const Offset(0, 0.10),
                  duration: durationSlow,
                  curve: ReelCurves.decelerate,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppTokens.feedOverlayBottomInset +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: space16,
                              right: space12,
                            ),
                            child: FeedOverlayBottom(item: item),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            right: space8,
                            bottom: space8,
                          ),
                          child: FeedSidebar(
                            item: item,
                            isActive: widget.isActive,
                            onOpenComments: widget.onOpenComments,
                            onOpenShare: widget.onOpenShare,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_player != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: widget.isActive ? 1 : 0,
                duration: durationNormal,
                child: FeedProgressBar(player: _player!),
              ),
            ),
          PauseOverlay(visible: _pausedByUser || _holdPaused),
          if (_burstPosition != null)
            LikeBurst(
              key: ValueKey(_burstId),
              position: _burstPosition!,
              onDone: () {
                if (mounted) setState(() => _burstPosition = null);
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background: video over poster
// ─────────────────────────────────────────────────────────────────────────────

class _FeedBackground extends StatelessWidget {
  const _FeedBackground({
    required this.item,
    required this.player,
    required this.controller,
  });

  final FeedItem item;
  final Player? player;
  final VideoController? controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.thumbnailUrl.isEmpty)
          _GradientPoster(seed: item.id)
        else
          CachedNetworkImage(
            imageUrl: item.thumbnailUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => _GradientPoster(seed: item.id),
            errorWidget: (_, __, ___) => _GradientPoster(seed: item.id),
          ),
        if (controller != null && player != null)
          _VideoLayer(
            key: ValueKey(item.id),
            player: player!,
            controller: controller!,
            poster: item.thumbnailUrl.isEmpty
                ? _GradientPoster(seed: item.id)
                : null,
          ),
      ],
    );
  }
}

class _VideoLayer extends StatefulWidget {
  const _VideoLayer({
    super.key,
    required this.player,
    required this.controller,
    required this.poster,
  });

  final Player player;
  final VideoController controller;
  final Widget? poster;

  @override
  State<_VideoLayer> createState() => _VideoLayerState();
}

class _VideoLayerState extends State<_VideoLayer> {
  /// The poster stays up until the decoder actually produced a frame: no
  /// spinner, exactly like the reference app.
  bool _hasFrame = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _watch(widget.player);
  }

  @override
  void didUpdateWidget(covariant _VideoLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) _watch(widget.player);
  }

  void _watch(Player player) {
    _positionSub?.cancel();
    _playingSub?.cancel();
    _hasFrame = player.state.position > Duration.zero;
    _positionSub = player.stream.position.listen((position) {
      if (!_hasFrame && position > Duration.zero) {
        setState(() => _hasFrame = true);
      }
    });
    _playingSub = player.stream.playing.listen((playing) {
      if (!_hasFrame && playing) {
        // Audio can start a hair before the first frame; reveal on the next
        // tick instead of flashing a black rectangle.
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_hasFrame) setState(() => _hasFrame = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: _hasFrame ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Video(
            controller: widget.controller,
            controls: NoVideoControls,
            fit: BoxFit.cover,
            fill: Colors.transparent,
          ),
        ),
        if (widget.poster != null)
          AnimatedOpacity(
            opacity: _hasFrame ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: IgnorePointer(child: widget.poster),
          ),
      ],
    );
  }
}

/// Generated poster shown while a thumbnail loads or is missing.
class _GradientPoster extends StatelessWidget {
  const _GradientPoster({required this.seed});

  final String seed;

  static const _palettes = <List<Color>>[
    [Color(0xFF2B1055), Color(0xFF7597DE)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF42275A), Color(0xFF734B6D)],
    [Color(0xFF1F1C2C), Color(0xFF928DAB)],
    [Color(0xFF3A1C71), Color(0xFFD76D77)],
    [Color(0xFF232526), Color(0xFF414345)],
  ];

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(7, (a, b) => a * 31 + b).abs();
    final colors = _palettes[hash % _palettes.length];
    final glyph = hash.isEven ? ReelGlyph.play : ReelGlyph.music;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _BlurredBlob(color: colors.last, size: 220),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _BlurredBlob(color: colors.first, size: 200),
          ),
          Center(
            child: Opacity(
              opacity: 0.14,
              child: ReelIcon(glyph, size: 160, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  const _BlurredBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
    );
  }
}

class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000)],
              ),
            ),
            child: SizedBox(height: 130, width: double.infinity),
          ),
          Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xD9000000), Color(0x00000000)],
              ),
            ),
            child: SizedBox(height: 260, width: double.infinity),
          ),
        ],
      ),
    );
  }
}
