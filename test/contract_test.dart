import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/contract/contract_provider.dart';
import 'package:reel/core/contract/ui_contract.dart';
import 'package:reel/core/icons/reel_icons.dart';
import 'package:reel/core/widgets/reel_bottom_nav.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped contract parses and describes the shell', () async {
    final contract = UiContract.parse(
      await rootBundle.loadString(UiContract.assetPath),
    );

    expect(contract.schemaVersion, greaterThanOrEqualTo(1));
    expect(contract.id, isNotEmpty);
    expect(contract.dock.enabled, isTrue);
    expect(contract.dock.items, hasLength(5));
    expect(contract.dock.items.map((item) => item.id).toSet(), hasLength(5));

    for (final item in contract.dock.items) {
      expect(contractGlyphNames, contains(item.glyph.name));
      expect(item.route != null || item.action != null, isTrue,
          reason: '${item.id} must navigate or trigger an action');
    }

    final create = contract.dock.items.singleWhere((item) => item.id == 'create');
    expect(create.isAction, isTrue);
    expect(contract.dock.items.any((item) => item.badge == 'unread'), isTrue);
  });

  test('unknown icon names fall back to the neutral glyph', () {
    expect(glyphFromName('does-not-exist'), ReelGlyph.grid);
    expect(glyphFromName(null), ReelGlyph.grid);
    expect(glyphFromName('live'), ReelGlyph.live);
  });

  test('a contract without a dock keeps the fallback destinations', () {
    final contract = UiContract.parse(jsonEncode({'schemaVersion': 1}));
    expect(contract.dock.items, UiContract.fallback.dock.items);
    expect(contract.playerAutoplay, isTrue);
  });

  test('malformed JSON is rejected before it can reach the UI', () {
    expect(() => UiContract.parse('{not json'), throwsFormatException);
  });

  testWidgets('the dock follows the contract layout', (tester) async {
    final contract = UiContract.parse(jsonEncode({
      'schemaVersion': 1,
      'shell': {
        'dock': {
          'enabled': true,
          'type': 'floating',
          'labels': 'icon',
          'activeIndicator': 'dot',
          'items': [
            {'id': 'home', 'label': 'Accueil', 'icon': 'home', 'route': '/'},
            {'id': 'create', 'label': 'Créer', 'icon': 'plus', 'action': 'create'},
            {'id': 'profile', 'label': 'Profil', 'icon': 'profile', 'route': '/profile'},
          ],
        },
      },
    }));

    await tester.pumpWidget(ProviderScope(
      overrides: [uiContractProvider.overrideWith((ref) async => contract)],
      child: MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ReelBottomNav(
            currentIndex: 0,
            onSelect: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ReelIcon && widget.glyph == ReelGlyph.home,
      ),
      findsOneWidget,
    );
  });
}
