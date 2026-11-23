import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../icons/reel_icons.dart';
import '../theme/tokens.dart';
import 'skeletons.dart';

/// Video poster with optional view count and duration chips.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.url,
    this.views,
    this.duration,
    this.aspectRatio = 9 / 16,
    this.radius = radiusSm,
    this.showPlayIcon = true,
    this.fit = BoxFit.cover,
    this.seed,
  });

  final String url;
  final String? views;
  final String? duration;
  final double aspectRatio;
  final double radius;
  final bool showPlayIcon;
  final BoxFit fit;

  /// Stable key used to pick the fallback gradient when there is no poster.
  final String? seed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Poster(url: url, fit: fit, seed: seed ?? url),
            if (showPlayIcon) const _PlayOverlay(),
            if (views != null || duration != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(space6, space12, space6, space4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xB3000000), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      if (views != null) ...[
                        const ReelIcon(
                          ReelGlyph.play,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          views!,
                          style: AppTokens.caption.copyWith(color: Colors.white),
                        ),
                      ],
                      const Spacer(),
                      if (duration != null)
                        Text(
                          duration!,
                          style: AppTokens.caption.copyWith(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0x59000000),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: ReelIcon(
            ReelGlyph.play,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.fit, required this.seed});

  final String url;
  final BoxFit fit;
  final String seed;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _PosterFallback(seed: seed);

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Shimmer(child: _PosterFallback(seed: seed)),
      errorWidget: (_, __, ___) => _PosterFallback(seed: seed),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.seed});

  static const _palettes = <List<Color>>[
    [Color(0xFF3B1E4E), Color(0xFF16121F)],
    [Color(0xFF12324A), Color(0xFF0E1620)],
    [Color(0xFF4A1E28), Color(0xFF1B1014)],
    [Color(0xFF1E3A2C), Color(0xFF101A15)],
    [Color(0xFF3E3115), Color(0xFF1A1610)],
    [Color(0xFF232346), Color(0xFF12121E)],
  ];

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = _palettes[hash % _palettes.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Center(
        child: ReelIcon(ReelGlyph.play, size: 22, color: Color(0x55FFFFFF)),
      ),
    );
  }
}
