import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLiked = 'reel_liked_items';
const _kSaved = 'reel_saved_items';
const _kFollowed = 'reel_followed_authors';
const _kMuted = 'reel_feed_muted';

/// Immutable engagement state: which items the user liked or saved, and which
/// creators they follow.
class EngagementState {
  const EngagementState({
    this.liked = const {},
    this.saved = const {},
    this.followed = const {},
  });

  final Set<String> liked;
  final Set<String> saved;
  final Set<String> followed;

  bool isLiked(String id) => liked.contains(id);
  bool isSaved(String id) => saved.contains(id);
  bool isFollowing(String author) => followed.contains(author);

  EngagementState copyWith({
    Set<String>? liked,
    Set<String>? saved,
    Set<String>? followed,
  }) {
    return EngagementState(
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      followed: followed ?? this.followed,
    );
  }
}

class EngagementNotifier extends Notifier<EngagementState> {
  @override
  EngagementState build() {
    _restore();
    return const EngagementState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = EngagementState(
      liked: (prefs.getStringList(_kLiked) ?? const []).toSet(),
      saved: (prefs.getStringList(_kSaved) ?? const []).toSet(),
      followed: (prefs.getStringList(_kFollowed) ?? const []).toSet(),
    );
  }

  Future<void> _persist(EngagementState snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kLiked, snapshot.liked.toList());
    await prefs.setStringList(_kSaved, snapshot.saved.toList());
    await prefs.setStringList(_kFollowed, snapshot.followed.toList());
  }

  /// Returns true when the item ends up liked.
  bool toggleLike(String id) {
    final liked = Set<String>.from(state.liked);
    final nowLiked = !liked.remove(id);
    if (nowLiked) liked.add(id);
    state = state.copyWith(liked: liked);
    _persist(state);
    return nowLiked;
  }

  /// Returns true when the item ends up saved.
  bool toggleSave(String id) {
    final saved = Set<String>.from(state.saved);
    final nowSaved = !saved.remove(id);
    if (nowSaved) saved.add(id);
    state = state.copyWith(saved: saved);
    _persist(state);
    return nowSaved;
  }

  Future<void> clearAll() async {
    state = const EngagementState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLiked);
    await prefs.remove(_kSaved);
    await prefs.remove(_kFollowed);
  }

  /// Returns true when the author ends up followed.
  bool toggleFollow(String author) {
    final followed = Set<String>.from(state.followed);
    final nowFollowed = !followed.remove(author);
    if (nowFollowed) followed.add(author);
    state = state.copyWith(followed: followed);
    _persist(state);
    return nowFollowed;
  }
}

final engagementProvider =
    NotifierProvider<EngagementNotifier, EngagementState>(
  EngagementNotifier.new,
);

/// Whether the feed plays with sound.
class FeedMutedNotifier extends Notifier<bool> {
  @override
  bool build() {
    _restore();
    return true;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kMuted) ?? true;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMuted, next);
  }
}

final feedMutedProvider =
    NotifierProvider<FeedMutedNotifier, bool>(FeedMutedNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Local comments
// ─────────────────────────────────────────────────────────────────────────────

/// A comment written from this device.
class LocalComment {
  const LocalComment({
    required this.id,
    required this.itemId,
    required this.text,
    required this.createdAt,
    this.author = 'vous',
    this.likes = 0,
  });

  final String id;
  final String itemId;
  final String text;
  final DateTime createdAt;
  final String author;
  final int likes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'author': author,
        'likes': likes,
      };

  static LocalComment fromJson(Map<String, dynamic> json) => LocalComment(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        author: json['author'] as String? ?? 'vous',
        likes: json['likes'] as int? ?? 0,
      );
}

class CommentsNotifier extends Notifier<Map<String, List<LocalComment>>> {
  static const _prefsKey = 'reel_local_comments';

  @override
  Map<String, List<LocalComment>> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      final restored = <String, List<LocalComment>>{};
      for (final entry in decoded) {
        final comment =
            LocalComment.fromJson(entry as Map<String, dynamic>);
        restored.putIfAbsent(comment.itemId, () => []).add(comment);
      }
      state = restored;
    } catch (_) {
      // Corrupted cache: start fresh instead of crashing the feed.
    }
  }

  Future<void> _persist(Map<String, List<LocalComment>> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final flat = snapshot.values.expand((list) => list).map((c) => c.toJson());
    await prefs.setString(_prefsKey, json.encode(flat.toList()));
  }

  List<LocalComment> forItem(String itemId) => state[itemId] ?? const [];

  void add(String itemId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final comment = LocalComment(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      itemId: itemId,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    state = {
      ...state,
      itemId: [...forItem(itemId), comment],
    };
    _persist(state);
  }

  Future<void> clearAll() async {
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void remove(String itemId, String commentId) {
    final updated = forItem(itemId)
        .where((c) => c.id != commentId)
        .toList(growable: false);
    state = {...state, itemId: updated};
    _persist(state);
  }
}

final commentsProvider =
    NotifierProvider<CommentsNotifier, Map<String, List<LocalComment>>>(
  CommentsNotifier.new,
);

/// Items the user asked not to see again (« Pas intéressé »).
class HiddenItemsNotifier extends Notifier<Set<String>> {
  static const _prefsKey = 'reel_hidden_items';

  @override
  Set<String> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  void hide(String id) {
    state = {...state, id};
    final snapshot = state.toList();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setStringList(_prefsKey, snapshot));
  }

  void clear() {
    state = const {};
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_prefsKey));
  }
}

final hiddenItemsProvider =
    NotifierProvider<HiddenItemsNotifier, Set<String>>(
  HiddenItemsNotifier.new,
);

/// Total number of comments shown for an item (server count + local ones).
final commentCountProvider =
    Provider.family<int, ({String itemId, int baseCount})>((ref, args) {
  final local = ref.watch(commentsProvider)[args.itemId]?.length ?? 0;
  return args.baseCount + local;
});
