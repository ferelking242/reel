import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/formatters.dart';
import '../../feed/providers/engagement_provider.dart';
import '../../feed/providers/feed_provider.dart';

enum ActivityKind { like, save, follow, comment, system }

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
    this.avatarUrl = '',
    this.itemId,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final DateTime time;
  final String avatarUrl;
  final String? itemId;
}

/// 0 = Tout, 1 = Activité, 2 = Système.
class InboxTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final inboxTabProvider =
    NotifierProvider<InboxTabNotifier, int>(InboxTabNotifier.new);

/// Ids of the entries the user has already seen.
class InboxReadNotifier extends Notifier<Set<String>> {
  static const _prefsKey = 'reel_inbox_seen_ids';

  @override
  Set<String> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final next = {...state, ...ids};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.toList());
  }
}

final inboxReadProvider =
    NotifierProvider<InboxReadNotifier, Set<String>>(InboxReadNotifier.new);

/// Activity derived from what the user actually did on this device.
final activityProvider = Provider<List<ActivityEntry>>((ref) {
  final engagement = ref.watch(engagementProvider);
  final comments = ref.watch(commentsProvider);
  final items = ref.watch(feedItemsProvider).asData?.value ?? const [];

  final entries = <ActivityEntry>[];

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (engagement.liked.contains(item.id)) {
      entries.add(
        ActivityEntry(
          id: 'like-${item.id}',
          kind: ActivityKind.like,
          title: 'Tu as aimé une vidéo',
          subtitle: item.title,
          time: DateTime.now().subtract(Duration(minutes: 6 + i * 7)),
          avatarUrl: item.authorAvatar,
          itemId: item.id,
        ),
      );
    }
    if (engagement.saved.contains(item.id)) {
      entries.add(
        ActivityEntry(
          id: 'save-${item.id}',
          kind: ActivityKind.save,
          title: 'Vidéo ajoutée à tes favoris',
          subtitle: item.title,
          time: DateTime.now().subtract(Duration(minutes: 12 + i * 9)),
          avatarUrl: item.authorAvatar,
          itemId: item.id,
        ),
      );
    }
  }

  for (final author in engagement.followed) {
    entries.add(
      ActivityEntry(
        id: 'follow-$author',
        kind: ActivityKind.follow,
        title: 'Nouvel abonnement',
        subtitle: 'Tu suis $author',
        time: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    );
  }

  final commentEntries = <ActivityEntry>[];
  for (final list in comments.values) {
    for (final comment in list) {
      commentEntries.add(
        ActivityEntry(
          id: 'comment-${comment.id}',
          kind: ActivityKind.comment,
          title: 'Ton commentaire a été publié',
          subtitle: comment.text,
          time: comment.createdAt,
        ),
      );
    }
  }
  commentEntries.sort((a, b) => b.time.compareTo(a.time));
  entries.addAll(commentEntries);

  entries.sort((a, b) => b.time.compareTo(a.time));
  return entries;
});

/// System entries: onboarding and server state.
final systemMessagesProvider = Provider<List<ActivityEntry>>((ref) {
  final status = ref.watch(serverStatusProvider);

  return [
    ActivityEntry(
      id: 'system-welcome',
      kind: ActivityKind.system,
      title: 'Bienvenue sur Reel',
      subtitle:
          'Ton feed, tes favoris et tes commentaires restent sur cet appareil.',
      time: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityEntry(
      id: 'system-server',
      kind: ActivityKind.system,
      title: 'État du serveur',
      subtitle: status ?? 'Aucun serveur connecté pour le moment.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityEntry(
      id: 'system-privacy',
      kind: ActivityKind.system,
      title: 'Confidentialité',
      subtitle:
          'Aucune donnée de navigation n\'est envoyée à un tiers par Reel.',
      time: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
});

/// Entries matching the selected inbox tab.
final visibleActivityProvider = Provider<List<ActivityEntry>>((ref) {
  final tab = ref.watch(inboxTabProvider);
  final activity = ref.watch(activityProvider);
  final system = ref.watch(systemMessagesProvider);
  switch (tab) {
    case 1:
      return activity;
    case 2:
      return system;
    default:
      final all = [...activity, ...system]
        ..sort((a, b) => b.time.compareTo(a.time));
      return all;
  }
});

final unreadInboxProvider = Provider<int>((ref) {
  final seen = ref.watch(inboxReadProvider);
  final entries = [...ref.watch(activityProvider), ...ref.watch(systemMessagesProvider)];
  return max(0, entries.where((e) => !seen.contains(e.id)).length);
});

/// Human label for an activity entry.
String activityTimeLabel(ActivityEntry entry) =>
    formatRelativeTime(entry.time);

/// Convenience for the header counter.
String activitySummary(List<ActivityEntry> entries) =>
    entries.isEmpty ? 'Aucune activité' : '${entries.length} éléments';
