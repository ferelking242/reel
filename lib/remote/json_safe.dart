/// Tolerant readers for the JSON the Watchtower server returns.
///
/// The server serialises Isar entities, so ids arrive as ints, counts as
/// numbers, and optional fields as `null`. A plain `as String` on an int
/// throws `type 'int' is not a subtype of type 'String' in type cast` and the
/// whole screen fails instead of showing one odd row.
library;

/// Reads [value] as text, stringifying numbers and booleans.
String readText(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Reads [value] as `String?`, stringifying numbers and booleans.
String? readTextOrNull(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

/// Reads [value] as an int, accepting numbers and numeric strings.
int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Reads [value] as a bool, accepting `1/0` and `"true"/"false"`.
bool readBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

/// Reads a list of JSON objects, skipping anything malformed.
List<Map<String, dynamic>> readMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}
