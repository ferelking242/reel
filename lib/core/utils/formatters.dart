import 'package:flutter/material.dart';

/// Formats a counter the way social feeds do: 1 240 → « 1,2 K ».
String formatCount(int value) {
  final n = value.abs();
  final sign = value < 0 ? '-' : '';
  if (n < 1000) return '$sign$n';
  if (n < 10000) {
    return '$sign${_trim(n / 1000)} K';
  }
  if (n < 1000000) {
    return '$sign${(n / 1000).round()} K';
  }
  if (n < 10000000) {
    return '$sign${_trim(n / 1000000)} M';
  }
  return '$sign${(n / 1000000).round()} M';
}

String _trim(double value) {
  final text = value.toStringAsFixed(1);
  if (text.endsWith('.0')) return text.substring(0, text.length - 2);
  return text.replaceAll('.', ',');
}

/// Compact relative time in French: « à l'instant », « il y a 5 min », …
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final delta = reference.difference(time);

  if (delta.isNegative || delta.inSeconds < 45) return "à l'instant";
  if (delta.inMinutes < 60) return 'il y a ${delta.inMinutes} min';
  if (delta.inHours < 24) return 'il y a ${delta.inHours} h';
  if (delta.inDays == 1) return 'hier';
  if (delta.inDays < 7) return 'il y a ${delta.inDays} j';
  if (delta.inDays < 30) return 'il y a ${delta.inDays ~/ 7} sem.';

  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  final local = time.toLocal();
  if (local.year == reference.year) {
    return '${local.day} ${months[local.month - 1]}';
  }
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Media duration: 7s → « 0:07 », 1h02m → « 1:02:03 ».
String formatDuration(Duration duration) {
  final total = duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }
  return '$minutes:$paddedSeconds';
}

/// File size for downloaded media.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  if (bytes < 1024 * 1024 * 1024) {
    final mo = (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
    return '$mo Mo';
  }
  final go = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2).replaceAll('.', ',');
  return '$go Go';
}

extension ReelContext on BuildContext {
  /// True when the shortest side is phone-sized.
  bool get isCompact => MediaQuery.sizeOf(this).shortestSide < 600;

  /// Max content width used to keep tablets and foldables readable.
  double get contentMaxWidth => isCompact ? double.infinity : 560;

  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
}


/// French pluralisation for counters: `plural(1, 'vidéo')` → `vidéo`.
String plural(int count, String singular, [String? pluralForm]) =>
    count > 1 ? (pluralForm ?? '${singular}s') : singular;

/// `countLabel(3, 'vidéo')` → `3 vidéos`.
String countLabel(int count, String singular, [String? pluralForm]) =>
    '$count ${plural(count, singular, pluralForm)}';
