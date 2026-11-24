import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/features/connect/connect_screen.dart';
import 'package:reel/features/feed/feed_screen.dart';
import 'package:reel/features/feed/providers/feed_provider.dart';
import 'package:reel/features/feed/widgets/like_burst.dart';

import '../fixtures/feed_fixture.dart';
import 'package:reel/features/friends/friends_screen.dart';
import 'package:reel/features/inbox/inbox_screen.dart';
import 'package:reel/features/live/live_multi_screen.dart';
import 'package:reel/features/profile/profile_screen.dart';
import 'package:reel/features/search/search_results_screen.dart';
import 'package:reel/features/search/search_screen.dart';
import 'package:reel/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = Size(390, 844);

Future<void> _loadFont() async {
  final loader = FontLoader(AppTokens.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File(
      'assets/fonts/TikTokSans-$weight.otf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  // Package fonts are not loaded in widget tests; without this the icons
  // would all render as empty boxes in the goldens.
  final symbols = File(
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
    'material_symbols_icons-4.2960.0/lib/fonts/MaterialSymbolsRounded.ttf',
  );
  if (symbols.existsSync()) {
    final iconLoader = FontLoader('packages/material_symbols_icons/MaterialSymbolsRounded');
    iconLoader.addFont(
      Future.value(ByteData.view(symbols.readAsBytesSync().buffer)),
    );
    await iconLoader.load();
  }
}

void main() {
  setUpAll(() async {
    await _loadFont();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture screens', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;

    final container = ProviderContainer(
      overrides: [feedItemsProvider.overrideWith(FixtureFeedNotifier.new)],
    );
    addTearDown(container.dispose);

    Future<void> pumpScreen(Widget screen, String name) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: AppTokens.fontFamily,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: colorBgBase,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/$name.png'),
      );
    }

    await pumpScreen(const FeedScreen(), '01_feed');
    await pumpScreen(const SearchScreen(), '02_search');
    await pumpScreen(const ProfileScreen(), '03_profile');
    await pumpScreen(const InboxScreen(), '04_inbox');
    await pumpScreen(const FriendsScreen(), '05_friends');
    await pumpScreen(const LiveMultiScreen(), '06_live');
    await pumpScreen(const ConnectScreen(), '07_connect');
    await pumpScreen(
      const Scaffold(
        backgroundColor: colorBgBase,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: space8),
            child: SearchResultsScreen(query: 'son'),
          ),
        ),
      ),
      '08_search_results',
    );
    await pumpScreen(const SettingsScreen(), '09_settings');
    await pumpScreen(
      const Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: colorBgBase)),
          LikeBurst(position: Offset(195, 400)),
        ],
      ),
      '10_like_burst',
    );
  });
}
