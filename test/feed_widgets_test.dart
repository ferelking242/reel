import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/icons/reel_icons.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/core/widgets/reel_bottom_nav.dart';
import 'package:reel/features/feed/demo_feed.dart';
import 'package:reel/features/feed/providers/engagement_provider.dart';
import 'package:reel/features/feed/widgets/feed_overlay_bottom.dart';
import 'package:reel/features/feed/widgets/feed_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: colorBgBase),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('feed page renders author, description and counters',
      (tester) async {
    final item = demoFeedItems.first;
    await tester.pumpWidget(_wrap(FeedPage(
      item: item,
      isActive: true,
      onOpenComments: () {},
      onOpenShare: () {},
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(item.authorUsername), findsOneWidget);
    expect(find.byType(FeedOverlayBottom), findsOneWidget);
    expect(find.textContaining('K'), findsWidgets);
  });

  testWidgets('bottom navigation exposes five destinations', (tester) async {
    var selected = -1;
    var created = false;

    await tester.pumpWidget(_wrap(ReelBottomNav(
      currentIndex: 0,
      onSelect: (index) => selected = index,
      onCreate: () => created = true,
    )));
    await tester.pump();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Amis'), findsOneWidget);
    expect(find.text('Boîte'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(selected, 4);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is ReelIcon && widget.glyph == ReelGlyph.plus,
      ),
    );
    await tester.pump();
    expect(created, isTrue);
  });

  test('engagement notifier toggles and keeps state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(engagementProvider.notifier);
    expect(container.read(engagementProvider).isLiked('a'), isFalse);

    expect(notifier.toggleLike('a'), isTrue);
    expect(container.read(engagementProvider).isLiked('a'), isTrue);

    expect(notifier.toggleLike('a'), isFalse);
    expect(container.read(engagementProvider).isLiked('a'), isFalse);

    expect(notifier.toggleFollow('@studio.nova'), isTrue);
    expect(
      container.read(engagementProvider).isFollowing('@studio.nova'),
      isTrue,
    );
  });
}
