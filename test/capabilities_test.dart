import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/contract/contract_provider.dart';
import 'package:reel/core/contract/ui_contract.dart';
import 'package:reel/core/icons/reel_icons.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/features/feed/feed_mapping.dart';
import 'package:reel/features/feed/models/feed_item.dart';
import 'package:reel/features/feed/widgets/feed_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A layout as an extension can declare it: the Reel renderer, a live tab, and
/// no like/comment endpoints (RedGIFs-style).
final _restricted = UiContract(
  schemaVersion: 1,
  id: 'redgifs',
  dock: UiContract.fallback.dock,
  playerAutoplay: true,
  playerLoop: true,
  playerMuted: false,
  renderer: ReelRenderer.reel,
  capabilities: ExtensionCapabilities(
    live: true,
    views: true,
    likes: false,
    comments: false,
    shares: false,
    sounds: true,
    download: false,
    follow: true,
  ),
);

Widget _wrap(Widget child, {required UiContract contract}) {
  return ProviderScope(
    overrides: [
      uiContractProvider.overrideWith((ref) async => contract),
    ],
    child: MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: colorBgBase),
      home: Scaffold(body: child),
    ),
  );
}

FeedItem _item({
  int? views,
  int? likes,
  int? comments,
  String? sound,
}) {
  return FeedItem(
    id: 'item',
    videoUrl: '',
    thumbnailUrl: '',
    title: 'Titre',
    authorUsername: '@auteur',
    authorAvatar: '',
    views: views,
    likes: likes,
    comments: comments,
    hashtags: const [],
    soundName: sound,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an extension layout declares its renderer and capabilities', () {
    final contract = UiContract.fromJson({
      'schemaVersion': 1,
      'renderer': 'reel',
      'capabilities': {
        'live': true,
        'views': true,
        'likes': false,
        'comments': false,
      },
    });

    expect(contract.renderer, ReelRenderer.reel);
    expect(contract.capabilities.live, isTrue);
    expect(contract.capabilities.views, isTrue);
    expect(contract.capabilities.likes, isFalse);
    expect(contract.capabilities.comments, isFalse);
    // Undeclared capabilities keep the permissive default.
    expect(contract.capabilities.sounds, isTrue);
  });

  test('a layout without renderer falls back to the watch renderer', () {
    final contract = UiContract.fromJson({'schemaVersion': 1});
    expect(contract.renderer, ReelRenderer.watch);
    expect(contract.capabilities, ExtensionCapabilities.all);
  });

  test('counters are never invented when the extension sends none', () {
    final item = feedItemFromRaw(
      {'link': 'https://example.org/1', 'name': 'Clip'},
      sourceName: 'RedGIFs',
    );

    expect(item.likes, isNull);
    expect(item.comments, isNull);
    expect(item.shares, isNull);
    expect(item.soundName, isNull);
    expect(item.authorVerified, isFalse);
  });

  test('counters are read when the extension sends them', () {
    final item = feedItemFromRaw(
      {
        'link': 'https://example.org/1',
        'name': 'Clip',
        'views': 12000,
        'likes': '1.2K',
        'sound': 'Son original',
        'verified': true,
      },
      sourceName: 'RedGIFs',
    );

    expect(item.views, 12000);
    expect(item.likes, 12);
    expect(item.soundName, 'Son original');
    expect(item.authorVerified, isTrue);
  });

  testWidgets('a source without likes or comments hides both actions',
      (tester) async {
    await tester.pumpWidget(_wrap(
      FeedPage(
        item: _item(views: 12500),
        isActive: true,
        onOpenComments: () {},
        onOpenShare: () {},
      ),
      contract: _restricted,
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byWidgetPredicate(
        (w) => w is ReelIcon && w.glyph == ReelGlyph.heart,
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is ReelIcon && w.glyph == ReelGlyph.comment,
      ),
      findsNothing,
    );
    // Views are the only counter the extension exposes.
    expect(find.text('13 K'), findsOneWidget);
  });

  testWidgets('a full source keeps like and comment actions', (tester) async {
    await tester.pumpWidget(_wrap(
      FeedPage(
        item: _item(likes: 1000, comments: 20),
        isActive: true,
        onOpenComments: () {},
        onOpenShare: () {},
      ),
      contract: UiContract.fallback,
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byWidgetPredicate(
        (w) => w is ReelIcon && w.glyph == ReelGlyph.heart,
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is ReelIcon && w.glyph == ReelGlyph.comment,
      ),
      findsWidgets,
    );
  });
}
