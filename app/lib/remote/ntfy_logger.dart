import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:watchtower_real/remote/ntfy_config.dart';

/// Envoie des messages de log push vers ntfy.sh pour surveiller l'app en live.
/// Topic configuré dans [NtfyConfig.topic] → https://ntfy.sh/watchtower-real
class NtfyLogger {
  static String get _topic => NtfyConfig.topic;
  static String get _appName => NtfyConfig.appName;

  /// Message debug/info (priorité basse).
  static void info(String msg, {String? title}) =>
      _send(msg, title: title ?? '📱 $_appName', priority: 'low', tags: 'information_source');

  /// Avertissement (fallback réseau, etc.).
  static void warn(String msg, {String? title}) =>
      _send(msg, title: title ?? '⚠️ $_appName', priority: 'default', tags: 'warning');

  /// Erreur critique (priorité haute).
  static void error(String msg, {String? title}) =>
      _send(msg, title: title ?? '🔴 $_appName Error', priority: 'high', tags: 'rotating_light');

  /// Succès.
  static void ok(String msg, {String? title}) =>
      _send(msg, title: title ?? '✅ $_appName', priority: 'low', tags: 'white_check_mark');

  static void _send(String body, {
    required String title,
    required String priority,
    required String tags,
  }) {
    // Fire and forget — ne bloque jamais l'UI
    unawaited(
      http.post(
        Uri.parse(_topic),
        headers: {
          'Title': title,
          'Priority': priority,
          'Tags': tags,
        },
        body: body,
      ).timeout(const Duration(seconds: 5)),
    );
  }
}

void unawaited(Future<dynamic> f) => f.catchError((_) {});
