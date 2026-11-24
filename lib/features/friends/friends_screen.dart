import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_bottom_nav.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';
import '../feed/providers/feed_provider.dart';
import '../feed/widgets/create_sheet.dart';
import '../feed/widgets/item_sheet.dart';

class _Creator {
  const _Creator({
    required this.username,
    required this.avatar,
    required this.verified,
    required this.videos,
    required this.item,
  });

  final String username;
  final String avatar;
  final bool verified;
  final List<FeedItem> videos;
  final FeedItem item;
}

class _FriendsTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final _friendsTabProvider =
    NotifierProvider<_FriendsTabNotifier, int>(_FriendsTabNotifier.new);

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_friendsTabProvider);
    final engagement = ref.watch(engagementProvider);
    final items = ref.watch(feedItemsProvider).asData?.value ?? const [];

    final byAuthor = <String, List<FeedItem>>{};
    for (final item in items) {
      byAuthor.putIfAbsent(item.authorUsername, () => []).add(item);
    }
    final creators = byAuthor.entries
        .map(
          (entry) => _Creator(
            username: entry.key,
            avatar: entry.value.first.authorAvatar,
            verified: entry.value.any((v) => v.authorVerified),
            videos: entry.value,
            item: entry.value.first,
          ),
        )
        .where(
          (creator) =>
              _filter.isEmpty ||
              creator.username.toLowerCase().contains(_filter.toLowerCase()),
        )
        .toList(growable: false);

    final followed =
        creators.where((c) => engagement.isFollowing(c.username)).toList();
    final suggestions =
        creators.where((c) => !engagement.isFollowing(c.username)).toList();
    final visible = tab == 0 ? suggestions : followed;

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, space8, gutter, 0),
              child: Text(
                'Amis',
                style: AppTokens.titleM.copyWith(color: colorTextPrimary),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(gutter, space12, gutter, space8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: colorBgCard,
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: space12),
                    const ReelIcon(
                      ReelGlyph.search,
                      size: 18,
                      color: colorTextSecondaryDark,
                    ),
                    const SizedBox(width: space8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _filter = value),
                        style: AppTokens.bodyS.copyWith(
                          color: colorTextPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un créateur',
                          hintStyle: AppTokens.bodyS.copyWith(
                            color: colorTextSecondaryDark,
                            fontSize: 14,
                          ),
                          filled: false,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_filter.isNotEmpty)
                      Pressable(
                        scale: 0.85,
                        onTap: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: space8),
                          child: ReelIcon(
                            ReelGlyph.close,
                            size: 14,
                            color: colorTextSecondaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(gutter, space4, gutter, space12),
              child: _SegmentedTabs(
                selected: tab,
                labels: [
                  'Suggestions (${suggestions.length})',
                  'Abonnements (${followed.length})',
                ],
                onSelect: (index) =>
                    ref.read(_friendsTabProvider.notifier).select(index),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _FriendsEmpty(tab: tab)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        gutter,
                        0,
                        gutter,
                        space32,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: space8,
                        crossAxisSpacing: space8,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final creator = visible[index];
                        return StaggeredEntrance(
                          index: index,
                          child: _CreatorCard(
                            creator: creator,
                            following: engagement.isFollowing(
                              creator.username,
                            ),
                            onOpen: () =>
                                showItemSheet(context, item: creator.item),
                            onToggleFollow: () {
                              ref
                                  .read(engagementProvider.notifier)
                                  .toggleFollow(creator.username);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReelBottomNav(
        currentIndex: 1,
        onSelect: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 3:
              context.go('/inbox');
            case 4:
              context.go('/profile');
          }
        },
        onCreate: () => showCreateSheet(context),
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.creator,
    required this.following,
    required this.onOpen,
    required this.onToggleFollow,
  });

  final _Creator creator;
  final bool following;
  final VoidCallback onOpen;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final views = creator.videos.fold<int>(
      0,
      (sum, item) => sum + (item.views ?? item.likes ?? 0),
    );

    return Pressable(
      scale: 0.96,
      onTap: onOpen,
      semanticLabel: 'Ouvrir ${creator.username}',
      child: Container(
        decoration: BoxDecoration(
          color: colorBgCard,
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        padding: const EdgeInsets.all(space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AvatarRing(
              creator: creator,
              following: following,
              onToggleFollow: onToggleFollow,
            ),
            const SizedBox(height: space8),
            Text(
              creator.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.labelM.copyWith(
                color: colorTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${formatCount(views)} j\'aime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.caption.copyWith(
                color: colorTextSecondaryDark,
              ),
            ),
            const SizedBox(height: space8),
            _FollowPill(
              following: following,
              onTap: onToggleFollow,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar with the cyan/pink ring TikTok uses for creators you have not
/// followed yet; the ring turns grey once you are subscribed.
class _AvatarRing extends StatelessWidget {
  const _AvatarRing({
    required this.creator,
    required this.following,
    required this.onToggleFollow,
  });

  final _Creator creator;
  final bool following;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleFollow,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: following
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorBrandCyan, colorBrand],
                ),
          color: following ? colorBgElevated : null,
        ),
        child: ReelAvatar(
          url: creator.avatar,
          name: creator.username,
          size: 54,
          showVerified: creator.verified,
        ),
      ),
    );
  }
}

class _FollowPill extends StatelessWidget {
  const _FollowPill({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: durationNormal,
        curve: ReelCurves.emphasized,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: space10),
        decoration: BoxDecoration(
          color: following ? colorBgElevated : colorBrand,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReelIcon(
              following ? ReelGlyph.check : ReelGlyph.plus,
              size: 13,
              color: following ? colorTextSecondary : Colors.white,
              strokeWidth: 2.6,
            ),
            const SizedBox(width: 3),
            Text(
              following ? 'Abonné' : 'Suivre',
              style: AppTokens.caption.copyWith(
                color: following ? colorTextSecondary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: durationNormal,
                  curve: ReelCurves.emphasized,
                  decoration: BoxDecoration(
                    color: selected == i
                        ? colorBgElevated
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(radiusPill),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.labelM.copyWith(
                        color: selected == i
                            ? colorTextPrimary
                            : colorTextSecondaryDark,
                        fontWeight: selected == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendsEmpty extends StatelessWidget {
  const _FriendsEmpty({required this.tab});

  final int tab;

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
                  ReelGlyph.friends,
                  size: 26,
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
            const SizedBox(height: space16),
            Text(
              tab == 0 ? 'Aucune suggestion' : 'Aucun abonnement',
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              tab == 0
                  ? 'Les créateurs du feed apparaissent ici.'
                  : 'Suis un créateur depuis le feed pour le retrouver ici.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
