import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reel/core/host/reel_host.dart';
import 'package:reel/remote/remote_client.dart';

const _kBaseUrl        = 'wt_real_server_url';
const _kApiKey         = 'wt_real_api_key';
const _kSelectedSource = 'wt_real_source_id';

/// Normalises a server address typed by the user.
///
/// Accepts `192.168.1.184:4567`, `http://host:4567/`, `https://x.lhr.life/api`
/// or a full link with `?key=…` and returns the bare origin
/// (`http://192.168.1.184:4567`). The API key found in the query is returned
/// separately so it can populate the key field.
({String url, String? apiKey}) parseServerInput(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return (url: '', apiKey: null);

  if (!text.startsWith('http://') && !text.startsWith('https://')) {
    text = 'http://$text';
  }

  Uri? uri = Uri.tryParse(text);
  String? apiKey;
  if (uri != null) {
    apiKey = uri.queryParameters['key'] ?? uri.queryParameters['api_key'];
    final origin = uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
    // Keep a deployment sub-path (e.g. https://host/wt) but drop `/api`.
    var path = uri.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path.endsWith('/api')) {
      path = path.substring(0, path.length - 4);
    }
    return (url: '$origin$path', apiKey: apiKey);
  }

  text = text.replaceAll(RegExp(r'/+$'), '');
  if (text.endsWith('/api')) text = text.substring(0, text.length - 4);
  return (url: text, apiKey: null);
}

/// Source ID par défaut — vide, l'utilisateur choisit après connexion.
const kDefaultSourceId = '';

class RemoteConfig {
  const RemoteConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.selectedSourceId = kDefaultSourceId,
  });
  final String baseUrl;
  final String apiKey;
  final String selectedSourceId;
  bool get isConfigured => baseUrl.isNotEmpty;
}

class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() async {
    final host = ref.watch(reelHostProvider);
    if (host != null) {
      return RemoteConfig(
        baseUrl: 'host://local',
        selectedSourceId: host.sourceId,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    return RemoteConfig(
      baseUrl:          prefs.getString(_kBaseUrl)        ?? '',
      apiKey:           prefs.getString(_kApiKey)         ?? '',
      selectedSourceId: prefs.getString(_kSelectedSource) ?? kDefaultSourceId,
    );
  }

  Future<void> save({
    required String baseUrl,
    required String apiKey,
    String? selectedSourceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl);
    await prefs.setString(_kApiKey,  apiKey);
    if (selectedSourceId != null) {
      await prefs.setString(_kSelectedSource, selectedSourceId);
    }
    state = AsyncData(RemoteConfig(
      baseUrl:          baseUrl,
      apiKey:           apiKey,
      selectedSourceId: selectedSourceId ??
          (state.asData?.value.selectedSourceId ?? kDefaultSourceId),
    ));
  }
}

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig>(
        RemoteConfigNotifier.new);

final remoteClientProvider = Provider<RemoteApiClient?>((ref) {
  final host = ref.watch(reelHostProvider);
  if (host != null) {
    final client = RemoteApiClient(
      baseUrl: 'host://local',
      transport: host.transport,
    );
    ref.onDispose(client.dispose);
    return client;
  }
  final config = ref.watch(remoteConfigProvider).asData?.value;
  if (config == null || !config.isConfigured) return null;
  final client = RemoteApiClient(baseUrl: config.baseUrl, apiKey: config.apiKey);
  ref.onDispose(client.dispose);
  return client;
});
