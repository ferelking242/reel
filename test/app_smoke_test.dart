import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reel/app.dart';
import 'package:reel/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('boots into the feed and walks the main tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: ReelApp()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pour toi'), findsWidgets);

    await tester.tap(find.text('Amis'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Amis'), findsWidgets);

    await tester.tap(find.text('Boîte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Boîte de réception'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Modifier le profil'), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pour toi'), findsWidgets);
  });
}
