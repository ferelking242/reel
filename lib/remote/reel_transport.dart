/// Transport used by [RemoteApiClient].
///
/// Reel normally talks HTTP to a Watchtower server. When the app is embedded in
/// the Watchtower Flutter app, that server does not exist: the extensions run
/// locally. The host supplies a [ReelTransport] that answers the same paths
/// (`/api/sources`, `/api/sources/<id>/popular`, …) from its own services, so
/// nothing else in Reel changes.
abstract class ReelTransport {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  });

  void close() {}
}
