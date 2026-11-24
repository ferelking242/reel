import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_contract.dart';

/// The UI contract of the running build (`assets/contract.json`).
///
/// Widgets read it synchronously through [uiContractValueProvider]: until the
/// asset resolves they get [UiContract.fallback], which mirrors the shipped
/// contract, so the first frame never flickers.
final uiContractProvider = FutureProvider<UiContract>(
  (ref) => UiContract.load(),
);

final uiContractValueProvider = Provider<UiContract>((ref) {
  return ref.watch(uiContractProvider).value ?? UiContract.fallback;
});
