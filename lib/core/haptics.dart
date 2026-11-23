import 'package:flutter/services.dart';

/// Centralised haptic feedback so every interaction feels the same.
///
/// All calls are fire-and-forget and silently ignored on platforms without a
/// haptic engine (desktop, web).
abstract final class Haptics {
  static bool enabled = true;

  static void tap() {
    if (!enabled) return;
    HapticFeedback.selectionClick().catchError((_) {});
  }

  static void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact().catchError((_) {});
  }

  static void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact().catchError((_) {});
  }

  static void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact().catchError((_) {});
  }
}
