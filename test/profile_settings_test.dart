import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/features/feed/providers/engagement_provider.dart';
import 'package:reel/features/profile/edit_profile_sheet.dart';
import 'package:reel/features/profile/providers/profile_edit_provider.dart';
import 'package:reel/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: AppTokens.fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: colorBgBase,
      ),
      home: child,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings toggles the feed audio and clears the cache',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _host(const SettingsScreen(), container),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Paramètres et confidentialité'), findsOneWidget);
    expect(find.text('Serveur Watchtower'), findsOneWidget);

    final mutedBefore = container.read(feedMutedProvider);
    await tester.tap(find.text('Son du feed'));
    await tester.pump();
    expect(container.read(feedMutedProvider), !mutedBefore);

    await tester.tap(find.text("Vider le cache d'images"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Le cache était déjà vide'), findsOneWidget);
  });

  testWidgets('edit profile sheet stores the local identity', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showEditProfileSheet(context),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
        container,
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'nova');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(container.read(profileEditProvider).handle, 'nova');
  });
}
