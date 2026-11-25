import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/features/feed/providers/feed_provider.dart';
import 'package:reel/remote/json_safe.dart';
import 'package:reel/remote/remote_client.dart';
import 'package:reel/remote/remote_config_provider.dart';
import 'package:reel/remote/reel_transport.dart';

/// The Watchtower server serialises Isar entities (`id` is an int) and can be
/// down when the app starts. Neither may block the feed.
class _FakeTransport implements ReelTransport {
  _FakeTransport({this.online = false});

  bool online;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    if (!online) {
      throw Exception('Failed to reach $path after 2 attempts');
    }
    switch (path) {
      case '/api/sources':
        return {
          'sources': [
            {'id': 7, 'name': 'RedGifs', 'lang': 'en', 'itemType': 'video'},
          ],
          'hiddenNsfw': 0,
        };
      case '/api/sources/7/videos':
        return {
          'videos': [
            {'quality': '720p', 'url': 'https://cdn.example.org/1.mp4'},
          ],
        };
      case '/api/sources/7/popular':
        return {
          'mangas': [
            {
              'link': 'https://example.org/watch/1',
              'name': 'Clip',
              'imageUrl': 'https://example.org/1.jpg',
            },
          ],
          'hasNextPage': false,
        };
    }
    throw Exception('404 $path');
  }

  @override
  void close() {}
}

void main() {
  group('read helpers', () {
    test('stringify numbers instead of throwing', () {
      expect(readText(7), '7');
      expect(readText(null), '');
      expect(readText(null, 'fallback'), 'fallback');
      expect(readTextOrNull(0), '0');
      expect(readInt('42'), 42);
      expect(readInt(3.9), 3);
      expect(readBool(1), isTrue);
      expect(readBool('false'), isFalse);
    });

    test('drop malformed list entries', () {
      final list = readMapList([
        {'id': 1},
        'nope',
        null,
        {'id': 2},
      ]);
      expect(list, hasLength(2));
      expect(readMapList('nope'), isEmpty);
    });
  });

  group('RemoteApiClient', () {
    test('reads int source ids from the server payload', () async {
      final client = RemoteApiClient(
        baseUrl: 'http://fake',
        transport: _FakeTransport(online: true),
      );
      final payload = await client.sourcesPayload();

      expect(payload['hiddenNsfw'], 0);
      expect(readText((payload['sources'] as List).first['id']), '7');
      client.dispose();
    });

    test('flags an unreachable server as a network failure', () {
      expect(
        RemoteApiClient.isNetworkFailure(
          Exception('Failed to reach /api/sources after 2 attempts'),
        ),
        isTrue,
      );
      expect(
        RemoteApiClient.isNetworkFailure(Exception('401 Unauthorized')),
        isFalse,
      );
    });
  });

  group('FeedNotifier', () {
    test('a silent server yields an empty feed and retries by itself', () async {
      final transport = _FakeTransport();
      final container = ProviderContainer(
        overrides: [
          remoteClientProvider.overrideWithValue(
            RemoteApiClient(baseUrl: 'http://fake', transport: transport),
          ),
          remoteConfigProvider.overrideWith(
            () => _StaticConfigNotifier(
              const RemoteConfig(baseUrl: 'http://fake', apiKey: 'k'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(feedItemsProvider.future);
      expect(items, isEmpty, reason: 'un serveur muet ne bloque pas le feed');
      expect(
        container.read(serverStatusProvider),
        contains('nouvelle tentative'),
      );

      transport.online = true;
      // First retry fires after 4 s.
      await Future<void>.delayed(const Duration(seconds: 5));
      final retried = container.read(feedItemsProvider).value;
      expect(retried, isNotNull);
      expect(retried, hasLength(1));
      expect(retried!.first.title, 'Clip');
    });

    test('a reachable server loads the feed on the first try', () async {
      final container = ProviderContainer(
        overrides: [
          remoteClientProvider.overrideWithValue(
            RemoteApiClient(
              baseUrl: 'http://fake',
              transport: _FakeTransport(online: true),
            ),
          ),
          remoteConfigProvider.overrideWith(
            () => _StaticConfigNotifier(
              const RemoteConfig(baseUrl: 'http://fake', apiKey: 'k'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(feedItemsProvider.future);
      expect(items, hasLength(1));
      expect(items.first.title, 'Clip');
    });
  });
}

class _StaticConfigNotifier extends RemoteConfigNotifier {
  _StaticConfigNotifier(this.config);

  final RemoteConfig config;

  @override
  Future<RemoteConfig> build() async => config;
}
