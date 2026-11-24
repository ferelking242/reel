import '../../../core/utils/formatters.dart';

/// One video of the vertical feed.
///
/// Counters are nullable on purpose: an extension that does not expose likes
/// or comments must not see invented numbers in the UI.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.authorUsername,
    required this.authorAvatar,
    required this.hashtags,
    this.views,
    this.likes,
    this.comments,
    this.shares,
    this.bookmarks,
    this.soundName,
    this.isFollowing = false,
    this.authorVerified = false,
    this.createdAt,
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String authorUsername;
  final String authorAvatar;
  final int? views;
  final int? likes;
  final int? comments;
  final int? shares;
  final int? bookmarks;
  final List<String> hashtags;
  final String? soundName;
  final bool isFollowing;
  final bool authorVerified;
  final DateTime? createdAt;

  bool get hasVideo => videoUrl.isNotEmpty;

  String? get formattedViews => views == null ? null : formatCount(views!);
  String? get formattedLikes => likes == null ? null : formatCount(likes!);
  String? get formattedComments =>
      comments == null ? null : formatCount(comments!);
  String? get formattedShares => shares == null ? null : formatCount(shares!);
  String? get formattedBookmarks =>
      bookmarks == null ? null : formatCount(bookmarks!);

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
      views: views,
      likes: likes,
      comments: comments,
      shares: shares,
      bookmarks: bookmarks,
      hashtags: hashtags,
      soundName: soundName,
      isFollowing: isFollowing ?? this.isFollowing,
      authorVerified: authorVerified,
      createdAt: createdAt,
    );
  }
}
