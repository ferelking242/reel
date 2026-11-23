import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/feed_item.dart';
import '../../feed/providers/engagement_provider.dart';
import '../../feed/providers/feed_provider.dart';

/// 0 = Feed, 1 = Favoris, 2 = J'aime.
class ProfileTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final profileTabProvider =
    NotifierProvider<ProfileTabNotifier, int>(ProfileTabNotifier.new);

/// Every item currently loaded in the feed.
final profileFeedItemsProvider = Provider<List<FeedItem>>((ref) {
  return ref.watch(feedItemsProvider).asData?.value ?? const [];
});

/// Items the user saved, newest first.
final profileSavedItemsProvider = Provider<List<FeedItem>>((ref) {
  final engagement = ref.watch(engagementProvider);
  final items = ref.watch(profileFeedItemsProvider);
  return items
      .where((item) => engagement.saved.contains(item.id))
      .toList(growable: false);
});

/// Items the user liked, newest first.
final profileLikedItemsProvider = Provider<List<FeedItem>>((ref) {
  final engagement = ref.watch(engagementProvider);
  final items = ref.watch(profileFeedItemsProvider);
  return items
      .where((item) => engagement.liked.contains(item.id))
      .toList(growable: false);
});

/// Number of comments written on this device.
final profileCommentCountProvider = Provider<int>((ref) {
  final comments = ref.watch(commentsProvider);
  return comments.values.fold<int>(0, (sum, list) => sum + list.length);
});
