import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/reel_avatar.dart';
import '../models/feed_item.dart';

/// Horizontal strip of creators of the feed, with the story ring the reference
/// app draws around them.
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
          return _StoryTile(
            item: item,
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
    required this.onTap,
  });

  final FeedItem item;
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
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    colorBrandCyan,
                    colorBrand,
                    colorBrandPink,
                    colorBrandCyan,
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: colorBgBase,
                  shape: BoxShape.circle,
                ),
                child: ReelAvatar(
                  url: item.authorAvatar,
                  name: item.authorUsername,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: space8),
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
