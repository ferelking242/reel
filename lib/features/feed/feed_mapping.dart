import 'dart:convert';
import 'dart:math';

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
  final link = raw['link'] as String? ?? '';
  if (link.startsWith('{')) {
    try {
      final parsed = json.decode(link) as Map<String, dynamic>;
      thumbnail = parsed['poster'] as String? ?? '';
    } catch (_) {}
  }
  if (thumbnail.isEmpty) {
    thumbnail = raw['imageUrl'] as String? ??
        raw['cover'] as String? ??
        raw['thumbnail'] as String? ??
        raw['image'] as String? ??
        '';
  }

  final title = raw['name'] as String? ??
      raw['title'] as String? ??
      raw['chapter_name'] as String? ??
      'Sans titre';
  final author =
      raw['author'] as String? ?? raw['creator'] as String? ?? sourceName;
  final genres = raw['genre'] as String? ??
      raw['genres'] as String? ??
      raw['tags'] as String? ??
      (raw['description'] as String? ?? '');

  final seed = title.hashCode.abs();
  final rng = Random(seed + index);

  return FeedItem(
    id: link.isNotEmpty ? link : (raw['url'] as String? ?? 'item_$index'),
    videoUrl: videoUrl,
    thumbnailUrl: thumbnail,
    title: title,
    authorUsername: '@${author.toLowerCase().replaceAll(' ', '_')}',
    authorAvatar: thumbnail,
    likes: 1000 + rng.nextInt(499000),
    comments: 100 + rng.nextInt(9900),
    shares: 200 + rng.nextInt(19800),
    bookmarks: 50 + rng.nextInt(4950),
    hashtags: parseTags(genres).take(4).toList(),
    soundName: 'Son original — ${title.split(' ').take(3).join(' ')}',
    authorVerified: rng.nextInt(4) == 0,
    createdAt: DateTime.now().subtract(Duration(hours: rng.nextInt(72))),
  );
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
      final value = parsed[key] as String?;
      if (value != null && value.isNotEmpty) return value;
    }
  } catch (_) {}
  return null;
}
