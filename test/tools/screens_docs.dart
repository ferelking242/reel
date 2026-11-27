import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/host/reel_host.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/features/comments/comments_sheet.dart';
import 'package:reel/features/connect/connect_screen.dart';
import 'package:reel/features/feed/feed_screen.dart';
import 'package:reel/features/feed/models/feed_item.dart';
import 'package:reel/features/feed/providers/engagement_provider.dart';
import 'package:reel/features/feed/providers/feed_provider.dart';
import 'package:reel/features/feed/widgets/create_sheet.dart';
import 'package:reel/features/feed/widgets/item_sheet.dart';
import 'package:reel/features/feed/widgets/like_burst.dart';
import 'package:reel/features/friends/friends_screen.dart';
import 'package:reel/features/inbox/inbox_screen.dart';
import 'package:reel/features/live/live_multi_screen.dart';
import 'package:reel/features/profile/creator_screen.dart';
import 'package:reel/features/profile/edit_profile_sheet.dart';
import 'package:reel/features/profile/providers/profile_provider.dart';
import 'package:reel/features/profile/profile_screen.dart';
import 'package:reel/features/search/providers/search_provider.dart';
import 'package:reel/features/search/search_filters_sheet.dart';
import 'package:reel/features/search/search_screen.dart';
import 'package:reel/features/settings/settings_screen.dart';
import 'package:reel/features/share/share_sheet.dart';
import 'package:reel/remote/remote_config_provider.dart';
import 'package:reel/remote/reel_transport.dart';
import 'package:reel/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/feed_fixture.dart';

/// Screenshots used by `docs/screens/README.md`.
///
/// Regenerate with:
///   flutter test test/tools/screens_docs.dart --update-goldens
///
/// The output lands in `docs/screens/images/` (390x844 logical points, x2).
const _phone = Size(390, 844);

Future<void> _loadFonts() async {
  final loader = FontLoader(AppTokens.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/TikTokSans-$weight.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  // Emoji live in their own family; the app asks for it as a fallback.
  final emoji = File('/workspace/fonts/emoji.ttf');
  if (emoji.existsSync()) {
    final emojiLoader = FontLoader('Noto Color Emoji');
    emojiLoader.addFont(
      Future.value(ByteData.view(emoji.readAsBytesSync().buffer)),
    );
    await emojiLoader.load();
  }

  final cache = Directory(
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
  );
  if (!cache.existsSync()) return;
  final symbols = cache
      .listSync()
      .whereType<Directory>()
      .where((dir) => dir.path.contains('material_symbols_icons-'))
      .map((dir) => File('${dir.path}/lib/fonts/MaterialSymbolsRounded.ttf'))
      .where((file) => file.existsSync())
      .firstOrNull;
  if (symbols == null) return;
  final iconLoader = FontLoader(
    'packages/material_symbols_icons/MaterialSymbolsRounded',
  );
  iconLoader.addFont(
    Future.value(ByteData.view(symbols.readAsBytesSync().buffer)),
  );
  await iconLoader.load();
}

/// Feed that never resolves: the screen keeps its skeleton.
class _LoadingFeedNotifier extends FeedNotifier {
  @override
  Future<List<FeedItem>> build() {
    ref.onDispose(() {});
    return Completer<List<FeedItem>>().future;
  }
}

/// Feed the server refused to serve.
class _ErrorFeedNotifier extends FeedNotifier {
  @override
  Future<List<FeedItem>> build() async {
    throw const FeedUnavailable('Le serveur ne répond pas (délai dépassé).');
  }
}

class FeedUnavailable implements Exception {
  const FeedUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class _EmptyFeedNotifier extends FeedNotifier {
  @override
  Future<List<FeedItem>> build() async => const [];
}

/// A server the user already connected to.
class _ConfiguredNotifier extends RemoteConfigNotifier {
  @override
  Future<RemoteConfig> build() async => const RemoteConfig(
        baseUrl: 'http://192.168.1.42:4567',
        apiKey: 'demo-key',
        selectedSourceId: '7',
      );
}

ThemeData _theme() => ThemeData(
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: colorBgBase,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorBrand,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

/// Answers the connect screen's ping/sources probes without a network.
class _DemoTransport implements ReelTransport {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    if (path.startsWith('/api/ping')) {
      return {'status': 'ok', 'version': '1.9.4'};
    }
    if (path.startsWith('/api/sources')) {
      return {
        'hiddenNsfw': 0,
        'sources': [
          {'id': '7', 'name': 'Exemple — Vidéos', 'lang': 'fr', 'nsfw': false},
          {'id': '8', 'name': 'Exemple — Séries', 'lang': 'fr', 'nsfw': false},
        ],
      };
    }
    return const {};
  }

  @override
  void close() {}
}

ProviderContainer _container({
  bool configured = true,
  FeedNotifier Function()? feed,
  Future<SearchResults> Function(String query)? results,
}) {
  return ProviderContainer(
    // Riverpod 3 retries failed providers by default; a screenshot must not.
    retry: (_, __) => null,
    overrides: [
      feedItemsProvider.overrideWith(feed ?? FixtureFeedNotifier.new),
      remoteConfigProvider.overrideWith(
        configured ? _ConfiguredNotifier.new : RemoteConfigNotifier.new,
      ),
      if (results != null)
        searchResultsProvider.overrideWith((ref, query) => results(query)),
      if (configured)
        reelHostProvider.overrideWithValue(
          ReelHost(
            sourceId: '7',
            sourceName: 'Exemple — Vidéos',
            transport: _DemoTransport(),
          ),
        ),
    ],
  );
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture every screen and state', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    tester.view.physicalSize = _phone * 2;
    tester.view.devicePixelRatio = 2;

    Future<void> capture(
      Widget child,
      String name, {
      ProviderContainer? container,
      void Function(ProviderContainer scope)? prepare,
      Duration settle = const Duration(milliseconds: 900),
    }) async {
      SharedPreferences.setMockInitialValues({});
      final scope = container ?? _container();
      addTearDown(scope.dispose);
      prepare?.call(scope);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme(),
            home: child,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(settle);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../docs/screens/images/$name.png'),
      );
    }

    // ── Splash ──────────────────────────────────────────────────────────────
    await capture(const SplashScreen(), '01_splash', settle: const Duration(milliseconds: 1000));

    // ── Feed ────────────────────────────────────────────────────────────────
    await capture(const FeedScreen(), '02_feed_pour_toi');
    await capture(
      const FeedScreen(),
      '03_feed_suivis_vide',
      prepare: (scope) => scope.read(feedTabProvider.notifier).update(1),
    );
    await capture(
      const FeedScreen(),
      '04_feed_chargement',
      container: _container(feed: _LoadingFeedNotifier.new),
      settle: const Duration(milliseconds: 300),
    );
    await capture(
      const FeedScreen(),
      '05_feed_erreur',
      container: _container(feed: _ErrorFeedNotifier.new),
    );
    await capture(
      const FeedScreen(),
      '06_feed_vide',
      container: _container(feed: _EmptyFeedNotifier.new),
    );
    await capture(
      const _PausedFeed(),
      '07_feed_pause',
      settle: const Duration(milliseconds: 400),
    );
    await capture(
      const _SheetHost(open: _openComments),
      '08_commentaires',
      prepare: _seedComments,
    );
    await capture(
      const _SheetHost(open: _openComments),
      '09_commentaires_vide',
    );
    await capture(
      const _SheetHost(open: _openShare),
      '10_partage',
    );
    await capture(
      const _SheetHost(open: _openCreate),
      '11_creation',
    );
    await capture(
      const _SheetHost(open: _openItem),
      '12_actions_video',
    );
    await capture(
      const Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: colorBgBase)),
          LikeBurst(position: Offset(195, 420)),
        ],
      ),
      '13_like_burst',
      settle: const Duration(milliseconds: 60),
    );

    // ── Search ──────────────────────────────────────────────────────────────
    await capture(const SearchScreen(), '14_recherche');
    await capture(
      const SearchScreen(),
      '15_recherche_resultats',
      prepare: (scope) => scope.read(searchQueryProvider.notifier).update('son'),
      container: _container(results: _demoResults),
    );
    await capture(
      const _SheetHost(open: _openFilters, child: SearchScreen()),
      '16_recherche_filtres',
    );
    await capture(
      const SearchScreen(),
      '17_recherche_aucun_resultat',
      prepare: (scope) =>
          scope.read(searchQueryProvider.notifier).update('zzzz'),
      container: _container(
        results: (query) async => SearchResults(query: query),
      ),
    );

    // ── Profile ─────────────────────────────────────────────────────────────
    await capture(const ProfileScreen(), '18_profil');
    await capture(
      const ProfileScreen(),
      '19_profil_favoris_vide',
      prepare: (scope) =>
          scope.read(profileTabProvider.notifier).select(1),
    );
    await capture(
      const _SheetHost(open: _openEditProfile, child: ProfileScreen()),
      '20_profil_edition',
    );

    // ── Creator ─────────────────────────────────────────────────────────────
    await capture(
      CreatorScreen(name: fixtureFeedItems.first.authorUsername),
      '21_createur',
    );
    await capture(
      const CreatorScreen(name: 'studio.inconnu'),
      '22_createur_vide',
    );

    // ── Friends / Inbox / Live ──────────────────────────────────────────────
    await capture(const FriendsScreen(), '23_amis');
    await capture(const InboxScreen(), '24_boite');
    await capture(const LiveMultiScreen(), '25_live');

    // ── Settings / Connect ──────────────────────────────────────────────────
    await capture(const SettingsScreen(), '26_parametres');
    await capture(
      const ConnectScreen(),
      '27_connexion',
      container: _container(configured: false),
    );
    await capture(const ConnectScreen(), '28_connexion_configuree');
  });
}

// ─── Helpers used by the captures ───────────────────────────────────────────

Future<SearchResults> _demoResults(String query) async {
  final videos = fixtureFeedItems.take(6).toList(growable: false);
  return SearchResults(
    query: query,
    sourceName: 'Feed chargé',
    videos: videos,
    users: videos
        .map(
          (item) => SearchUser(
            username: item.authorUsername,
            avatar: item.authorAvatar,
            verified: item.authorVerified,
            videos: 12,
          ),
        )
        .take(4)
        .toList(growable: false),
    hashtags: const [
      SearchTag(tag: 'pourtoi', videos: 128000),
      SearchTag(tag: 'musique', videos: 42000),
      SearchTag(tag: 'sport', videos: 9600),
    ],
    sounds: const [
      SearchSound(name: 'Son original — Studio Nova', uses: 24000),
      SearchSound(name: 'Cuisine — Mijoté', uses: 8700),
    ],
  );
}

/// The feed with its pause overlay on top, as the user sees it.
class _PausedFeed extends StatelessWidget {
  const _PausedFeed();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [FeedScreen(), PauseOverlay(visible: true)],
    );
  }
}

void _seedComments(ProviderContainer scope) {
  final notifier = scope.read(commentsProvider.notifier);
  final id = fixtureFeedItems.first.id;
  notifier.add(id, 'Ce passage est incroyable');
  notifier.add(id, 'La transition est parfaite');
  notifier.add(id, 'Quelqu\'un connaît le titre du son ?');
}

void _openComments(BuildContext context) =>
    showCommentsSheet(context, item: fixtureFeedItems.first);

void _openShare(BuildContext context) =>
    showShareSheet(context, item: fixtureFeedItems.first);

void _openCreate(BuildContext context) => showCreateSheet(context);

void _openItem(BuildContext context) =>
    showItemSheet(context, item: fixtureFeedItems.first);

void _openFilters(BuildContext context) => showSearchFiltersSheet(context);

void _openEditProfile(BuildContext context) => showEditProfileSheet(context);

/// Pumps a blank screen then opens a sheet, so the modal is captured over the
/// real app theme and overlay.
class _SheetHost extends StatefulWidget {
  const _SheetHost({required this.open, this.child});

  final void Function(BuildContext context) open;
  final Widget? child;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.open(context);
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.child ??
      const Scaffold(backgroundColor: colorBgBase, body: SizedBox.expand());
}
