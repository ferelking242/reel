import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/follow_button.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';
import '../feed/providers/feed_provider.dart';

/// Profile of the creator of a post, opened by swiping the feed to the left.
class CreatorScreen extends ConsumerWidget {
  const CreatorScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedItemsProvider);
    final items = feed.value ?? const <FeedItem>[];
    final videos = items
        .where(
          (item) => item.authorUsername.toLowerCase() == name.toLowerCase(),
        )
        .toList(growable: false);
    final following = ref.watch(engagementProvider).isFollowing(name);
    final avatar = videos.isNotEmpty
        ? videos.first.authorAvatar
        : (items.isNotEmpty ? items.first.authorAvatar : '');
    final likes = videos.fold<int>(
      0,
      (total, item) => total + (item.likes ?? 0),
    );

    return Scaffold(
      backgroundColor: colorBgBase,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colorBgBase,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Pressable(
              scale: 0.9,
              onTap: () => context.pop(),
              semanticLabel: 'Retour',
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.back,
                  size: 26,
                  color: colorTextPrimary,
                ),
              ),
            ),
            title: Text(
              name.startsWith('@') ? name : '@$name',
              style: AppTokens.titleS.copyWith(
                color: colorTextPrimary,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: _CreatorHeader(
              name: name,
              avatar: avatar,
              following: following,
              videoCount: videos.length,
              likes: likes,
              onToggleFollow: () {
                ref.read(engagementProvider.notifier).toggleFollow(name);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(space16, space20, space16, space10),
              child: Row(
                children: [
                  const ReelIcon(
                    ReelGlyph.play,
                    size: 15,
                    color: colorTextPrimary,
                  ),
                  const SizedBox(width: space8),
                  Text(
                    'Vidéos',
                    style: AppTokens.labelM.copyWith(
                      color: colorTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (videos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyCreator(name: name),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(space2),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppTokens.gridGap,
                  mainAxisSpacing: AppTokens.gridGap,
                  childAspectRatio: 9 / 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = videos[index];
                    return Pressable(
                      scale: 0.97,
                      onTap: () => _openInFeed(context, ref, items, item),
                      semanticLabel: item.title,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoThumbnail(
                            url: item.thumbnailUrl,
                            seed: item.id,
                            radius: 0,
                            showPlayIcon: false,
                          ),
                          Positioned(
                            left: space4,
                            bottom: space4,
                            child: Row(
                              children: [
                                const ReelIcon(
                                  ReelGlyph.play,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.formattedViews ??
                                      item.formattedLikes ??
                                      '—',
                                  style: AppTokens.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    shadows: AppTokens.feedTextShadow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: videos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openInFeed(
    BuildContext context,
    WidgetRef ref,
    List<FeedItem> feed,
    FeedItem item,
  ) {
    final index = feed.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      ref.read(currentFeedIndexProvider.notifier).update(index);
      Haptics.tap();
    }
    context.pop();
  }
}

class _CreatorHeader extends StatelessWidget {
  const _CreatorHeader({
    required this.name,
    required this.avatar,
    required this.following,
    required this.videoCount,
    required this.likes,
    required this.onToggleFollow,
  });

  final String name;
  final String avatar;
  final bool following;
  final int videoCount;
  final int likes;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: space16),
      child: Column(
        children: [
          const SizedBox(height: space16),
          ReelAvatar(url: avatar, name: name, size: 96),
          const SizedBox(height: space12),
          Text(
            name.startsWith('@') ? name.substring(1) : name,
            style: AppTokens.titleM.copyWith(color: colorTextPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CreatorStat(value: '$videoCount', label: 'Vidéos'),
              const _StatDivider(),
              _CreatorStat(value: formatCount(likes), label: "J'aime"),
            ],
          ),
          const SizedBox(height: space16),
          SizedBox(
            width: 200,
            child: FollowButton(
              initialFollowing: following,
              onChanged: (value) {
                if (value != following) onToggleFollow();
              },
            ),
          ),
          const SizedBox(height: space8),
        ],
      ),
    );
  }

}

class _CreatorStat extends StatelessWidget {
  const _CreatorStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Text(
            value,
            style: AppTokens.titleS.copyWith(
              color: colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: space2),
          Text(
            label,
            style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: colorDivider,
    );
  }
}

class _EmptyCreator extends StatelessWidget {
  const _EmptyCreator({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: colorBgCard,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.profile,
                  size: 26,
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
            const SizedBox(height: space16),
            Text(
              'Aucune vidéo chargée',
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              'Les vidéos de $name apparaîtront ici dès que la source en '
              'renverra.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
