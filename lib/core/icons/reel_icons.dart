import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Glyphs used by the Reel UI.
///
/// They are drawn with vector paths on a 24×24 grid so they scale crisply at
/// any size and stay consistent with the rest of the interface.
enum ReelGlyph {
  heart,
  comment,
  bookmark,
  share,
  music,
  mic,
  home,
  friends,
  inbox,
  profile,
  plus,
  search,
  verified,
  play,
  pause,
  mute,
  volume,
  camera,
  effects,
  more,
  close,
  back,
  chevronRight,
  chevronDown,
  clock,
  trash,
  trend,
  send,
  emoji,
  grid,
  settings,
  link,
  check,
  warning,
  refresh,
  live,
}

/// A theme-aware icon rendered from a [ReelGlyph].
///
/// Use [filled] for the active/selected state (solid heart, solid home…).
class ReelIcon extends StatelessWidget {
  const ReelIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.strokeWidth,
    this.semanticLabel,
  });

  final ReelGlyph glyph;
  final double size;
  final Color? color;
  final bool filled;
  final double? strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.white;
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(
        glyph: glyph,
        filled: filled,
        color: resolved,
        strokeWidth: strokeWidth,
      ),
    );
    if (semanticLabel == null) return icon;
    return Semantics(label: semanticLabel, child: icon);
  }
}

/// The Reel wordmark: an original mark built from a rounded play shape with a
/// cyan/pink chromatic offset.
class ReelMark extends StatelessWidget {
  const ReelMark({super.key, this.size = 96, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: size * 0.86,
              height: size * 0.86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorBrand.withValues(alpha: 0.32),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.04,
                  ),
                ],
              ),
            ),
          CustomPaint(
            size: Size.square(size),
            painter: const _MarkPainter(),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.14, s * 0.72, s * 0.72),
      Radius.circular(s * 0.24),
    );

    // Chromatic offsets (cyan behind, pink in front, white core).
    for (final offset in const [
      Offset(-0.035, 0.02),
      Offset(0.035, -0.02),
    ]) {
      canvas.save();
      canvas.translate(offset.dx * s, offset.dy * s);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = offset.dx < 0 ? colorBrandCyan : colorBrandPink
          ..blendMode = BlendMode.plus,
      );
      canvas.restore();
    }

    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    final play = Path()
      ..moveTo(s * 0.43, s * 0.35)
      ..lineTo(s * 0.43, s * 0.65)
      ..quadraticBezierTo(s * 0.43, s * 0.69, s * 0.47, s * 0.67)
      ..lineTo(s * 0.69, s * 0.52)
      ..quadraticBezierTo(s * 0.72, s * 0.50, s * 0.69, s * 0.48)
      ..lineTo(s * 0.47, s * 0.33)
      ..quadraticBezierTo(s * 0.43, s * 0.31, s * 0.43, s * 0.35)
      ..close();
    canvas.drawPath(play, Paint()..color = const Color(0xFF0B0B0C));
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _GlyphSpec {
  const _GlyphSpec({
    required this.path,
    this.fill = false,
    this.stroke = 0,
    this.strokes = const [],
    this.cutouts = const [],
  });

  final Path path;
  final bool fill;
  final double stroke;
  final List<Path> strokes;
  final List<Path> cutouts;
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.glyph,
    required this.filled,
    required this.color,
    this.strokeWidth,
  });

  final ReelGlyph glyph;
  final bool filled;
  final Color color;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final spec = _specFor(glyph, filled);
    final stroke = strokeWidth ?? spec.stroke;

    final paint = Paint()
      ..isAntiAlias = true
      ..color = color;

    void drawMainPath() {
      if (spec.fill) {
        paint.style = PaintingStyle.fill;
        canvas.drawPath(spec.path, paint);
      }
      if (stroke > 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(spec.path, paint);
      }
    }

    if (spec.cutouts.isEmpty) {
      drawMainPath();
    } else {
      // Composite the glyph on its own layer so the cutouts can erase pixels.
      canvas.saveLayer(const Rect.fromLTWH(0, 0, 24, 24), Paint());
      drawMainPath();
      final clear = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;
      for (final cut in spec.cutouts) {
        canvas.drawPath(cut, clear);
      }
      canvas.restore();
    }

    for (final extra in spec.strokes) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke > 0 ? stroke : 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(extra, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.glyph != glyph ||
      old.filled != filled ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Path builders (24×24 grid)
// ─────────────────────────────────────────────────────────────────────────────

Path _heartPath() => Path()
  ..moveTo(12, 20.6)
  ..cubicTo(9.1, 18.2, 3.1, 13.8, 3.1, 8.9)
  ..cubicTo(3.1, 5.9, 5.3, 3.7, 8.1, 3.7)
  ..cubicTo(9.9, 3.7, 11.3, 4.7, 12, 6)
  ..cubicTo(12.7, 4.7, 14.1, 3.7, 15.9, 3.7)
  ..cubicTo(18.7, 3.7, 20.9, 5.9, 20.9, 8.9)
  ..cubicTo(20.9, 13.8, 14.9, 18.2, 12, 20.6)
  ..close();

Path _commentPath() => Path()
  ..moveTo(7.4, 3.2)
  ..lineTo(16.6, 3.2)
  ..quadraticBezierTo(21.2, 3.2, 21.2, 7.8)
  ..lineTo(21.2, 12.2)
  ..quadraticBezierTo(21.2, 16.8, 16.6, 16.8)
  ..lineTo(11.4, 16.8)
  ..lineTo(6.4, 21.1)
  ..lineTo(7.3, 16.8)
  ..quadraticBezierTo(2.8, 16.8, 2.8, 12.2)
  ..lineTo(2.8, 7.8)
  ..quadraticBezierTo(2.8, 3.2, 7.4, 3.2)
  ..close();

Path _bookmarkPath() => Path()
  ..moveTo(6.2, 3.4)
  ..lineTo(17.8, 3.4)
  ..quadraticBezierTo(19, 3.4, 19, 4.6)
  ..lineTo(19, 20.6)
  ..lineTo(12, 15.3)
  ..lineTo(5, 20.6)
  ..lineTo(5, 4.6)
  ..quadraticBezierTo(5, 3.4, 6.2, 3.4)
  ..close();

Path _shareShaft() => Path()
  ..moveTo(3.4, 19.2)
  ..cubicTo(3.9, 13.6, 8.4, 9.6, 14.6, 9.3)
  ..lineTo(20.4, 9.3);

Path _shareHead() => Path()
  ..moveTo(16.1, 4.8)
  ..lineTo(20.7, 9.3)
  ..lineTo(16.1, 13.8);

Path _musicPath() => Path()
  ..moveTo(10.1, 17)
  ..lineTo(10.1, 4.9)
  ..cubicTo(13.9, 5.5, 17.4, 7.4, 17.4, 11.1)
  ..cubicTo(15.3, 9.3, 12.5, 8.9, 10.1, 9.3);

Path _homePath() => Path()
  ..moveTo(4.1, 10.5)
  ..lineTo(11.1, 3.9)
  ..quadraticBezierTo(12, 3.1, 12.9, 3.9)
  ..lineTo(19.9, 10.5)
  ..lineTo(19.9, 19.6)
  ..quadraticBezierTo(19.9, 20.6, 18.9, 20.6)
  ..lineTo(5.1, 20.6)
  ..quadraticBezierTo(4.1, 20.6, 4.1, 19.6)
  ..close();

Path _homeDoor() => Path()
  ..moveTo(9.8, 20.6)
  ..lineTo(9.8, 15.6)
  ..quadraticBezierTo(9.8, 14.6, 10.8, 14.6)
  ..lineTo(13.2, 14.6)
  ..quadraticBezierTo(14.2, 14.6, 14.2, 15.6)
  ..lineTo(14.2, 20.6);

Path _friendsHead() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(9.1, 8.1), radius: 3.5));

Path _friendsBody() => Path()
  ..moveTo(2.6, 20.4)
  ..cubicTo(3.1, 15.7, 5.7, 13.3, 9.1, 13.3)
  ..cubicTo(12.5, 13.3, 15.1, 15.7, 15.6, 20.4);

Path _friendsHead2() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(17.3, 9.4), radius: 2.6));

Path _friendsBody2() => Path()
  ..moveTo(16.2, 14.6)
  ..cubicTo(19.4, 14.8, 21.2, 17, 21.4, 20.2);

Path _inboxPath() => Path()
  ..moveTo(5.4, 3.9)
  ..lineTo(18.6, 3.9)
  ..quadraticBezierTo(20.4, 3.9, 20.4, 5.7)
  ..lineTo(20.4, 18.3)
  ..quadraticBezierTo(20.4, 20.1, 18.6, 20.1)
  ..lineTo(5.4, 20.1)
  ..quadraticBezierTo(3.6, 20.1, 3.6, 18.3)
  ..lineTo(3.6, 5.7)
  ..quadraticBezierTo(3.6, 3.9, 5.4, 3.9)
  ..close();

Path _inboxTray() => Path()
  ..moveTo(3.6, 13.4)
  ..lineTo(8.2, 13.4)
  ..quadraticBezierTo(9.1, 13.4, 9.5, 14.2)
  ..quadraticBezierTo(10.3, 15.8, 12, 15.8)
  ..quadraticBezierTo(13.7, 15.8, 14.5, 14.2)
  ..quadraticBezierTo(14.9, 13.4, 15.8, 13.4)
  ..lineTo(20.4, 13.4);

/// Closed band following the tray curve, used to carve the notch out of the
/// filled inbox glyph.
Path _inboxTrayBand() => Path()
  ..moveTo(3.6, 12.1)
  ..lineTo(8.2, 12.1)
  ..quadraticBezierTo(9.1, 12.1, 9.5, 12.9)
  ..quadraticBezierTo(10.3, 14.5, 12, 14.5)
  ..quadraticBezierTo(13.7, 14.5, 14.5, 12.9)
  ..quadraticBezierTo(14.9, 12.1, 15.8, 12.1)
  ..lineTo(20.4, 12.1)
  ..lineTo(20.4, 13.6)
  ..lineTo(15.8, 13.6)
  ..quadraticBezierTo(14.9, 13.6, 14.5, 14.4)
  ..quadraticBezierTo(13.7, 16.0, 12, 16.0)
  ..quadraticBezierTo(10.3, 16.0, 9.5, 14.4)
  ..quadraticBezierTo(9.1, 13.6, 8.2, 13.6)
  ..lineTo(3.6, 13.6)
  ..close();

Path _micHead() => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(9, 2.4, 15, 13.2),
      const Radius.circular(3),
    ),
  );

Path _micArc() => Path()
  ..moveTo(5.8, 11.4)
  ..cubicTo(5.8, 15.6, 8.4, 17.8, 12, 17.8)
  ..cubicTo(15.6, 17.8, 18.2, 15.6, 18.2, 11.4);

Path _micStand() => Path()
  ..moveTo(12, 17.8)
  ..lineTo(12, 21.2);

Path _micBase() => Path()
  ..moveTo(9, 21.2)
  ..lineTo(15, 21.2);

Path _profileHead() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 7.5), radius: 3.9));

Path _profileBody() => Path()
  ..moveTo(3.4, 20.6)
  ..cubicTo(4, 15.4, 7.5, 12.7, 12, 12.7)
  ..cubicTo(16.5, 12.7, 20, 15.4, 20.6, 20.6);

Path _plusH() => Path()
  ..moveTo(5.4, 12)
  ..lineTo(18.6, 12);

Path _plusV() => Path()
  ..moveTo(12, 5.4)
  ..lineTo(12, 18.6);

Path _searchCircle() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(10.6, 10.6), radius: 6.6));

Path _searchHandle() => Path()
  ..moveTo(15.5, 15.5)
  ..lineTo(20.4, 20.4);

Path _verifiedPath() {
  const center = Offset(12, 12);
  const outer = 10.4;
  const inner = 9.0;
  const points = 12;
  final path = Path();
  for (var i = 0; i < points; i++) {
    final a0 = (i * 2 * math.pi / points) - math.pi / 2;
    final a1 = a0 + (2 * math.pi / points) / 2;
    final a2 = a0 + (2 * math.pi / points);
    final p0 = center + Offset(math.cos(a0), math.sin(a0)) * outer;
    final p1 = center + Offset(math.cos(a1), math.sin(a1)) * inner;
    final p2 = center + Offset(math.cos(a2), math.sin(a2)) * outer;
    if (i == 0) {
      path.moveTo(p0.dx, p0.dy);
    }
    path.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
  }
  return path..close();
}

Path _checkPath() => Path()
  ..moveTo(7.6, 12.3)
  ..lineTo(10.7, 15.3)
  ..lineTo(16.4, 8.9);

Path _playPath() => Path()
  ..moveTo(8.2, 5.2)
  ..lineTo(19, 11.4)
  ..quadraticBezierTo(19.6, 11.8, 19, 12.2)
  ..lineTo(8.2, 18.4)
  ..quadraticBezierTo(7.4, 18.9, 7.4, 17.9)
  ..lineTo(7.4, 5.7)
  ..quadraticBezierTo(7.4, 4.7, 8.2, 5.2)
  ..close();

Path _pauseBar(double x) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 5, 3.4, 14),
      const Radius.circular(1.6),
    ),
  );

Path _speakerPath() => Path()
  ..moveTo(4.2, 9.4)
  ..lineTo(7.4, 9.4)
  ..lineTo(12.4, 5.2)
  ..lineTo(12.4, 18.8)
  ..lineTo(7.4, 14.6)
  ..lineTo(4.2, 14.6)
  ..close();

Path _muteSlash() => Path()
  ..moveTo(4.4, 4.6)
  ..lineTo(19.4, 19.6);

Path _cameraPath() => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.2, 6.6, 17.6, 13),
      const Radius.circular(3.6),
    ),
  );

Path _cameraLens() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 13.1), radius: 3.1));

Path _effectsPath() => Path()
  ..moveTo(12, 2.8)
  ..quadraticBezierTo(13.2, 10.8, 21.2, 12)
  ..quadraticBezierTo(13.2, 13.2, 12, 21.2)
  ..quadraticBezierTo(10.8, 13.2, 2.8, 12)
  ..quadraticBezierTo(10.8, 10.8, 12, 2.8)
  ..close();

Path _moreDots() {
  final path = Path();
  for (final x in [5.4, 12.0, 18.6]) {
    path.addOval(Rect.fromCircle(center: Offset(x, 12), radius: 1.7));
  }
  return path;
}

Path _closePath() => Path()
  ..moveTo(6.2, 6.2)
  ..lineTo(17.8, 17.8)
  ..moveTo(17.8, 6.2)
  ..lineTo(6.2, 17.8);

Path _backPath() => Path()
  ..moveTo(15.2, 4.6)
  ..lineTo(7.4, 12)
  ..lineTo(15.2, 19.4);

Path _chevronRightPath() => Path()
  ..moveTo(9.2, 4.8)
  ..lineTo(16.4, 12)
  ..lineTo(9.2, 19.2);

Path _chevronDownPath() => Path()
  ..moveTo(5, 9)
  ..lineTo(12, 16)
  ..lineTo(19, 9);

Path _clockCircle() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.6));

Path _clockHands() => Path()
  ..moveTo(12, 7)
  ..lineTo(12, 12.2)
  ..lineTo(15.4, 14.2);

Path _trashPath() => Path()
  ..moveTo(4.4, 6.6)
  ..lineTo(19.6, 6.6)
  ..moveTo(9.2, 6.6)
  ..lineTo(9.2, 4.6)
  ..quadraticBezierTo(9.2, 3.8, 10, 3.8)
  ..lineTo(14, 3.8)
  ..quadraticBezierTo(14.8, 3.8, 14.8, 4.6)
  ..lineTo(14.8, 6.6)
  ..moveTo(6.2, 6.6)
  ..lineTo(7.2, 19.4)
  ..quadraticBezierTo(7.3, 20.4, 8.3, 20.4)
  ..lineTo(15.7, 20.4)
  ..quadraticBezierTo(16.7, 20.4, 16.8, 19.4)
  ..lineTo(17.8, 6.6);

Path _trendPath() => Path()
  ..moveTo(3.6, 17.4)
  ..lineTo(9.4, 11.6)
  ..lineTo(13.2, 15.4)
  ..lineTo(20.4, 8.2)
  ..moveTo(14.8, 8.2)
  ..lineTo(20.4, 8.2)
  ..lineTo(20.4, 13.8);

Path _sendPath() => Path()
  ..moveTo(3.4, 11.6)
  ..lineTo(20.2, 4.2)
  ..lineTo(13.6, 20.4)
  ..lineTo(11.2, 13.4)
  ..close();

Path _emojiFace() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.6));

Path _emojiSmile() => Path()
  ..moveTo(8.2, 13.6)
  ..quadraticBezierTo(12, 17.6, 15.8, 13.6);

Path _emojiEyes() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(9.2, 9.9), radius: 1.1))
  ..addOval(Rect.fromCircle(center: const Offset(14.8, 9.9), radius: 1.1));

Path _gridPath() {
  final path = Path();
  for (final dx in [0.0, 12.4]) {
    for (final dy in [0.0, 12.4]) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3.4 + dx, 3.4 + dy, 8.2, 8.2),
          const Radius.circular(2.2),
        ),
      );
    }
  }
  return path;
}

Path _settingsPath() => Path()
  ..moveTo(4, 7.2)
  ..lineTo(20, 7.2)
  ..moveTo(4, 16.8)
  ..lineTo(20, 16.8);

Path _settingsKnobs() {
  final path = Path();
  path.addOval(Rect.fromCircle(center: const Offset(9.4, 7.2), radius: 2.4));
  path.addOval(Rect.fromCircle(center: const Offset(15.2, 16.8), radius: 2.4));
  return path;
}

Path _linkPath() => Path()
  ..moveTo(9.6, 14.4)
  ..lineTo(14.4, 9.6)
  ..moveTo(8.4, 10.4)
  ..lineTo(6.6, 12.2)
  ..quadraticBezierTo(3.6, 15.2, 6.6, 18.2)
  ..quadraticBezierTo(9.6, 21.2, 12.6, 18.2)
  ..lineTo(14.4, 16.4)
  ..moveTo(15.6, 13.6)
  ..lineTo(17.4, 11.8)
  ..quadraticBezierTo(20.4, 8.8, 17.4, 5.8)
  ..quadraticBezierTo(14.4, 2.8, 11.4, 5.8)
  ..lineTo(9.6, 7.6);

Path _warningPath() => Path()
  ..moveTo(12, 3.6)
  ..lineTo(21.4, 19.6)
  ..lineTo(2.6, 19.6)
  ..close();

Path _refreshPath() => Path()
  ..moveTo(20.2, 12)
  ..cubicTo(20.2, 7.5, 16.5, 3.8, 12, 3.8)
  ..cubicTo(8.6, 3.8, 5.7, 5.9, 4.4, 8.9)
  ..moveTo(3.8, 12)
  ..cubicTo(3.8, 16.5, 7.5, 20.2, 12, 20.2)
  ..cubicTo(15.4, 20.2, 18.3, 18.1, 19.6, 15.1)
  ..moveTo(4.4, 4.4)
  ..lineTo(4.4, 9.2)
  ..lineTo(9.2, 9.2)
  ..moveTo(19.6, 19.6)
  ..lineTo(19.6, 14.8)
  ..lineTo(14.8, 14.8);

_GlyphSpec _specFor(ReelGlyph glyph, bool filled) {
  switch (glyph) {
    case ReelGlyph.heart:
      return _GlyphSpec(path: _heartPath(), fill: filled, stroke: 1.9);

    case ReelGlyph.comment:
      return _GlyphSpec(path: _commentPath(), fill: filled, stroke: 1.9);

    case ReelGlyph.bookmark:
      return _GlyphSpec(path: _bookmarkPath(), fill: filled, stroke: 1.9);

    case ReelGlyph.share:
      return _GlyphSpec(
        path: _shareShaft(),
        stroke: 2.1,
        strokes: [_shareHead()],
      );

    case ReelGlyph.music:
      return _GlyphSpec(
        path: _musicPath(),
        stroke: 2.2,
        strokes: [
          Path()
            ..addOval(
              Rect.fromCircle(center: const Offset(7.2, 17.1), radius: 3.1),
            ),
        ],
      );

    case ReelGlyph.home:
      return _GlyphSpec(
        path: _homePath(),
        fill: filled,
        stroke: 1.9,
        cutouts: filled ? [_homeDoor()] : const [],
      );

    case ReelGlyph.friends:
      return _GlyphSpec(
        path: _friendsHead(),
        fill: filled,
        stroke: 1.8,
        strokes: [_friendsBody(), _friendsHead2(), _friendsBody2()],
      );

    case ReelGlyph.inbox:
      return _GlyphSpec(
        path: _inboxPath(),
        fill: filled,
        stroke: 1.9,
        cutouts: filled ? [_inboxTrayBand()] : const [],
        strokes: filled ? const [] : [_inboxTray()],
      );

    case ReelGlyph.mic:
      return _GlyphSpec(
        path: _micHead(),
        fill: filled,
        stroke: 1.9,
        strokes: [_micArc(), _micStand(), _micBase()],
      );

    case ReelGlyph.profile:
      return _GlyphSpec(
        path: _profileHead(),
        fill: filled,
        stroke: 1.9,
        strokes: [_profileBody()],
      );

    case ReelGlyph.plus:
      return _GlyphSpec(
        path: _plusH(),
        stroke: 2.6,
        strokes: [_plusV()],
      );

    case ReelGlyph.search:
      return _GlyphSpec(
        path: _searchCircle(),
        stroke: 2.1,
        strokes: [_searchHandle()],
      );

    case ReelGlyph.verified:
      return _GlyphSpec(
        path: _verifiedPath(),
        fill: true,
        strokes: [_checkPath()],
        stroke: 1.9,
      );

    case ReelGlyph.play:
      return _GlyphSpec(path: _playPath(), fill: true);

    case ReelGlyph.pause:
      return _GlyphSpec(
        path: _pauseBar(7.4),
        fill: true,
        strokes: [_pauseBar(13.2)],
      );

    case ReelGlyph.mute:
      return _GlyphSpec(
        path: _speakerPath(),
        fill: true,
        strokes: [_muteSlash()],
        stroke: 2,
      );

    case ReelGlyph.volume:
      return _GlyphSpec(
        path: _speakerPath(),
        fill: true,
        strokes: [
          Path()
            ..moveTo(15.4, 9)
            ..quadraticBezierTo(17.2, 12, 15.4, 15),
          Path()
            ..moveTo(18.2, 6.6)
            ..quadraticBezierTo(21.4, 12, 18.2, 17.4),
        ],
        stroke: 1.9,
      );

    case ReelGlyph.camera:
      return _GlyphSpec(
        path: _cameraPath(),
        fill: filled,
        stroke: 1.9,
        cutouts: filled ? [_cameraLens()] : const [],
        strokes: filled ? const [] : [_cameraLens()],
      );

    case ReelGlyph.effects:
      return _GlyphSpec(path: _effectsPath(), fill: true);

    case ReelGlyph.more:
      return _GlyphSpec(path: _moreDots(), fill: true);

    case ReelGlyph.close:
      return _GlyphSpec(path: _closePath(), stroke: 2.1);

    case ReelGlyph.back:
      return _GlyphSpec(path: _backPath(), stroke: 2.2);

    case ReelGlyph.chevronRight:
      return _GlyphSpec(path: _chevronRightPath(), stroke: 2.1);

    case ReelGlyph.chevronDown:
      return _GlyphSpec(path: _chevronDownPath(), stroke: 2.1);

    case ReelGlyph.clock:
      return _GlyphSpec(
        path: _clockCircle(),
        stroke: 1.9,
        strokes: [_clockHands()],
      );

    case ReelGlyph.trash:
      return _GlyphSpec(path: _trashPath(), stroke: 1.9);

    case ReelGlyph.trend:
      return _GlyphSpec(path: _trendPath(), stroke: 2);

    case ReelGlyph.send:
      return _GlyphSpec(path: _sendPath(), fill: true, stroke: 1.6);

    case ReelGlyph.emoji:
      return _GlyphSpec(
        path: _emojiFace(),
        stroke: 1.8,
        strokes: [_emojiSmile(), _emojiEyes()],
      );

    case ReelGlyph.grid:
      return _GlyphSpec(path: _gridPath(), fill: filled, stroke: 1.7);

    case ReelGlyph.settings:
      return _GlyphSpec(
        path: _settingsPath(),
        stroke: 2,
        strokes: [_settingsKnobs()],
      );

    case ReelGlyph.link:
      return _GlyphSpec(path: _linkPath(), stroke: 2);

    case ReelGlyph.check:
      return _GlyphSpec(path: _checkPath(), stroke: 2.4);

    case ReelGlyph.warning:
      return _GlyphSpec(path: _warningPath(), stroke: 1.9);

    case ReelGlyph.refresh:
      return _GlyphSpec(path: _refreshPath(), stroke: 2);

    case ReelGlyph.live:
      return _GlyphSpec(
        path: Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(12, 12), radius: 4.2),
          ),
        fill: true,
        stroke: 2.6,
        strokes: [
          Path()
            ..addOval(
              Rect.fromCircle(center: const Offset(12, 12), radius: 9),
            ),
        ],
      );
  }
}
