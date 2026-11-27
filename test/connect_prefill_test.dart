import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/features/connect/connect_screen.dart';
import 'package:reel/remote/remote_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Config that only lands after the first frame, like the real
/// SharedPreferences read.
class _SlowConfigNotifier extends RemoteConfigNotifier {
  @override
  Future<RemoteConfig> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const RemoteConfig(
      baseUrl: 'http://192.168.1.42:4567',
      apiKey: 'secret',
      selectedSourceId: '7',
    );
  }
}

void main() {
  testWidgets('the URL field is filled once the stored config arrives',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      retry: (_, __) => null,
      overrides: [
        remoteConfigProvider.overrideWith(_SlowConfigNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConnectScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(find.text('Serveur connecté'), findsOneWidget);
    expect(find.text('http://192.168.1.42:4567'), findsOneWidget);
  });
}
