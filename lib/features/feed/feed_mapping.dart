import 'dart:convert';

import '../../remote/json_safe.dart';
import 'models/feed_item.dart';

/// Builds a [FeedItem] from a raw Watchtower item payload.
///
/// Watchtower sources return slightly different shapes; this normalises them in
/// one place so the feed and the search results stay consistent.
FeedItem feedItemFromRaw(
  Map<String, dynamic> raw, {
  required String sourceName,
  String videoUrl = '',
  int index = 0,
}) {
  var thumbnail = '';
  final link = readText(raw['link']);
  if (link.startsWith('{')) {
    try {
      final parsed = json.decode(link) as Map<String, dynamic>;
      thumbnail = readText(parsed['poster']);
    } catch (_) {}
  }
  if (thumbnail.isEmpty) {
    thumbnail = readText(
      raw['imageUrl'] ?? raw['cover'] ?? raw['thumbnail'] ?? raw['image'],
    );
  }

  final title = readText(
    raw['name'] ?? raw['title'] ?? raw['chapter_name'],
    'Sans titre',
  );
  final author = readText(raw['author'] ?? raw['creator'], sourceName);
  final genres = readText(
    raw['genre'] ??
        raw['genres'] ??
        raw['tags'] ??
        raw['description'],
  );
  final sound = readTextOrNull(raw['sound'] ?? raw['music']);

  return FeedItem(
    id: link.isNotEmpty ? link : readText(raw['url'], 'item_$index'),
    videoUrl: videoUrl,
    thumbnailUrl: thumbnail,
    title: title,
    authorUsername: '@${author.toLowerCase().replaceAll(' ', '_')}',
    authorAvatar: thumbnail,
    views: _count(raw, const ['views', 'viewCount', 'playCount', 'plays']),
    likes: _count(raw, const ['likes', 'likeCount']),
    comments: _count(raw, const ['comments', 'commentCount']),
    shares: _count(raw, const ['shares', 'shareCount']),
    hashtags: parseTags(genres).take(4).toList(),
    soundName: sound,
    authorVerified: raw['verified'] == true,
    createdAt: _date(raw['createdAt'] ?? raw['uploadedAt']),
  );
}

/// Reads a counter only when the extension really returned one.
int? _count(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? _date(Object? raw) {
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  return null;
}

/// Extracts the item list from any Watchtower response shape.
List<Map<String, dynamic>> extractRawItems(Map<String, dynamic> data) {
  final list = data['list'] ??
      data['mangas'] ??
      data['items'] ??
      data['data'] ??
      data['results'] ??
      data['videos'] ??
      data['posts'] ??
      data['content'] ??
      const [];
  if (list is! List) return const [];
  return list.whereType<Map<String, dynamic>>().toList(growable: false);
}

/// Splits a raw genre/tag string into hashtag-ready tokens.
List<String> parseTags(String genreStr) {
  if (genreStr.isEmpty) return const ['watchtower'];
  return genreStr
      .split(RegExp(r'[,|/·]'))
      .map((g) => g.trim().toLowerCase().replaceAll(' ', ''))
      .where((g) => g.isNotEmpty && g.length <= 20)
      .toList();
}

/// Extracts a playable URL when the source encodes it in the link field.
String? videoUrlFromLink(String link) {
  if (link.isEmpty || !link.startsWith('{')) return null;
  try {
    final parsed = json.decode(link) as Map<String, dynamic>;
    for (final key in const ['hd', 'sd', 'url']) {
      final value = readTextOrNull(parsed[key]);
      if (value != null && value.isNotEmpty) return value;
    }
  } catch (_) {}
  return null;
}
