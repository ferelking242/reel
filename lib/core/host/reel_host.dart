import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../remote/reel_transport.dart';
import '../contract/ui_contract.dart';

/// Context injected by a host application that embeds Reel.
///
/// Reel ships as its own app (own `main.dart`, own tests, own releases). The
/// Watchtower app mounts the very same code through this seam instead of
/// duplicating it: the host supplies the extension to display, a
/// [ReelTransport] that answers the Watchtower API paths locally, and the
/// contract parsed from the extension's `ui-layouts/<slug>.json`.
class ReelHost {
  const ReelHost({
    required this.sourceId,
    required this.sourceName,
    required this.transport,
    this.contract,
    this.onExit,
    this.initialTab = 0,
  });

  /// Extension id used for every request (`/api/sources/<id>/...`).
  final String sourceId;
  final String sourceName;

  /// Local implementation of the Watchtower API surface.
  final ReelTransport transport;

  /// Layout of the extension, already parsed. `null` keeps the bundled asset.
  final UiContract? contract;

  /// Called when the user leaves the embedded feed (back gesture, dock).
  final void Function()? onExit;

  /// Feed tab to open first: 0 = Pour toi, 1 = Suivis, 2 = Explorer.
  final int initialTab;

  ReelHost copyWith({UiContract? contract, void Function()? onExit}) {
    return ReelHost(
      sourceId: sourceId,
      sourceName: sourceName,
      transport: transport,
      contract: contract ?? this.contract,
      onExit: onExit ?? this.onExit,
      initialTab: initialTab,
    );
  }
}

/// `null` when Reel runs standalone (its own `main.dart`).
final reelHostProvider = Provider<ReelHost?>((ref) => null);
