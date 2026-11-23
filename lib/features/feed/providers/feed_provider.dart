import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../remote/remote_client.dart';
import '../../../remote/remote_config_provider.dart';
import '../../../utils/log/app_file_logger.dart';
import '../demo_feed.dart';
import '../feed_mapping.dart';
import '../models/feed_item.dart';

const _tag = 'FeedProvider';

/// Error surfaced to the feed UI. [details] keeps the raw server message so the
/// user can expand it when troubleshooting.
class FeedException implements Exception {
  const FeedException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() => details == null ? message : '$message\n$details';
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple state holders
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentFeedIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void update(int value) => state = value;
}

final currentFeedIndexProvider =
    NotifierProvider<_CurrentFeedIndexNotifier, int>(
  _CurrentFeedIndexNotifier.new,
);

/// 0 = « Pour toi », 1 = « Suivis ».
class _FeedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void update(int value) => state = value;
}

final feedTabProvider =
    NotifierProvider<_FeedTabNotifier, int>(_FeedTabNotifier.new);

class _ServerStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void update(String? value) => state = value;
}

final serverStatusProvider =
    NotifierProvider<_ServerStatusNotifier, String?>(
  _ServerStatusNotifier.new,
);

class _LoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

final loadingMoreProvider =
    NotifierProvider<_LoadingMoreNotifier, bool>(_LoadingMoreNotifier.new);

/// When true the feed shows a local demo so the UI can be explored without a
/// Watchtower server.
class _DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void enable() => state = true;
  void disable() => state = false;
}

final demoModeProvider =
    NotifierProvider<_DemoModeNotifier, bool>(_DemoModeNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Feed items
// ─────────────────────────────────────────────────────────────────────────────

final feedItemsProvider =
    AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  static const int itemsPerPage = 8;
  static const int _maxSourcesToTry = 4;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _sourceId = '';
  String _sourceName = '';
  RemoteApiClient? _client;

  @override
  Future<List<FeedItem>> build() async {
    _reset();

    if (ref.watch(demoModeProvider)) {
      _scheduleStatus('Mode démo — contenu local');
      return demoFeedItems;
    }

    final client = ref.watch(remoteClientProvider);
    if (client == null) {
      // First run: show the local demo so the interface is never empty.
      _scheduleStatus('Aucun serveur configuré — mode démo');
      Future.microtask(() {
        if (!ref.mounted) return;
        if (!ref.read(demoModeProvider)) {
          ref.read(demoModeProvider.notifier).enable();
        }
      });
      return demoFeedItems;
    }

    final config = await ref.read(remoteConfigProvider.future);
    final items = await _loadFirstPage(client, config.selectedSourceId);
    return items;
  }

  /// Riverpod forbids mutating other providers while this one builds, so the
  /// status line is published on the next frame.
  void _scheduleStatus(String? message) {
    Future.microtask(() {
      if (!ref.mounted) return;
      ref.read(serverStatusProvider.notifier).update(message);
    });
  }

  void _reset() {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _sourceId = '';
    _sourceName = '';
    _client = null;
  }

  /// Tries the selected source first, then falls back to the other sources
  /// exposed by the server so a single broken provider does not empty the feed.
  Future<List<FeedItem>> _loadFirstPage(
    RemoteApiClient client,
    String preferredSourceId,
  ) async {
    final candidates = await _candidateSources(client, preferredSourceId);
    if (candidates.isEmpty) {
      throw const FeedException(
        'Le serveur ne liste aucune source de contenu.',
        details: 'GET /api/sources a renvoyé une liste vide.',
      );
    }

    final failures = <String>[];
    for (final candidate in candidates.take(_maxSourcesToTry)) {
      try {
        final items = await _fetchPage(
          client,
          candidate.id,
          page: 1,
          resolveVideos: true,
        );
        if (items.isEmpty) {
          failures.add('${candidate.name}: aucune vidéo jouable');
          continue;
        }

        _client = client;
        _sourceId = candidate.id;
        _sourceName = candidate.name;
        _hasMore = items.length >= itemsPerPage;

        final fellBack = preferredSourceId.isNotEmpty &&
            candidate.id != preferredSourceId;
        ref.read(serverStatusProvider.notifier).update(
              fellBack
                  ? 'Source précédente indisponible — lecture de « ${candidate.name} »'
                  : '✓ ${candidate.name} — ${items.length} vidéos',
            );
        return items;
      } catch (error) {
        failures.add('${candidate.name}: ${_shortError(error)}');
        logger.error(_tag, 'Source ${candidate.id} en échec: $error');
      }
    }

    throw FeedException(
      'Aucune source ne renvoie de vidéo lisible.',
      details: failures.join('\n'),
    );
  }

  Future<List<({String id, String name})>> _candidateSources(
    RemoteApiClient client,
    String preferredSourceId,
  ) async {
    try {
      final raw = await client.sources().timeout(const Duration(seconds: 15));
      final all = raw
          .cast<Map<String, dynamic>>()
          .map((s) => (
                id: s['id']?.toString() ?? '',
                name: s['name']?.toString() ?? s['id']?.toString() ?? '',
              ))
          .where((s) => s.id.isNotEmpty)
          .toList();

      if (all.isEmpty) return const [];

      final preferred = all.where(
        (s) => s.id == preferredSourceId || s.name == preferredSourceId,
      );
      final rest = all.where(
        (s) => s.id != preferredSourceId && s.name != preferredSourceId,
      );
      return [...preferred, ...rest];
    } catch (error) {
      logger.log(_tag, 'Impossible de lister les sources: $error');
      if (preferredSourceId.isEmpty) return const [];
      return [(id: preferredSourceId, name: preferredSourceId)];
    }
  }

  /// Fetches one page for [sourceId], resolving playable URLs when needed.
  Future<List<FeedItem>> _fetchPage(
    RemoteApiClient client,
    String sourceId, {
    required int page,
    required bool resolveVideos,
  }) async {
    final rawItems = await _fetchRawItems(client, sourceId, page: page);
    if (rawItems.isEmpty) return const [];

    final slice = rawItems.take(itemsPerPage).toList(growable: false);
    final baseIndex = (page - 1) * itemsPerPage;

    if (!resolveVideos) {
      return [
        for (var i = 0; i < slice.length; i++)
          feedItemFromRaw(
            slice[i],
            sourceName: _sourceName,
            index: baseIndex + i,
          ),
      ];
    }

    // Resolve in small batches: a 20s timeout per item would stall the feed.
    final resolved = List<FeedItem?>.filled(slice.length, null);
    const batchSize = 4;
    for (var start = 0; start < slice.length; start += batchSize) {
      final end = min(start + batchSize, slice.length);
      await Future.wait([
        for (var i = start; i < end; i++)
          _resolveItem(client, sourceId, slice[i], baseIndex + i).then(
            (item) => resolved[i] = item,
            onError: (_) => resolved[i] = null,
          ),
      ]);
    }

    return resolved.whereType<FeedItem>().toList(growable: false);
  }

  Future<FeedItem?> _resolveItem(
    RemoteApiClient client,
    String sourceId,
    Map<String, dynamic> raw,
    int index,
  ) async {
    final link = raw['link'] as String? ?? raw['url'] as String? ?? '';
    var videoUrl = videoUrlFromLink(link);
    if (videoUrl == null && link.isNotEmpty) {
      videoUrl = await _resolveVideoUrl(client, sourceId, link);
    }
    if (videoUrl == null || videoUrl.isEmpty) return null;
    return feedItemFromRaw(
      raw,
      sourceName: _sourceName,
      videoUrl: videoUrl,
      index: index,
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _sourceId.isEmpty) return;
    final client = _client ?? ref.read(remoteClientProvider);
    if (client == null) return;

    _isLoadingMore = true;
    ref.read(loadingMoreProvider.notifier).update(true);
    final nextPage = _page + 1;

    try {
      final newItems = await _fetchPage(
        client,
        _sourceId,
        page: nextPage,
        resolveVideos: true,
      );
      if (newItems.isEmpty) {
        _hasMore = false;
        return;
      }
      _page = nextPage;
      final current = state.value ?? const <FeedItem>[];
      final seen = current.map((e) => e.id).toSet();
      final deduped =
          newItems.where((item) => !seen.contains(item.id)).toList();
      state = AsyncData([...current, ...deduped]);
      _hasMore = newItems.length >= itemsPerPage;
    } catch (error) {
      logger.error(_tag, 'loadMore page $nextPage: $error');
    } finally {
      _isLoadingMore = false;
      ref.read(loadingMoreProvider.notifier).update(false);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _shortError(Object error) {
    final text = error.toString().replaceAll('Exception: ', '');
    return text.length > 180 ? '${text.substring(0, 180)}…' : text;
  }

  Future<List<Map<String, dynamic>>> _fetchRawItems(
    RemoteApiClient client,
    String sourceId, {
    required int page,
  }) async {
    final attempts = <Future<Map<String, dynamic>> Function()>[
      () => client.popular(sourceId, page: page),
      () => client.latest(sourceId, page: page),
      () => client.search(sourceId, '', page: page),
    ];

    Object? lastError;
    for (final attempt in attempts) {
      try {
        final data = await attempt().timeout(const Duration(seconds: 20));
        final items = extractRawItems(data);
        if (items.isNotEmpty) {
          return items;
        }
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) throw lastError;
    return const [];
  }

  Future<String?> _resolveVideoUrl(
    RemoteApiClient client,
    String sourceId,
    String itemLink,
  ) async {
    try {
      final data = await client
          .videos(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));
      final url = _bestVideoUrl(data['videos'] as List? ?? const []);
      if (url != null) return url;
    } catch (_) {}

    try {
      final detail = await client
          .detail(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));
      final chapters = detail['chapters'] as List? ??
          detail['episodes'] as List? ??
          detail['chapter_list'] as List? ??
          const [];
      if (chapters.isEmpty) return null;

      final episode = chapters.length == 1 ? chapters.first : chapters.last;
      final episodeUrl = episode['url'] as String? ??
          episode['link'] as String? ??
          episode['chapterUrl'] as String? ??
          '';
      if (episodeUrl.isEmpty) return null;

      final videoData = await client
          .videos(sourceId, episodeUrl)
          .timeout(const Duration(seconds: 20));
      return _bestVideoUrl(videoData['videos'] as List? ?? const []);
    } catch (_) {}

    return null;
  }

  String? _bestVideoUrl(List<dynamic> videos) {
    if (videos.isEmpty) return null;
    for (final quality in const ['1080', '720', '480']) {
      for (final video in videos) {
        final label = (video['quality'] as String? ?? '').toLowerCase();
        final url = video['url'] as String? ?? '';
        if (label.contains(quality) && url.isNotEmpty) return url;
      }
    }
    for (final video in videos) {
      final url = video['url'] as String? ?? '';
      if (url.isNotEmpty) return url;
    }
    return null;
  }
}
