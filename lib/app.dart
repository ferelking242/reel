import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/reel_theme.dart';
import 'core/theme/tokens.dart';
import 'router/router.dart';

class ReelApp extends StatelessWidget {
  const ReelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Reel',
      debugShowCheckedModeBanner: false,
      theme: ReelTheme.light(),
      darkTheme: ReelTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
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
