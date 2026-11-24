import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../remote/remote_client.dart';
import '../../../remote/remote_config_provider.dart';
import '../../feed/feed_mapping.dart';
import '../../feed/models/feed_item.dart';
import '../../feed/providers/feed_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class SearchUser {
  const SearchUser({
    required this.username,
    required this.avatar,
    required this.verified,
    required this.videos,
  });

  final String username;
  final String avatar;
  final bool verified;
  final int videos;
}

class SearchTag {
  const SearchTag({
    required this.tag,
    required this.videos,
  });

  final String tag;
  final int videos;
}

class SearchSound {
  const SearchSound({required this.name, required this.uses});

  final String name;
  final int uses;
}

class SearchResults {
  const SearchResults({
    required this.query,
    this.sourceName = '',
    this.videos = const [],
    this.users = const [],
    this.hashtags = const [],
    this.sounds = const [],
  });

  final String query;
  final String sourceName;
  final List<FeedItem> videos;
  final List<SearchUser> users;
  final List<SearchTag> hashtags;
  final List<SearchSound> sounds;

  bool get isEmpty =>
      videos.isEmpty && users.isEmpty && hashtags.isEmpty && sounds.isEmpty;

  SearchResults sorted(SearchSort sort) {
    final copy = [...videos];
    switch (sort) {
      case SearchSort.relevance:
        break;
      case SearchSort.popular:
        copy.sort((a, b) => b.likes.compareTo(a.likes));
      case SearchSort.recent:
        copy.sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
    }
    return SearchResults(
      query: query,
      sourceName: sourceName,
      videos: copy,
      users: users,
      hashtags: hashtags,
      sounds: sounds,
    );
  }
}

enum SearchSort {
  relevance('Pertinence'),
  popular('Popularité'),
  recent('Récence');

  const SearchSort(this.label);

  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class SearchSortNotifier extends Notifier<SearchSort> {
  @override
  SearchSort build() => SearchSort.relevance;

  void select(SearchSort sort) => state = sort;
}

final searchSortProvider =
    NotifierProvider<SearchSortNotifier, SearchSort>(SearchSortNotifier.new);

/// Recent queries, persisted on the device.
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _prefsKey = 'reel_search_history';
  static const _maxEntries = 12;

  @override
  List<String> build() {
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const [];
  }

  Future<void> _persist(List<String> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, snapshot);
  }

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      trimmed,
      ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxEntries).toList(growable: false);
    state = updated;
    _persist(updated);
  }

  void remove(String query) {
    state = state.where((q) => q != query).toList(growable: false);
    _persist(state);
  }

  void clear() {
    state = const [];
    _persist(const []);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

/// Debounced query used by the results view.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Results
// ─────────────────────────────────────────────────────────────────────────────

final searchResultsProvider =
    FutureProvider.family<SearchResults, String>((ref, rawQuery) async {
  final query = rawQuery.trim();
  if (query.isEmpty) return SearchResults(query: query);

  final client = ref.watch(remoteClientProvider);
  if (client == null) {
    // Sans serveur, on cherche dans les vidéos déjà chargées : ce sont de
    // vraies données, pas un jeu de démonstration.
    final local = _localMatches(ref.watch(feedItemsProvider).value ?? const [], query);
    if (local.isNotEmpty) return _resultsFrom(query, 'Feed chargé', local);
    throw const SearchUnavailable(
      'Aucun serveur configuré — connecte-toi pour rechercher.',
    );
  }

  final source = await _resolveSource(ref, client);
  if (source == null) {
    throw const SearchUnavailable(
      'Le serveur ne liste aucune source de contenu.',
    );
  }

  final data = await client
      .search(source.id, query)
      .timeout(const Duration(seconds: 25));
  final raw = extractRawItems(data);

  final videos = [
    for (var i = 0; i < raw.length; i++)
      feedItemFromRaw(
        raw[i],
        sourceName: source.name,
        index: i,
      ),
  ];

  return _resultsFrom(query, source.name, videos);
});

SearchResults _resultsFrom(String query, String sourceName, List<FeedItem> videos) {
  return SearchResults(
    query: query,
    sourceName: sourceName,
    videos: videos,
    users: _usersFrom(videos),
    hashtags: _tagsFrom(videos),
    sounds: _soundsFrom(videos),
  );
}

List<FeedItem> _localMatches(List<FeedItem> items, String query) {
  final needle = query.toLowerCase();
  return items
      .where((item) =>
          item.title.toLowerCase().contains(needle) ||
          item.authorUsername.toLowerCase().contains(needle) ||
          item.soundName.toLowerCase().contains(needle) ||
          item.hashtags.any((tag) => tag.toLowerCase().contains(needle)))
      .toList(growable: false);
}

class SearchUnavailable implements Exception {
  const SearchUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<({String id, String name})?> _resolveSource(
  Ref ref,
  RemoteApiClient client,
) async {
  try {
    final config = await ref.read(remoteConfigProvider.future);
    final sources = await client.sources().timeout(
          const Duration(seconds: 15),
        );
    if (sources.isEmpty) return null;

    final maps = sources.cast<Map<String, dynamic>>();
    final preferred = config.selectedSourceId;
    final match = maps.where(
      (s) => s['id']?.toString() == preferred || s['name'] == preferred,
    );
    final chosen = match.isNotEmpty ? match.first : maps.first;
    return (
      id: chosen['id']?.toString() ?? '',
      name: chosen['name']?.toString() ?? chosen['id']?.toString() ?? '',
    );
  } catch (_) {
    final config = await ref.read(remoteConfigProvider.future);
    if (config.selectedSourceId.isEmpty) return null;
    return (id: config.selectedSourceId, name: config.selectedSourceId);
  }
}

List<SearchUser> _usersFrom(List<FeedItem> videos) {
  final byAuthor = <String, List<FeedItem>>{};
  for (final video in videos) {
    byAuthor.putIfAbsent(video.authorUsername, () => []).add(video);
  }
  return byAuthor.entries
      .map(
        (entry) => SearchUser(
          username: entry.key,
          avatar: entry.value.first.authorAvatar,
          verified: entry.value.any((v) => v.authorVerified),
          videos: entry.value.length,
        ),
      )
      .toList(growable: false);
}

List<SearchTag> _tagsFrom(List<FeedItem> videos) {
  final counts = <String, int>{};
  for (final video in videos) {
    for (final tag in video.hashtags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => SearchTag(tag: e.key, videos: e.value))
      .toList(growable: false);
}

List<SearchSound> _soundsFrom(List<FeedItem> videos) {
  final counts = <String, int>{};
  for (final video in videos) {
    counts[video.soundName] = (counts[video.soundName] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .take(12)
      .map((e) => SearchSound(name: e.key, uses: e.value))
      .toList(growable: false);
}

/// Hashtags currently popular in the loaded feed, used for suggestions.
final trendingTagsProvider = Provider<List<SearchTag>>((ref) {
  final items = ref.watch(feedItemsProvider).asData?.value ?? const [];
  final counts = <String, int>{};
  for (final item in items) {
    for (final tag in item.hashtags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .take(8)
      .map((e) => SearchTag(tag: e.key, videos: e.value))
      .toList(growable: false);
});

/// Creators currently present in the feed, used for suggestions.
final trendingCreatorsProvider = Provider<List<SearchUser>>((ref) {
  final items = ref.watch(feedItemsProvider).asData?.value ?? const [];
  return _usersFrom(items).take(8).toList(growable: false);
});
