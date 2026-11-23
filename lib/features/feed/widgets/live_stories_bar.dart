import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/reel_avatar.dart';
import '../models/feed_item.dart';

/// Horizontal strip of creators currently live, built from the feed authors.
class LiveStoriesBar extends StatelessWidget {
  const LiveStoriesBar({
    super.key,
    required this.items,
    this.onSelect,
  });

  final List<FeedItem> items;
  final ValueChanged<FeedItem>? onSelect;

  @override
  Widget build(BuildContext context) {
    final authors = <String, FeedItem>{};
    for (final item in items) {
      authors.putIfAbsent(item.authorUsername, () => item);
    }
    if (authors.isEmpty) return const SizedBox.shrink();

    final entries = authors.values.take(12).toList(growable: false);

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: space12),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: space12),
        itemBuilder: (context, index) {
          final item = entries[index];
          final isLive = index < 2;
          return _StoryTile(
            item: item,
            isLive: isLive,
            onTap: () => onSelect?.call(item),
          );
        },
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.item,
    required this.isLive,
    required this.onTap,
  });

  final FeedItem item;
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ReelAvatar(
                  url: item.authorAvatar,
                  name: item.authorUsername,
                  size: 58,
                  showLiveRing: isLive,
                  borderColor: Colors.white24,
                  borderWidth: isLive ? 0 : 1.5,
                ),
                if (isLive)
                  const Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(child: LiveBadge(compact: true)),
                  ),
              ],
            ),
            const SizedBox(height: space10),
            Text(
              item.authorUsername.replaceFirst('@', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTokens.labelS.copyWith(color: colorTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
