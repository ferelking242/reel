import 'dart:convert';

import 'package:flutter/services.dart';

import '../icons/reel_icons.dart';

/// How the persistent navigation is drawn.
enum DockType { bar, centered, floating, edgeToEdge }

/// Whether the dock shows labels under the icons.
enum DockLabels { icon, iconAndLabel }

/// How the active destination is emphasised.
enum DockIndicator { fill, dot, underline, none }

/// Background treatment of the dock.
enum DockElevation { none, border, shadow, blur }

/// One destination of the dock.
class DockItem {
  const DockItem({
    required this.id,
    required this.label,
    required this.glyph,
    this.route,
    this.action,
    this.badge,
  });

  final String id;
  final String label;
  final ReelGlyph glyph;
  final String? route;

  /// `create` opens the capture sheet instead of navigating.
  final String? action;

  /// `unread` asks the host for the inbox counter.
  final String? badge;

  bool get isAction => action != null;

  factory DockItem.fromJson(Map<String, dynamic> json) {
    return DockItem(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      glyph: glyphFromName(json['icon'] as String?),
      route: json['route'] as String?,
      action: json['action'] as String?,
      badge: json['badge'] as String?,
    );
  }
}

/// Dock declaration: what to render, where and how.
class DockConfig {
  const DockConfig({
    required this.enabled,
    required this.type,
    required this.height,
    required this.labels,
    required this.activeIndicator,
    required this.elevation,
    required this.margin,
    required this.cornerRadius,
    required this.haptics,
    required this.transparentOnFeed,
    required this.items,
  });

  final bool enabled;
  final DockType type;
  final double height;
  final DockLabels labels;
  final DockIndicator activeIndicator;
  final DockElevation elevation;
  final double margin;
  final double cornerRadius;
  final bool haptics;
  final bool transparentOnFeed;
  final List<DockItem> items;

  bool get showsLabels => labels == DockLabels.iconAndLabel;

  factory DockConfig.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    return DockConfig(
      enabled: json['enabled'] as bool? ?? true,
      type: DockType.values.byName(
        json['type'] as String? ?? DockType.bar.name,
      ),
      height: (json['height'] as num?)?.toDouble() ?? 52,
      labels: _labelsFrom(json['labels'] as String?),
      activeIndicator: DockIndicator.values.byName(
        json['activeIndicator'] as String? ?? DockIndicator.fill.name,
      ),
      elevation: DockElevation.values.byName(
        json['elevation'] as String? ?? DockElevation.border.name,
      ),
      margin: (json['margin'] as num?)?.toDouble() ?? 16,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 999,
      haptics: json['haptics'] as bool? ?? true,
      transparentOnFeed: json['transparentOnFeed'] as bool? ?? true,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(DockItem.fromJson)
          .toList(growable: false),
    );
  }
}

/// What an extension really supports.
///
/// The same block ships in every `ui-layouts/<slug>.json` of
/// watchtower-extensions. Reel hides an affordance the extension does not
/// declare instead of showing a button that cannot work.
class ExtensionCapabilities {
  const ExtensionCapabilities({
    this.live = true,
    this.views = true,
    this.likes = true,
    this.comments = true,
    this.shares = true,
    this.sounds = true,
    this.download = false,
    this.follow = true,
  });

  final bool live;
  final bool views;
  final bool likes;
  final bool comments;
  final bool shares;
  final bool sounds;
  final bool download;
  final bool follow;

  static const all = ExtensionCapabilities();

  factory ExtensionCapabilities.fromJson(Map<String, dynamic> json) {
    bool read(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return ExtensionCapabilities(
      live: read('live', true),
      views: read('views', true),
      likes: read('likes', true),
      comments: read('comments', true),
      shares: read('shares', true),
      sounds: read('sounds', true),
      download: read('download', false),
      follow: read('follow', true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExtensionCapabilities &&
      other.live == live &&
      other.views == views &&
      other.likes == likes &&
      other.comments == comments &&
      other.shares == shares &&
      other.sounds == sounds &&
      other.download == download &&
      other.follow == follow;

  @override
  int get hashCode =>
      Object.hash(live, views, likes, comments, shares, sounds, download, follow);
}

/// Which host screen draws the extension.
enum ReelRenderer {
  /// Reel owns the whole shell (vertical feed).
  reel,

  /// Watchtower's own home/browse screens.
  watch;

  static ReelRenderer fromName(String? name) => switch (name) {
        'reel' => ReelRenderer.reel,
        'watch' || null => ReelRenderer.watch,
        _ => throw FormatException('Unknown renderer: $name'),
      };
}

/// Declarative UI contract loaded from `assets/contract.json`.
///
/// Same spirit as the `ui-layouts/*.json` files of watchtower-extensions, with
/// the shell and player sections added. Every accessor falls back to a sane
/// default so a missing or partial file never breaks the app.
class UiContract {
  const UiContract({
    required this.schemaVersion,
    required this.id,
    required this.dock,
    required this.playerAutoplay,
    required this.playerLoop,
    required this.playerMuted,
    this.renderer = ReelRenderer.reel,
    this.capabilities = ExtensionCapabilities.all,
  });

  static const assetPath = 'assets/contract.json';

  final int schemaVersion;
  final String id;
  final DockConfig dock;
  final bool playerAutoplay;
  final bool playerLoop;
  final bool playerMuted;
  final ReelRenderer renderer;
  final ExtensionCapabilities capabilities;

  static const fallback = UiContract(
    schemaVersion: 1,
    id: 'fallback',
    dock: DockConfig(
      enabled: true,
      type: DockType.bar,
      height: 52,
      labels: DockLabels.iconAndLabel,
      activeIndicator: DockIndicator.fill,
      elevation: DockElevation.border,
      margin: 16,
      cornerRadius: 999,
      haptics: true,
      transparentOnFeed: true,
      items: [
        DockItem(id: 'home', label: 'Accueil', glyph: ReelGlyph.home, route: '/'),
        DockItem(
          id: 'friends',
          label: 'Amis',
          glyph: ReelGlyph.friends,
          route: '/friends',
        ),
        DockItem(
          id: 'create',
          label: 'Créer',
          glyph: ReelGlyph.plus,
          action: 'create',
        ),
        DockItem(
          id: 'inbox',
          label: 'Boîte',
          glyph: ReelGlyph.inbox,
          route: '/inbox',
          badge: 'unread',
        ),
        DockItem(
          id: 'profile',
          label: 'Profil',
          glyph: ReelGlyph.profile,
          route: '/profile',
        ),
      ],
    ),
    playerAutoplay: true,
    playerLoop: true,
    playerMuted: false,
  );

  factory UiContract.fromJson(Map<String, dynamic> json) {
    final shell = json['shell'] as Map<String, dynamic>? ?? const {};
    final dockJson = shell['dock'] as Map<String, dynamic>?;
    final screens = json['screens'] as Map<String, dynamic>? ?? const {};
    final feed = screens['feed'] as Map<String, dynamic>? ?? const {};
    final player = {
      ...?json['player'] as Map<String, dynamic>?,
      ...?feed['player'] as Map<String, dynamic>?,
    };

    final parsedDock = dockJson == null
        ? fallback.dock
        : DockConfig.fromJson(dockJson);

    final capabilitiesJson = json['capabilities'] as Map<String, dynamic>?;

    return UiContract(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      id: json['id'] as String? ?? 'unnamed',
      dock: parsedDock.items.isEmpty ? fallback.dock : parsedDock,
      playerAutoplay: player['autoplay'] as bool? ?? true,
      playerLoop: player['loop'] as bool? ?? true,
      playerMuted: player['muted'] as bool? ?? false,
      renderer: ReelRenderer.fromName(json['renderer'] as String?),
      capabilities: capabilitiesJson == null
          ? ExtensionCapabilities.all
          : ExtensionCapabilities.fromJson(capabilitiesJson),
    );
  }

  static UiContract parse(String source) =>
      UiContract.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Loads [assetPath] and falls back to [fallback] when it is missing or
  /// malformed, so a broken contract never takes the app down.
  static Future<UiContract> load() async {
    try {
      return parse(await rootBundle.loadString(assetPath));
    } catch (_) {
      return fallback;
    }
  }
}

DockLabels _labelsFrom(String? name) {
  switch (name) {
    case null:
      return DockLabels.iconAndLabel;
    case 'icon':
      return DockLabels.icon;
    case 'icon+label':
    case 'iconAndLabel':
    case 'label':
      return DockLabels.iconAndLabel;
    default:
      throw FormatException('Unknown dock labels: $name');
  }
}

const _glyphNames = <String, ReelGlyph>{
  'heart': ReelGlyph.heart,
  'comment': ReelGlyph.comment,
  'bookmark': ReelGlyph.bookmark,
  'share': ReelGlyph.share,
  'music': ReelGlyph.music,
  'mic': ReelGlyph.mic,
  'home': ReelGlyph.home,
  'friends': ReelGlyph.friends,
  'inbox': ReelGlyph.inbox,
  'profile': ReelGlyph.profile,
  'plus': ReelGlyph.plus,
  'search': ReelGlyph.search,
  'verified': ReelGlyph.verified,
  'play': ReelGlyph.play,
  'pause': ReelGlyph.pause,
  'mute': ReelGlyph.mute,
  'volume': ReelGlyph.volume,
  'camera': ReelGlyph.camera,
  'effects': ReelGlyph.effects,
  'more': ReelGlyph.more,
  'close': ReelGlyph.close,
  'back': ReelGlyph.back,
  'chevronRight': ReelGlyph.chevronRight,
  'chevronDown': ReelGlyph.chevronDown,
  'clock': ReelGlyph.clock,
  'trash': ReelGlyph.trash,
  'trend': ReelGlyph.trend,
  'send': ReelGlyph.send,
  'emoji': ReelGlyph.emoji,
  'grid': ReelGlyph.grid,
  'settings': ReelGlyph.settings,
  'link': ReelGlyph.link,
  'check': ReelGlyph.check,
  'warning': ReelGlyph.warning,
  'refresh': ReelGlyph.refresh,
  'live': ReelGlyph.live,
};

/// Maps a contract icon name to a [ReelGlyph]; unknown names fall back to the
/// neutral `grid` glyph so a typo never hides a destination.
ReelGlyph glyphFromName(String? name) => _glyphNames[name] ?? ReelGlyph.grid;

/// Icon names the contract may use. Kept for validation tests.
Set<String> get contractGlyphNames => _glyphNames.keys.toSet();
