import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../icons/reel_icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'skeletons.dart';

/// Circular avatar with a deterministic gradient fallback.
///
/// Handles empty URLs, loading shimmer, live rings and verified badges.
class ReelAvatar extends StatelessWidget {
  const ReelAvatar({
    super.key,
    required this.url,
    this.size = 44,
    this.name,
    this.showLiveRing = false,
    this.showVerified = false,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
  });

  final String url;
  final double size;
  final String? name;
  final bool showLiveRing;
  final bool showVerified;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  static const _palettes = <List<Color>>[
    [Color(0xFFFE2C55), Color(0xFFFF7A45)],
    [Color(0xFF25F4EE), Color(0xFF0E7490)],
    [Color(0xFF7C3AED), Color(0xFFDB2777)],
    [Color(0xFF2563EB), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF059669)],
  ];

  List<Color> get _gradient {
    final seed = (name ?? url).codeUnits.fold<int>(0, (a, b) => a + b);
    return _palettes[seed % _palettes.length];
  }

  String get _initials {
    final source = (name ?? '').trim();
    if (source.isEmpty) return '?';
    final parts = source
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return source.substring(0, 1).toUpperCase();
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget core = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _image(),
      ),
    );

    if (showLiveRing) {
      core = Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorBrandCyan, colorBrand, colorBrandPink],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: colorBgBase,
          ),
          child: core,
        ),
      );
    } else if (borderWidth > 0) {
      core = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor ?? colorTextPrimary,
        ),
        child: core,
      );
    }

    if (showVerified) {
      core = Stack(
        clipBehavior: Clip.none,
        children: [
          core,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: colorBgBase,
              ),
              child: const ReelIcon(
                ReelGlyph.verified,
                size: 16,
                color: colorVerified,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return core;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: name == null ? 'Profil' : 'Profil de $name',
      child: core,
    );
  }

  Widget _image() {
    if (url.isEmpty) return _fallback();

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Shimmer(
        child: Container(
          color: backgroundColor ?? colorBgCard,
          alignment: Alignment.center,
          child: _initialsLabel(0.7),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient,
        ),
      ),
      child: Center(child: _initialsLabel(1)),
    );
  }

  Widget _initialsLabel(double opacity) {
    if (_initials == '?') {
      return ReelIcon(
        ReelGlyph.profile,
        size: size * 0.44,
        color: Colors.white.withValues(alpha: opacity),
      );
    }
    return Text(
      _initials,
      style: TextStyle(
        color: Colors.white.withValues(alpha: opacity),
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
