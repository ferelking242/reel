import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/host/reel_host.dart';
import 'core/theme/reel_theme.dart';
import 'core/theme/tokens.dart';
import 'router/router.dart' as app_router;

class ReelApp extends StatelessWidget {
  const ReelApp({super.key, this.routerConfig});

  /// Injected by a host so Reel does not share the standalone navigation state.
  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Reel',
      debugShowCheckedModeBanner: false,
      theme: ReelTheme.light(),
      darkTheme: ReelTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: routerConfig ?? app_router.router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Keep the design intact on devices with very large text settings.
        final media = MediaQuery.of(context);
        final scale = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Used by the integration tests and the screenshot harness.
Widget buildTestApp({Widget? home}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ReelTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: home ?? const Scaffold(backgroundColor: colorBgBase),
    ),
  );
}

/// Reel mounted inside another app (Watchtower).
///
/// The host supplies the extension, its layout contract and a local transport;
/// Reel keeps its own providers, so nothing leaks into the host scope.
class ReelHostedApp extends StatelessWidget {
  const ReelHostedApp({super.key, required this.host});

  final ReelHost host;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [reelHostProvider.overrideWithValue(host)],
      child: ReelApp(
        routerConfig: app_router.createReelRouter(initialLocation: '/'),
      ),
    );
  }
}
