import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:watchtower_real/app.dart';
import 'package:watchtower_real/utils/log/app_file_logger.dart';
import 'package:watchtower_real/remote/app_version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. File logger (must come first) ────────────────────────────────────────
  await AppFileLogger.instance.init();
  logger.log('MAIN', 'App starting…');

  // ── 2. App version (fetched once, used in all HTTP requests) ────────────────
  await AppVersion.init();
  logger.log('MAIN', 'App version: ${AppVersion.version} (${AppVersion.buildNumber})');

  // ── 3. Hive ──────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  logger.log('MAIN', 'Hive initialised');

  // ── 4. Global Flutter error hook ─────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error('FLUTTER', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  // ── 5. Uncaught async errors ─────────────────────────────────────────────────
  PlatformDispatcher.instance.onError = (error, st) {
    logger.error('PLATFORM', error, st);
    return false; // let it propagate
  };

  logger.log('MAIN', 'Launching ProviderScope…');
  runZonedGuarded(
    () => runApp(const ProviderScope(child: WatchtowerRealApp())),
    (error, st) => logger.error('ZONE', error, st),
  );
}
