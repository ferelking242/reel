import 'package:watchtower_client/watchtower_client.dart';
import 'package:reel/utils/log/app_file_logger.dart';
import 'package:reel/remote/app_version.dart';
import 'package:reel/remote/json_safe.dart';
import 'package:reel/remote/reel_transport.dart';

/// Adaptateur mince sur [WatchtowerClient] (SDK officiel Watchtower).
///
/// Conserve exactement l'interface de l'ancien [RemoteApiClient] afin que
/// [FeedNotifier] et le reste du code n'aient pas à changer.
///
/// Bénéfices obtenus via le SDK :
/// - Retry exponentiel automatique (300 ms → 600 ms → 1200 ms, max 3 tentatives)
/// - Injection automatique du header auth (`X-Api-Key`)
/// - Timeout configurable par requête
/// - Exceptions typées ([WatchtowerNetworkException], [WatchtowerApiException])
class RemoteApiClient {
  RemoteApiClient({
    required this.baseUrl,
    this.apiKey,
    ReelTransport? transport,
    Duration timeout = const Duration(seconds: 12),
    int maxRetries = 2,
  })  : _transport = transport,
        _client = transport == null
            ? WatchtowerClient(
                url: baseUrl,
                apiKey: apiKey,
                timeout: timeout,
                maxRetries: maxRetries,
              )
            : null;

  final String baseUrl;
  final String? apiKey;
  final WatchtowerClient? _client;
  final ReelTransport? _transport;

  static const _tag = 'RemoteClient';

  /// `true` when [error] means "the server did not answer" rather than "the
  /// server answered with a problem". Those two need different UI: the first
  /// must retry silently, the second must explain itself.
  static bool isNetworkFailure(Object error) {
    if (error is WatchtowerNetworkException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('failed to reach') ||
        text.contains('socketexception') ||
        text.contains('connection refused') ||
        text.contains('connection closed') ||
        text.contains('timed out') ||
        text.contains('timeout') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('clientexception');
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) {
    final transport = _transport;
    if (transport != null) return transport.get(path, query: query);
    return _client!.getRaw(
      path,
      queryParams: <String, String?>{
        for (final e in (query ?? const {}).entries) e.key: e.value,
      },
    );
  }

  // ── Health check ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> ping() async {
    logger.log(_tag, 'GET /api/ping [v${AppVersion.headerValue}]');
    try {
      // getRaw conserve tous les champs (status, version, …)
      return await _get('/api/ping');
    } catch (_) {
      return {'status': 'error'};
    }
  }

  // ── Sources ─────────────────────────────────────────────────────────────────

  /// Retourne la liste brute des sources (List de Map).
  ///
  /// Délègue à [WatchtowerClient.sources.list()] (typé) et reconvertit en
  /// [List<Map<String,dynamic>>] pour ne pas casser [FeedNotifier._resolveSource].
  Future<List<dynamic>> sources() async {
    final payload = await sourcesPayload();
    final list = payload['sources'];
    return list is List ? list : const [];
  }

  /// Full `/api/sources` answer.
  ///
  /// Carries `hiddenNsfw`: the number of active sources the server withholds
  /// because NSFW exposure is off. Showing that count is what turns a blank
  /// feed into an actionable message.
  Future<Map<String, dynamic>> sourcesPayload() async {
    logger.log(_tag, 'GET /api/sources');
    final data = await _get('/api/sources');
    final raw = data['sources'] ?? data['list'] ?? data['data'];
    return {
      'sources': raw is List ? readMapList(raw) : const <Map<String, dynamic>>[],
      'hiddenNsfw': readInt(data['hiddenNsfw']),
    };
  }

  // ── Contenu — via getRaw (conserve TOUS les champs de la réponse) ────────────
  //
  // On passe par client.getRaw() plutôt que par les endpoints typés afin que
  // FeedNotifier._extractItems puisse chercher n'importe quelle clé retournée
  // par le serveur (list, mangas, items, data, results, videos, posts, content…).

  Future<Map<String, dynamic>> popular(String sourceId, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/popular?page=$page');
    return _get('/api/sources/$sourceId/popular', {'page': page.toString()});
  }

  Future<Map<String, dynamic>> latest(String sourceId, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/latest?page=$page');
    return _get('/api/sources/$sourceId/latest', {'page': page.toString()});
  }

  Future<Map<String, dynamic>> search(
      String sourceId, String query, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/search?q=$query&page=$page');
    return _get(
      '/api/sources/$sourceId/search',
      {'q': query, 'page': page.toString()},
    );
  }

  Future<Map<String, dynamic>> detail(
      String sourceId, String itemUrl) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/detail');
    return _get('/api/sources/$sourceId/detail', {'url': itemUrl});
  }

  Future<Map<String, dynamic>> videos(
      String sourceId, String episodeUrl) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/videos');
    return _get('/api/sources/$sourceId/videos', {'url': episodeUrl});
  }

  /// Libère les ressources du client HTTP sous-jacent.
  void dispose() {
    _transport?.close();
    _client?.close();
  }
}
