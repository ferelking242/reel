import 'package:flutter/material.dart';

import 'reel_icons.dart';

/// Hand-drawn glyphs matching the geometry of the TikTok app icon set.
///
/// Every path is authored in a 24×24 box and either stroked (outline state) or
/// filled (active state). Glyphs without a hand-drawn path keep falling back to
/// Material Symbols so the rest of the app is untouched.
class TikGlyphSpec {
  const TikGlyphSpec(
    this.outline, {
    this.filled,
    this.strokeOnly = false,
    this.strokeScale = 1,
  });

  final Path Function() outline;

  /// Solid shape used for the active state. Defaults to [outline].
  final Path Function()? filled;

  /// Icons that never fill (search stays a magnifier, even when active).
  final bool strokeOnly;

  /// Multiplier on the default stroke width, for glyphs that look heavier.
  final double strokeScale;
}

const double _kStroke = 2.15;

/// Heart: wide, low, very round — the TikTok like button.
Path _heart() => Path()
  ..moveTo(12, 21.2)
  ..cubicTo(11.3, 21.2, 10.6, 20.9, 10.0, 20.4)
  ..cubicTo(6.2, 17.3, 2.5, 13.8, 2.5, 9.2)
  ..cubicTo(2.5, 5.8, 5.2, 3.2, 8.5, 3.2)
  ..cubicTo(10.3, 3.2, 11.5, 4.1, 12, 5.2)
  ..cubicTo(12.5, 4.1, 13.7, 3.2, 15.5, 3.2)
  ..cubicTo(18.8, 3.2, 21.5, 5.8, 21.5, 9.2)
  ..cubicTo(21.5, 13.8, 17.8, 17.3, 14.0, 20.4)
  ..cubicTo(13.4, 20.9, 12.7, 21.2, 12, 21.2)
  ..close();

/// Comment: wide speech bubble whose tail falls on the lower left.
Path _comment() => Path()
  ..moveTo(12, 3.3)
  ..cubicTo(6.7, 3.3, 2.9, 6.6, 2.9, 10.7)
  ..cubicTo(2.9, 12.9, 4.0, 14.9, 5.9, 16.2)
  ..cubicTo(5.7, 17.4, 5.0, 18.6, 4.0, 19.6)
  ..cubicTo(3.7, 19.9, 3.9, 20.5, 4.4, 20.5)
  ..cubicTo(6.6, 20.5, 8.3, 19.5, 9.3, 18.6)
  ..cubicTo(10.2, 18.8, 11.1, 18.9, 12, 18.9)
  ..cubicTo(17.3, 18.9, 21.1, 15.6, 21.1, 11.1)
  ..cubicTo(21.1, 6.6, 17.3, 3.3, 12, 3.3)
  ..close();

/// Save: ribbon with a notched bottom.
Path _bookmark() => Path()
  ..moveTo(6.6, 3.4)
  ..lineTo(17.4, 3.4)
  ..cubicTo(18.5, 3.4, 19.3, 4.2, 19.3, 5.3)
  ..lineTo(19.3, 20.3)
  ..cubicTo(19.3, 20.8, 18.7, 21.1, 18.3, 20.8)
  ..lineTo(12, 16.2)
  ..lineTo(5.7, 20.8)
  ..cubicTo(5.3, 21.1, 4.7, 20.8, 4.7, 20.3)
  ..lineTo(4.7, 5.3)
  ..cubicTo(4.7, 4.2, 5.5, 3.4, 6.6, 3.4)
  ..close();

/// Share: thick curved arrow pointing right.
Path _share() => Path()
  ..moveTo(13.1, 4.6)
  ..lineTo(21.3, 11.7)
  ..cubicTo(21.7, 12.0, 21.7, 12.5, 21.3, 12.8)
  ..lineTo(13.1, 19.9)
  ..lineTo(13.1, 15.4)
  ..cubicTo(9.4, 15.4, 6.6, 16.6, 4.4, 19.4)
  ..cubicTo(3.9, 20.0, 2.9, 19.6, 3.0, 18.8)
  ..cubicTo(3.7, 12.9, 7.4, 9.1, 13.1, 8.7)
  ..close();

/// Home: rounded roof and body, door cut out of the silhouette.
Path _home() => Path()
  ..moveTo(11.4, 3.0)
  ..cubicTo(11.8, 2.7, 12.2, 2.7, 12.6, 3.0)
  ..lineTo(21.0, 10.4)
  ..cubicTo(21.4, 10.7, 21.4, 11.3, 21.1, 11.7)
  ..lineTo(20.2, 12.8)
  ..cubicTo(19.9, 13.2, 19.3, 13.2, 18.9, 12.9)
  ..lineTo(18.6, 12.7)
  ..lineTo(18.6, 19.3)
  ..cubicTo(18.6, 19.9, 18.1, 20.4, 17.5, 20.4)
  ..lineTo(14.3, 20.4)
  ..lineTo(14.3, 14.9)
  ..cubicTo(14.3, 14.6, 14.1, 14.4, 13.8, 14.4)
  ..lineTo(10.2, 14.4)
  ..cubicTo(9.9, 14.4, 9.7, 14.6, 9.7, 14.9)
  ..lineTo(9.7, 20.4)
  ..lineTo(6.5, 20.4)
  ..cubicTo(5.9, 20.4, 5.4, 19.9, 5.4, 19.3)
  ..lineTo(5.4, 12.7)
  ..lineTo(5.1, 12.9)
  ..cubicTo(4.7, 13.2, 4.1, 13.2, 3.8, 12.8)
  ..lineTo(2.9, 11.7)
  ..cubicTo(2.6, 11.3, 2.6, 10.7, 3.0, 10.4)
  ..close();

/// Friends: two people, the front one complete, the back one hinted.
Path _friendsOutline() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(9.0, 8.0), radius: 3.5))
  ..moveTo(2.6, 20.3)
  ..cubicTo(2.6, 16.2, 5.5, 13.4, 9.0, 13.4)
  ..cubicTo(12.5, 13.4, 15.4, 16.2, 15.4, 20.3)
  ..moveTo(16.0, 5.4)
  ..cubicTo(17.9, 5.7, 19.3, 7.3, 19.3, 9.3)
  ..cubicTo(19.3, 10.9, 18.5, 12.3, 17.3, 13.1)
  ..moveTo(17.6, 14.0)
  ..cubicTo(19.7, 14.9, 21.4, 17.1, 21.4, 20.3);

Path _friendsFilled() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(9.0, 8.0), radius: 3.6))
  ..moveTo(9.0, 13.3)
  ..cubicTo(12.6, 13.3, 15.6, 16.1, 15.6, 20.4)
  ..lineTo(2.4, 20.4)
  ..cubicTo(2.4, 16.1, 5.4, 13.3, 9.0, 13.3)
  ..close()
  ..addOval(Rect.fromCircle(center: const Offset(16.6, 8.6), radius: 2.9))
  ..moveTo(16.6, 13.4)
  ..cubicTo(19.2, 13.4, 21.3, 15.5, 21.3, 18.6)
  ..lineTo(21.3, 20.4)
  ..lineTo(17.2, 20.4)
  ..cubicTo(17.2, 17.6, 16.2, 15.2, 14.6, 13.9)
  ..cubicTo(15.2, 13.6, 15.9, 13.4, 16.6, 13.4)
  ..close();

/// Inbox: rounded square with the tray notch, like the TikTok inbox tab.
Path _inbox() => Path()
  ..moveTo(6.2, 3.6)
  ..lineTo(17.8, 3.6)
  ..cubicTo(19.2, 3.6, 20.4, 4.8, 20.4, 6.2)
  ..lineTo(20.4, 17.8)
  ..cubicTo(20.4, 19.2, 19.2, 20.4, 17.8, 20.4)
  ..lineTo(14.0, 20.4)
  ..cubicTo(13.5, 20.4, 13.0, 20.1, 12.7, 19.7)
  ..lineTo(11.6, 17.9)
  ..cubicTo(11.3, 17.5, 10.7, 17.5, 10.4, 17.9)
  ..lineTo(9.3, 19.7)
  ..cubicTo(9.0, 20.1, 8.5, 20.4, 8.0, 20.4)
  ..lineTo(6.2, 20.4)
  ..cubicTo(4.8, 20.4, 3.6, 19.2, 3.6, 17.8)
  ..lineTo(3.6, 6.2)
  ..cubicTo(3.6, 4.8, 4.8, 3.6, 6.2, 3.6)
  ..close();

/// Profile: head and shoulders, opened at the bottom like the tab icon.
Path _profileOutline() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 8.1), radius: 3.8))
  ..moveTo(4.2, 20.4)
  ..cubicTo(4.2, 16.0, 7.7, 13.2, 12.0, 13.2)
  ..cubicTo(16.3, 13.2, 19.8, 16.0, 19.8, 20.4);

Path _profileFilled() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(12, 8.1), radius: 3.9))
  ..moveTo(12.0, 13.1)
  ..cubicTo(16.4, 13.1, 20.0, 16.0, 20.0, 20.4)
  ..lineTo(4.0, 20.4)
  ..cubicTo(4.0, 16.0, 7.6, 13.1, 12.0, 13.1)
  ..close();

/// Plus: two rounded bars.
Path _plus() {
  const bar = 2.6;
  const half = 12.0;
  const len = 8.6;
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(half - bar / 2, half - len, half + bar / 2, half + len),
        const Radius.circular(bar / 2),
      ),
    )
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(half - len, half - bar / 2, half + len, half + bar / 2),
        const Radius.circular(bar / 2),
      ),
    );
}

/// Play: soft triangle.
Path _play() => Path()
  ..moveTo(8.0, 4.6)
  ..cubicTo(8.0, 3.8, 8.9, 3.3, 9.6, 3.7)
  ..lineTo(20.0, 11.2)
  ..cubicTo(20.6, 11.6, 20.6, 12.4, 20.0, 12.8)
  ..lineTo(9.6, 20.3)
  ..cubicTo(8.9, 20.7, 8.0, 20.2, 8.0, 19.4)
  ..close();

/// Pause: two rounded bars.
Path _pause() {
  const bar = 4.4;
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(6.6, 3.6, 6.6 + bar, 20.4),
        const Radius.circular(1.6),
      ),
    )
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(13.0, 3.6, 13.0 + bar, 20.4),
        const Radius.circular(1.6),
      ),
    );
}

/// Search: magnifier.
Path _search() => Path()
  ..addOval(Rect.fromCircle(center: const Offset(10.6, 10.6), radius: 6.9))
  ..moveTo(15.7, 15.7)
  ..lineTo(20.9, 20.9);

/// Music: eighth note with a flag.
Path _music() => Path()
  ..moveTo(19.0, 3.4)
  ..cubicTo(19.0, 2.9, 18.5, 2.5, 18.0, 2.6)
  ..lineTo(10.0, 4.4)
  ..cubicTo(9.6, 4.5, 9.3, 4.8, 9.3, 5.2)
  ..lineTo(9.3, 15.4)
  ..cubicTo(8.5, 15.0, 7.5, 14.9, 6.6, 15.2)
  ..cubicTo(5.1, 15.6, 4.2, 16.9, 4.4, 18.2)
  ..cubicTo(4.6, 19.5, 5.9, 20.3, 7.4, 19.9)
  ..cubicTo(8.7, 19.6, 9.6, 18.6, 9.8, 17.4)
  ..lineTo(9.8, 8.6)
  ..lineTo(17.0, 7.0)
  ..lineTo(17.0, 13.9)
  ..cubicTo(16.2, 13.5, 15.2, 13.4, 14.3, 13.7)
  ..cubicTo(12.8, 14.1, 11.9, 15.4, 12.1, 16.7)
  ..cubicTo(12.3, 18.0, 13.6, 18.8, 15.1, 18.4)
  ..cubicTo(16.4, 18.1, 17.3, 17.1, 17.5, 15.9)
  ..lineTo(17.5, 6.6)
  ..lineTo(19.0, 6.3)
  ..close();

const Map<ReelGlyph, TikGlyphSpec> tikGlyphs = {
  ReelGlyph.heart: TikGlyphSpec(_heart, strokeScale: 1.05),
  ReelGlyph.comment: TikGlyphSpec(_comment),
  ReelGlyph.bookmark: TikGlyphSpec(_bookmark),
  ReelGlyph.share: TikGlyphSpec(_share, strokeScale: 0.95),
  ReelGlyph.home: TikGlyphSpec(_home),
  ReelGlyph.friends: TikGlyphSpec(_friendsOutline, filled: _friendsFilled),
  ReelGlyph.inbox: TikGlyphSpec(_inbox),
  ReelGlyph.profile: TikGlyphSpec(_profileOutline, filled: _profileFilled),
  ReelGlyph.plus: TikGlyphSpec(_plus, strokeScale: 1.15),
  ReelGlyph.play: TikGlyphSpec(_play),
  ReelGlyph.pause: TikGlyphSpec(_pause),
  ReelGlyph.search: TikGlyphSpec(_search, strokeOnly: true),
  ReelGlyph.music: TikGlyphSpec(_music),
};

/// Paints one of the hand-drawn glyphs.
class TikIconPainter extends CustomPainter {
  const TikIconPainter({
    required this.glyph,
    required this.color,
    required this.filled,
    this.weight = 1,
  });

  final ReelGlyph glyph;
  final Color color;
  final bool filled;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = tikGlyphs[glyph];
    if (spec == null) return;
    final scale = size.shortestSide / 24.0;
    final solid = filled && !spec.strokeOnly;
    final path = (solid ? (spec.filled ?? spec.outline) : spec.outline)();

    canvas.save();
    canvas.scale(scale, scale);
    if (solid) {
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _kStroke * spec.strokeScale * weight
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TikIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.filled != filled ||
      old.weight != weight;
}
