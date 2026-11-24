import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/tokens.dart';

/// Glyphs used by the Reel UI.
///
/// Each one maps to a Material Symbols rounded glyph. The family is a variable
/// font, so [ReelIcon] can ask for the filled variant and a heavier weight
/// without shipping a second icon font.
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
  chevronLeft,
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
  lock,
  notifications,
  language,
  help,
  info,
  logout,
  personAdd,
  hashtag,
  download,
  edit,
  eye,
  shield,
  palette,
  storage,
  star,
  filter,
  qr,
  at,
  videoLibrary,
  flag,
  block,
  arrowUpRight,
  darkMode,
  cloud,
  key,
}

const Map<ReelGlyph, IconData> _glyphData = {
  ReelGlyph.heart: Symbols.favorite_rounded,
  ReelGlyph.comment: Symbols.chat_bubble_rounded,
  ReelGlyph.bookmark: Symbols.bookmark_rounded,
  ReelGlyph.share: Symbols.forward_rounded,
  ReelGlyph.music: Symbols.music_note_rounded,
  ReelGlyph.mic: Symbols.mic_rounded,
  ReelGlyph.home: Symbols.home_rounded,
  ReelGlyph.friends: Symbols.group_rounded,
  ReelGlyph.inbox: Symbols.notifications_rounded,
  ReelGlyph.profile: Symbols.person_rounded,
  ReelGlyph.plus: Symbols.add_rounded,
  ReelGlyph.search: Symbols.search_rounded,
  ReelGlyph.verified: Symbols.verified_rounded,
  ReelGlyph.play: Symbols.play_arrow_rounded,
  ReelGlyph.pause: Symbols.pause_rounded,
  ReelGlyph.mute: Symbols.volume_off_rounded,
  ReelGlyph.volume: Symbols.volume_up_rounded,
  ReelGlyph.camera: Symbols.videocam_rounded,
  ReelGlyph.effects: Symbols.auto_awesome_rounded,
  ReelGlyph.more: Symbols.more_horiz_rounded,
  ReelGlyph.close: Symbols.close_rounded,
  ReelGlyph.back: Symbols.arrow_back_ios_new_rounded,
  ReelGlyph.chevronRight: Symbols.chevron_right_rounded,
  ReelGlyph.chevronLeft: Symbols.chevron_left_rounded,
  ReelGlyph.chevronDown: Symbols.keyboard_arrow_down_rounded,
  ReelGlyph.clock: Symbols.schedule_rounded,
  ReelGlyph.trash: Symbols.delete_rounded,
  ReelGlyph.trend: Symbols.trending_up_rounded,
  ReelGlyph.send: Symbols.send_rounded,
  ReelGlyph.emoji: Symbols.emoji_emotions_rounded,
  ReelGlyph.grid: Symbols.grid_view_rounded,
  ReelGlyph.settings: Symbols.settings_rounded,
  ReelGlyph.link: Symbols.link_rounded,
  ReelGlyph.check: Symbols.check_rounded,
  ReelGlyph.warning: Symbols.error_rounded,
  ReelGlyph.refresh: Symbols.refresh_rounded,
  ReelGlyph.live: Symbols.sensors_rounded,
  ReelGlyph.lock: Symbols.lock_rounded,
  ReelGlyph.notifications: Symbols.notifications_rounded,
  ReelGlyph.language: Symbols.translate_rounded,
  ReelGlyph.help: Symbols.help_rounded,
  ReelGlyph.info: Symbols.info_rounded,
  ReelGlyph.logout: Symbols.logout_rounded,
  ReelGlyph.personAdd: Symbols.person_add_rounded,
  ReelGlyph.hashtag: Symbols.tag_rounded,
  ReelGlyph.download: Symbols.download_rounded,
  ReelGlyph.edit: Symbols.edit_rounded,
  ReelGlyph.eye: Symbols.visibility_rounded,
  ReelGlyph.shield: Symbols.shield_rounded,
  ReelGlyph.palette: Symbols.palette_rounded,
  ReelGlyph.storage: Symbols.storage_rounded,
  ReelGlyph.star: Symbols.star_rounded,
  ReelGlyph.filter: Symbols.tune_rounded,
  ReelGlyph.qr: Symbols.qr_code_rounded,
  ReelGlyph.at: Symbols.alternate_email_rounded,
  ReelGlyph.videoLibrary: Symbols.video_library_rounded,
  ReelGlyph.flag: Symbols.flag_rounded,
  ReelGlyph.block: Symbols.block_rounded,
  ReelGlyph.arrowUpRight: Symbols.arrow_outward_rounded,
  ReelGlyph.darkMode: Symbols.dark_mode_rounded,
  ReelGlyph.cloud: Symbols.cloud_rounded,
  ReelGlyph.key: Symbols.key_rounded,
};

/// A theme-aware icon rendered from a [ReelGlyph].
///
/// Use [filled] for the active/selected state (solid heart, solid home…).
/// [strokeWidth] maps to the variable font weight, so 2 is regular and 3 is a
/// noticeably bolder glyph.
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
    final icon = Icon(
      _glyphData[glyph],
      size: size,
      color: resolved,
      fill: filled ? 1 : 0,
      weight: strokeWidth == null
          ? (filled ? 500 : 400)
          : (300 + strokeWidth! * 100).clamp(300, 700),
      grade: 0,
      opticalSize: size.clamp(20, 48),
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
