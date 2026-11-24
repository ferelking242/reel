import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/follow_button.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/skeletons.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../feed/models/feed_item.dart';
import '../feed/widgets/item_sheet.dart';
import 'providers/search_provider.dart';
import 'search_filters_sheet.dart';

/// Result tabs for [query]: top, videos, users, sounds and hashtags.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(widget.query));
    final sort = ref.watch(searchSortProvider);
    final data = resultsAsync.asData?.value;

    return Column(
      children: [
        _ResultsTabBar(
          controller: _tabs,
          query: widget.query,
          results: data,
          onOpenFilters: () => showSearchFiltersSheet(context),
        ),
        Expanded(
          child: resultsAsync.when(
            loading: () => const _ResultsSkeleton(),
            error: (error, _) => _ResultsError(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(searchResultsProvider(widget.query)),
            ),
            data: (results) {
              if (results.isEmpty) {
                return _ResultsEmpty(query: widget.query);
              }
              final sorted = results.sorted(sort);
              return TabBarView(
                controller: _tabs,
                children: [
                  _TopTab(results: sorted),
                  _UsersList(users: sorted.users),
                  _VideosGrid(videos: sorted.videos),
                  _SoundsList(sounds: sorted.sounds),
                  _TagsList(tags: sorted.hashtags),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Result tabs: label, count and an animated underline on the active tab.
class _ResultsTabBar extends StatelessWidget {
  const _ResultsTabBar({
    required this.controller,
    required this.query,
    required this.results,
    required this.onOpenFilters,
  });

  final TabController controller;
  final String query;
  final SearchResults? results;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final r = results;
    final total = r == null
        ? null
        : r.videos.length + r.users.length + r.sounds.length + r.hashtags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: colorTextPrimary, width: 2.5),
            insets: EdgeInsets.symmetric(horizontal: 2),
          ),
          dividerColor: Colors.transparent,
          labelColor: colorTextPrimary,
          unselectedLabelColor: colorTextSecondaryDark,
          labelStyle: AppTokens.titleS.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTokens.titleS.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: space10),
          padding: const EdgeInsets.symmetric(horizontal: space8),
          tabs: const [
            Tab(text: 'Top'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Vidéos'),
            Tab(text: 'Sons'),
            Tab(text: 'Hashtags'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(gutter, space8, space8, space8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  total == null
                      ? 'Résultats pour « $query »'
                      : 'Résultats pour « $query » · $total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.labelS.copyWith(
                    color: colorTextSecondaryDark,
                  ),
                ),
              ),
              Pressable(
                scale: 0.9,
                onTap: onOpenFilters,
                semanticLabel: 'Filtres de recherche',
                child: const Padding(
                  padding: EdgeInsets.all(space8),
                  child: ReelIcon(
                    ReelGlyph.filter,
                    size: 18,
                    color: colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabs content
// ─────────────────────────────────────────────────────────────────────────────

class _TopTab extends StatelessWidget {
  const _TopTab({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: space32),
      children: [
        if (results.users.isNotEmpty) ...[
          const _SectionTitle('Créateurs'),
          _CreatorsRow(users: results.users.take(8).toList()),
        ],
        if (results.videos.isNotEmpty) ...[
          const _SectionTitle('Vidéos populaires'),
          _VideosGrid(
            videos: results.videos.take(9).toList(),
            shrinkWrap: true,
          ),
        ],
        if (results.hashtags.isNotEmpty) ...[
          const _SectionTitle('Hashtags'),
          for (final tag in results.hashtags.take(5))
            _TagTile(tag: tag),
        ],
      ],
    );
  }
}

class _VideosGrid extends StatelessWidget {
  const _VideosGrid({required this.videos, this.shrinkWrap = false});

  final List<FeedItem> videos;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _InlineEmpty(
        icon: ReelGlyph.play,
        message: 'Aucune vidéo pour cette recherche',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(space2),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTokens.gridGap,
        mainAxisSpacing: AppTokens.gridGap,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) => _VideoTile(video: videos[index]),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final FeedItem video;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => showItemSheet(context, item: video),
      semanticLabel: video.title,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoThumbnail(
            url: video.thumbnailUrl,
            radius: radiusSm,
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
                  video.formattedViews ?? video.formattedLikes ?? '—',
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
  }
}

class _CreatorsRow extends StatelessWidget {
  const _CreatorsRow({required this.users});

  final List<SearchUser> users;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: gutter),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: space16),
        itemBuilder: (context, index) {
          final user = users[index];
          return SizedBox(
            width: 76,
            child: Column(
              children: [
                ReelAvatar(
                  url: user.avatar,
                  name: user.username,
                  size: 62,
                  showVerified: user.verified,
                ),
                const SizedBox(height: space8),
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTokens.labelS.copyWith(color: colorTextPrimary),
                ),
                Text(
                  countLabel(user.videos, 'vidéo'),
                  maxLines: 1,
                  style: AppTokens.caption.copyWith(
                    color: colorTextSecondaryDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({required this.users});

  final List<SearchUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _InlineEmpty(
        icon: ReelGlyph.profile,
        message: 'Aucun utilisateur trouvé',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: space8),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: space4),
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: space8,
          ),
          child: Row(
            children: [
              ReelAvatar(
                url: user.avatar,
                name: user.username,
                size: 48,
                showVerified: user.verified,
              ),
              const SizedBox(width: space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: AppTokens.titleS.copyWith(
                        color: colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${countLabel(user.videos, 'vidéo')} · ${formatCount(user.videos * 1200)} vues',
                      style: AppTokens.labelS.copyWith(
                        color: colorTextSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const FollowButton(compact: true),
            ],
          ),
        );
      },
    );
  }
}

class _SoundsList extends StatelessWidget {
  const _SoundsList({required this.sounds});

  final List<SearchSound> sounds;

  @override
  Widget build(BuildContext context) {
    if (sounds.isEmpty) {
      return const _InlineEmpty(
        icon: ReelGlyph.music,
        message: 'Aucun son trouvé',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: space8),
      itemCount: sounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: space4),
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: gutter),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorBgElevated,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: const Center(
              child: ReelIcon(ReelGlyph.music, size: 22),
            ),
          ),
          title: Text(
            sound.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.titleS.copyWith(color: colorTextPrimary),
          ),
          subtitle: Text(
            countLabel(sound.uses, 'vidéo'),
            style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
          ),
          trailing: const ReelIcon(
            ReelGlyph.play,
            size: 18,
            color: colorTextSecondary,
          ),
          onTap: () => showReelToast(
            context,
            sound.name,
            icon: ReelGlyph.music,
          ),
        );
      },
    );
  }
}

class _TagsList extends StatelessWidget {
  const _TagsList({required this.tags});

  final List<SearchTag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const _InlineEmpty(
        icon: ReelGlyph.trend,
        message: 'Aucun hashtag trouvé',
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: space8),
      children: [for (final tag in tags) _TagTile(tag: tag)],
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag});

  final SearchTag tag;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: gutter),
      leading: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: colorBgElevated,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '#',
            style: TextStyle(
              color: colorTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        '#${tag.tag}',
        style: AppTokens.titleS.copyWith(color: colorTextPrimary),
      ),
      subtitle: Text(
        countLabel(tag.videos, 'vidéo'),
        style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
      ),
      trailing: const ReelIcon(
        ReelGlyph.chevronRight,
        size: 16,
        color: colorTextSecondaryDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space20, gutter, space12),
      child: Text(
        title,
        style: AppTokens.titleS.copyWith(color: colorTextPrimary),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});

  final ReelGlyph icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReelIcon(icon, size: 36, color: colorTextSecondaryDark),
            const SizedBox(height: space12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsEmpty extends StatelessWidget {
  const _ResultsEmpty({required this.query});

  final String query;

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
                color: colorBgElevated,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.search,
                  size: 28,
                  color: colorTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: space16),
            Text(
              'Aucun résultat pour « $query »',
              textAlign: TextAlign.center,
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              'Essaie un autre mot-clé ou vérifie la source active.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsError extends StatelessWidget {
  const _ResultsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ReelIcon(
              ReelGlyph.warning,
              size: 32,
              color: colorWarning,
            ),
            const SizedBox(height: space16),
            Text(
              'Recherche indisponible',
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
            const SizedBox(height: space20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: colorDivider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
              ),
              child: Text(
                'Réessayer',
                style: AppTokens.labelM.copyWith(color: colorTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(space2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppTokens.gridGap,
          mainAxisSpacing: AppTokens.gridGap,
          childAspectRatio: 9 / 16,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => const SkeletonBox(radius: radiusSm),
      ),
    );
  }
}
