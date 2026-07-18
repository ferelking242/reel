/// Centralise la configuration ntfy.sh.
/// Change [ntfyTopic] pour rediriger tous les logs de l'app.
class NtfyConfig {
  /// Topic ntfy.sh où tous les logs sont envoyés.
  /// Subscribe sur https://ntfy.sh/watchtower-real (ou l'app ntfy)
  static const String topic = 'https://ntfy.sh/watchtower-real';

  /// Préfixe du titre affiché sur les notifications.
  static const String appName = 'Watchtower Real';
}
