import 'package:flutter/material.dart';

/// Design tokens for the Reel UI.
///
/// Colours, type scale, spacing, radii and motion are defined once here so
/// every screen shares the same visual rhythm.
abstract class AppTokens {
  // ─── Typography ──────────────────────────────────────────────────────────
  /// TikTok Sans (OFL 1.1) — bundled in `assets/fonts`.
  static const String fontFamily = 'TikTokSans';

  // ─── Brand ───────────────────────────────────────────────────────────────
  static const colorBrand = Color(0xFFFE2C55);
  static const colorBrandCyan = Color(0xFF25F4EE);
  static const colorBrandPink = Color(0xFFFF3B5C);
  static const colorBrandDeep = Color(0xFFE11D48);

  // ─── Dark backgrounds ────────────────────────────────────────────────────
  static const colorBgBase = Color(0xFF000000);
  static const colorBgSurface = Color(0xFF121212);
  static const colorBgCard = Color(0xFF1C1C1E);
  static const colorBgElevated = Color(0xFF242426);
  static const colorBgOverlay = Color(0x73000000);

  // ─── Light backgrounds ───────────────────────────────────────────────────
  static const colorBgLight = Color(0xFFFFFFFF);
  static const colorBgLightSurface = Color(0xFFF1F1F2);
  static const colorBgLightCard = Color(0xFFE9E9EB);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const colorTextPrimary = Color(0xFFFFFFFF);
  static const colorTextPrimaryDark = Color(0xFF161823);
  static const colorTextSecondary = Color(0xCCFFFFFF);
  static const colorTextTertiary = Color(0x99FFFFFF);
  static const colorTextSecondaryDark = Color(0xFF8A8B91);
  static const colorTextBrand = Color(0xFFFE2C55);

  // ─── States ──────────────────────────────────────────────────────────────
  static const colorLike = Color(0xFFFE2C55);
  static const colorLiveRed = Color(0xFFFE2C55);
  static const colorVerified = Color(0xFF20D5EC);
  static const colorFollowBtn = Color(0xFFFE2C55);
  static const colorSuccess = Color(0xFF2ECC71);
  static const colorWarning = Color(0xFFFFB020);
  static const colorDivider = Color(0x1FFFFFFF);
  static const colorDividerLight = Color(0xFFE8E8EA);
  static const colorScrimTop = Color(0x8A000000);
  static const colorScrimBottom = Color(0xD9000000);

  // ─── Spacing ─────────────────────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space56 = 56;
  static const double space64 = 64;

  /// Horizontal page gutter used by every non-immersive screen.
  static const double gutter = 16;

  // ─── Radii ───────────────────────────────────────────────────────────────
  static const double radiusNone = 0;
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusXxl = 20;
  static const double radiusPill = 999;

  // ─── Icon sizes ──────────────────────────────────────────────────────────
  static const double iconSidebar = 30;
  static const double iconNav = 24;
  static const double iconHeader = 24;
  static const double iconInline = 20;
  static const double iconSmall = 16;

  // ─── Layout ──────────────────────────────────────────────────────────────
  static const double sidebarWidth = 72;
  static const double bottomNavHeight = 52;
  static const double feedOverlayBottomInset = 74;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;
  static const double gridGap = 2;

  // ─── Type scale ──────────────────────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static const TextStyle titleL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );
  static const TextStyle titleM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle titleS = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle bodyM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle bodyS = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle labelM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle labelS = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Text shadow used on top of video to keep copy readable.
  static const List<Shadow> feedTextShadow = [
    Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 1)),
  ];

  // ─── Elevation ───────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

// ── Top-level convenience aliases ─────────────────────────────────────────────
const colorBrand = AppTokens.colorBrand;
const colorBrandCyan = AppTokens.colorBrandCyan;
const colorBrandPink = AppTokens.colorBrandPink;
const colorBrandDeep = AppTokens.colorBrandDeep;
const colorBgBase = AppTokens.colorBgBase;
const colorBgSurface = AppTokens.colorBgSurface;
const colorBgCard = AppTokens.colorBgCard;
const colorBgElevated = AppTokens.colorBgElevated;
const colorBgOverlay = AppTokens.colorBgOverlay;
const colorBgLight = AppTokens.colorBgLight;
const colorBgLightSurface = AppTokens.colorBgLightSurface;
const colorBgLightCard = AppTokens.colorBgLightCard;
const colorTextPrimary = AppTokens.colorTextPrimary;
const colorTextPrimaryDark = AppTokens.colorTextPrimaryDark;
const colorTextSecondary = AppTokens.colorTextSecondary;
const colorTextTertiary = AppTokens.colorTextTertiary;
const colorTextSecondaryDark = AppTokens.colorTextSecondaryDark;
const colorTextBrand = AppTokens.colorTextBrand;
const colorLike = AppTokens.colorLike;
const colorLiveRed = AppTokens.colorLiveRed;
const colorVerified = AppTokens.colorVerified;
const colorFollowBtn = AppTokens.colorFollowBtn;
const colorSuccess = AppTokens.colorSuccess;
const colorWarning = AppTokens.colorWarning;
const colorDivider = AppTokens.colorDivider;
const colorDividerLight = AppTokens.colorDividerLight;
const colorScrimTop = AppTokens.colorScrimTop;
const colorScrimBottom = AppTokens.colorScrimBottom;
const double space2 = AppTokens.space2;
const double space4 = AppTokens.space4;
const double space6 = AppTokens.space6;
const double space8 = AppTokens.space8;
const double space10 = AppTokens.space10;
const double space12 = AppTokens.space12;
const double space16 = AppTokens.space16;
const double space20 = AppTokens.space20;
const double space24 = AppTokens.space24;
const double space32 = AppTokens.space32;
const double space40 = AppTokens.space40;
const double space48 = AppTokens.space48;
const double space56 = AppTokens.space56;
const double space64 = AppTokens.space64;
const double gutter = AppTokens.gutter;
const double radiusNone = AppTokens.radiusNone;
const double radiusXs = AppTokens.radiusXs;
const double radiusSm = AppTokens.radiusSm;
const double radiusMd = AppTokens.radiusMd;
const double radiusLg = AppTokens.radiusLg;
const double radiusXl = AppTokens.radiusXl;
const double radiusXxl = AppTokens.radiusXxl;
const double radiusPill = AppTokens.radiusPill;
const double iconSidebar = AppTokens.iconSidebar;
const double iconNav = AppTokens.iconNav;
const double iconHeader = AppTokens.iconHeader;
const double iconInline = AppTokens.iconInline;
const double iconSmall = AppTokens.iconSmall;

// ── Motion ────────────────────────────────────────────────────────────────────
const durationFast = Duration(milliseconds: 120);
const durationNormal = Duration(milliseconds: 220);
const durationSlow = Duration(milliseconds: 320);
const durationLike = Duration(milliseconds: 420);
const durationPulse = Duration(milliseconds: 900);
const durationSheet = Duration(milliseconds: 300);

/// Standard easing curves used across the app.
abstract final class ReelCurves {
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const decelerate = Curves.easeOutCubic;
  static const accelerate = Curves.easeInCubic;
  static const spring = Curves.easeOutBack;
}
