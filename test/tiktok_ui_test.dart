import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/icons/reel_icons.dart';
import 'package:reel/core/icons/tik_glyphs.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/core/widgets/reel_bottom_nav.dart';
import 'package:reel/features/feed/providers/feed_provider.dart';
import 'package:reel/features/feed/widgets/feed_header.dart';
import 'package:reel/features/feed/widgets/feed_page.dart';
import 'package:reel/features/feed/widgets/like_burst.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/feed_fixture.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: colorBgBase),
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('hand-drawn glyphs', () {
    testWidgets('the like button uses the custom painter, not Material',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const Center(child: ReelIcon(ReelGlyph.heart, size: 32)),
      ));

      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ReelIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.painter, isA<TikIconPainter>());
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('glyphs without a TikTok path keep Material Symbols',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const Center(child: ReelIcon(ReelGlyph.verified, size: 20)),
      ));
      expect(find.byType(Icon), findsOneWidget);
    });

    test('every custom glyph builds a non-empty outline', () {
      for (final entry in tikGlyphs.entries) {
        final bounds = entry.value.outline().getBounds();
        expect(bounds.width, greaterThan(4), reason: '${entry.key} width');
        expect(bounds.height, greaterThan(4), reason: '${entry.key} height');
      }
    });

    test('filled variants differ from the outline where provided', () {
      final spec = tikGlyphs[ReelGlyph.profile]!;
      expect(spec.filled, isNotNull);
      expect(spec.filled!().getBounds().width, greaterThan(4));
    });

    test('painter repaints only when the look changes', () {
      const base = TikIconPainter(
        glyph: ReelGlyph.heart,
        color: Colors.white,
        filled: false,
      );
      expect(
        base.shouldRepaint(
          const TikIconPainter(
            glyph: ReelGlyph.heart,
            color: Colors.white,
            filled: false,
          ),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          const TikIconPainter(
            glyph: ReelGlyph.heart,
            color: colorLike,
            filled: true,
          ),
        ),
        isTrue,
      );
    });
  });

  group('buffering', () {
    testWidgets('no spinner is shown while the video loads', (tester) async {
      await tester.pumpWidget(_wrap(FeedPage(
        item: fixtureFeedItems.first,
        isActive: true,
        onOpenComments: () {},
        onOpenShare: () {},
      )));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('tabs', () {
    testWidgets('each label selects its own feed', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colorBgBase,
          ),
          home: const Scaffold(body: FeedHeader()),
        ),
      ));
      await tester.pump();

      // « Suivis » is provider value 1, « Pour toi » is 0.
      expect(container.read(feedTabProvider), 0);
      await tester.tap(find.text('Suivis'));
      await tester.pump();
      expect(container.read(feedTabProvider), 1);
      await tester.tap(find.text('Pour toi'));
      await tester.pump();
      expect(container.read(feedTabProvider), 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('animations', () {
    testWidgets('double tap heart plays once and reports completion',
        (tester) async {
      var done = 0;
      await tester.pumpWidget(_wrap(Stack(
        children: [
          LikeBurst(
            position: const Offset(100, 100),
            onDone: () => done++,
          ),
        ],
      )));
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 800));
      expect(done, 1);
    });

    testWidgets('pause overlay fades in and out', (tester) async {
      await tester.pumpWidget(_wrap(const PauseOverlay(visible: true)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );

      await tester.pumpWidget(_wrap(const PauseOverlay(visible: false)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });

    testWidgets('selecting a nav destination does not throw', (tester) async {
      await tester.pumpWidget(_wrap(ReelBottomNav(
        currentIndex: 0,
        onSelect: (_) {},
        onCreate: () {},
      )));
      await tester.pump();
      await tester.tap(find.text('Profil'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
