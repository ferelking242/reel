import '../../../core/utils/formatters.dart';

/// One video of the vertical feed.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.authorUsername,
    required this.authorAvatar,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.bookmarks,
    required this.hashtags,
    required this.soundName,
    this.isFollowing = false,
    this.authorVerified = false,
    this.createdAt,
    this.isDemo = false,
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String authorUsername;
  final String authorAvatar;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final List<String> hashtags;
  final String soundName;
  final bool isFollowing;
  final bool authorVerified;
  final DateTime? createdAt;

  /// Demo items use generated posters and never hit the network.
  final bool isDemo;

  bool get hasVideo => videoUrl.isNotEmpty;

  String get formattedLikes => formatCount(likes);
  String get formattedComments => formatCount(comments);
  String get formattedShares => formatCount(shares);
  String get formattedBookmarks => formatCount(bookmarks);

  FeedItem copyWith({
    String? videoUrl,
    String? thumbnailUrl,
    bool? isFollowing,
  }) {
    return FeedItem(
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      likes: likes,
      comments: comments,
      shares: shares,
      bookmarks: bookmarks,
      hashtags: hashtags,
      soundName: soundName,
      isFollowing: isFollowing ?? this.isFollowing,
      authorVerified: authorVerified,
      createdAt: createdAt,
      isDemo: isDemo,
    );
  }
}
