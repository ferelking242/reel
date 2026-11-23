import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/utils/formatters.dart';

void main() {
  group('formatCount', () {
    test('keeps small numbers untouched', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
    });

    test('uses K below one million', () {
      expect(formatCount(1240), '1,2 K');
      expect(formatCount(12000), '12 K');
      expect(formatCount(999999), '1000 K');
    });

    test('uses M above one million', () {
      expect(formatCount(1500000), '1,5 M');
      expect(formatCount(24000000), '24 M');
    });

    test('keeps the sign', () {
      expect(formatCount(-1200), '-1,2 K');
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 5, 20, 12);

    test('handles just now and minutes', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(seconds: 10)), now: now),
        "à l'instant",
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        'il y a 5 min',
      );
    });

    test('handles hours, days and weeks', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
        'il y a 3 h',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 1)), now: now),
        'hier',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 10)), now: now),
        'il y a 1 sem.',
      );
    });

    test('falls back to a date for older entries', () {
      expect(
        formatRelativeTime(DateTime(2025, 3, 4), now: now),
        '4 mars 2025',
      );
    });
  });

  group('formatDuration', () {
    test('pads seconds', () {
      expect(formatDuration(const Duration(seconds: 7)), '0:07');
      expect(formatDuration(const Duration(minutes: 3, seconds: 5)), '3:05');
    });

    test('adds hours when needed', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('formatBytes', () {
    test('uses french units', () {
      expect(formatBytes(512), '512 o');
      expect(formatBytes(2048), '2 Ko');
      expect(formatBytes(5 * 1024 * 1024), '5,0 Mo');
    });
  });
}
