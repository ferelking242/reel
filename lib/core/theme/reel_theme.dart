import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Material themes built from [AppTokens].
///
/// The app is dark-first (immersive video feed) with a light theme used by the
/// search, profile and settings surfaces.
abstract final class ReelTheme {
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? colorBgSurface : colorBgLight;
    final surface = isDark ? colorBgCard : colorBgLight;
    final onSurface = isDark ? colorTextPrimary : colorTextPrimaryDark;
    final secondary = isDark ? colorTextSecondary : colorTextSecondaryDark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colorBrand,
      onPrimary: Colors.white,
      secondary: colorBrandCyan,
      onSecondary: const Color(0xFF00201F),
      error: const Color(0xFFFF4D4F),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? colorBgElevated : colorBgLightSurface,
      outline: isDark ? colorDivider : colorDividerLight,
      outlineVariant: isDark ? const Color(0x14FFFFFF) : const Color(0xFFEDEDF0),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTokens.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: AppTokens.display.copyWith(color: onSurface),
      headlineSmall: AppTokens.titleL.copyWith(color: onSurface),
      titleLarge: AppTokens.titleL.copyWith(color: onSurface),
      titleMedium: AppTokens.titleM.copyWith(color: onSurface),
      titleSmall: AppTokens.titleS.copyWith(color: onSurface),
      bodyLarge: AppTokens.bodyM.copyWith(color: onSurface),
      bodyMedium: AppTokens.bodyS.copyWith(color: onSurface),
      bodySmall: AppTokens.bodyS.copyWith(color: secondary),
      labelLarge: AppTokens.labelM.copyWith(color: onSurface),
      labelMedium: AppTokens.labelS.copyWith(color: secondary),
      labelSmall: AppTokens.caption.copyWith(color: secondary),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface, size: iconHeader),
        titleTextStyle: AppTokens.titleM.copyWith(color: onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: secondary,
        indicatorColor: onSurface,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: AppTokens.titleS,
        unselectedLabelStyle: AppTokens.bodyS,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? colorDivider : colorDividerLight,
        thickness: 0.5,
        space: 0.5,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: const Color(0x99000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A2A2C) : const Color(0xFF232325),
        contentTextStyle: AppTokens.bodyS.copyWith(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark ? colorBgElevated : colorBgLightSurface,
        hintStyle: AppTokens.bodyS.copyWith(color: secondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(
            color: isDark ? colorDivider : colorDividerLight,
            width: 1,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: colorBrand,
        linearTrackColor: Colors.white24,
        circularTrackColor: Colors.white24,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
