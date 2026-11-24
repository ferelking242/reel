import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/live_badge.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/feed_provider.dart';

/// « Direct » tab.
///
/// Watchtower does not expose live streams yet, so the page uses the creators
/// of the current feed: their hashtags become the category rail and every tile
/// opens an explanation instead of pretending a stream is running. No viewer
/// count is invented — the API has none.
class LiveMultiScreen extends ConsumerStatefulWidget {
  const LiveMultiScreen({super.key});

  @override
  ConsumerState<LiveMultiScreen> createState() => _LiveMultiScreenState();
}

class _LiveMultiScreenState extends ConsumerState<LiveMultiScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(feedItemsProvider).asData?.value ?? const [];
    final creators = _uniqueCreators(items);
    final categories = _categories(items);
    final visible = _category == null
        ? creators
        : creators
            .where((c) => c.hashtags.contains(_category))
            .toList(growable: false);

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(space4, space4, space8, 0),
              child: Row(
                children: [
                  Pressable(
                    scale: 0.88,
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    semanticLabel: 'Retour',
                    child: const Padding(
                      padding: EdgeInsets.all(space8),
                      child: ReelIcon(
                        ReelGlyph.back,
                        size: 22,
                        color: colorTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: space4),
                  Text(
                    'Direct',
                    style: AppTokens.titleM.copyWith(color: colorTextPrimary),
                  ),
                  const SizedBox(width: space8),
                  const LiveBadge(compact: true),
                  const Spacer(),
                  Pressable(
                    scale: 0.88,
                    onTap: () => context.push('/search'),
                    semanticLabel: 'Rechercher un direct',
                    child: const Padding(
                      padding: EdgeInsets.all(space8),
                      child: ReelIcon(
                        ReelGlyph.search,
                        size: 21,
                        color: colorTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (categories.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: space8),
                  itemBuilder: (context, index) {
                    final value = index == 0 ? null : categories[index - 1];
                    return _CategoryChip(
                      label: value == null ? 'Tout' : '#$value',
                      selected: _category == value,
                      onTap: () => setState(() => _category = value),
                    );
                  },
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? _LiveEmpty(hasFeed: creators.isNotEmpty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: space32),
                      children: [
                        const _ServerNotice(),
                        const SizedBox(height: space16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: gutter,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'En direct maintenant',
                                style: AppTokens.titleS.copyWith(
                                  color: colorTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${visible.length} créateurs',
                                style: AppTokens.labelS.copyWith(
                                  color: colorTextSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: space12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: gutter,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: space10,
                              mainAxisSpacing: space10,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: visible.length > 4 ? 4 : visible.length,
                            itemBuilder: (context, index) {
                              return _LiveTile(item: visible[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: space24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: gutter,
                          ),
                          child: Text(
                            'Créateurs à suivre',
                            style: AppTokens.titleS.copyWith(
                              color: colorTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: space12),
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: gutter,
                            ),
                            itemCount: creators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: space16),
                            itemBuilder: (context, index) {
                              final creator = creators[index];
                              return SizedBox(
                                width: 76,
                                child: Column(
                                  children: [
                                    ReelAvatar(
                                      url: creator.authorAvatar,
                                      name: creator.authorUsername,
                                      size: 62,
                                      showLiveRing: index < 2,
                                    ),
                                    const SizedBox(height: space8),
                                    Text(
                                      creator.authorUsername,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTokens.labelS.copyWith(
                                        color: colorTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FeedItem> _uniqueCreators(List<FeedItem> items) {
    final seen = <String>{};
    final creators = <FeedItem>[];
    for (final item in items) {
      if (seen.add(item.authorUsername)) creators.add(item);
    }
    return creators;
  }

  List<String> _categories(List<FeedItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final tag in item.hashtags) {
        counts.update(tag, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((entry) => entry.key).toList(growable: false);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        decoration: BoxDecoration(
          color: selected ? colorTextPrimary : colorBgCard,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        child: Text(
          label,
          style: AppTokens.labelM.copyWith(
            color: selected ? colorBgBase : colorTextSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ServerNotice extends StatelessWidget {
  const _ServerNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: gutter),
      padding: const EdgeInsets.all(space12),
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReelIcon(ReelGlyph.warning, size: 16, color: colorWarning),
          const SizedBox(width: space10),
          Expanded(
            child: Text(
              'L\'API Watchtower n\'expose pas encore de flux en direct : les tuiles ci-dessous présentent les créateurs du feed.',
              style: AppTokens.labelS.copyWith(
                color: colorTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => showReelToast(
        context,
        'Les directs arrivent avec une prochaine version du serveur',
        icon: ReelGlyph.live,
      ),
      semanticLabel: 'Direct de ${item.authorUsername}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoThumbnail(
              url: item.thumbnailUrl,
              seed: item.id,
              radius: 0,
              showPlayIcon: false,
              aspectRatio: 1,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
            ),
            const Positioned(
              top: space8,
              left: space8,
              child: LiveBadge(compact: true),
            ),
            Positioned(
              left: space8,
              right: space8,
              bottom: space8,
              child: Row(
                children: [
                  ReelAvatar(
                    url: item.authorAvatar,
                    name: item.authorUsername,
                    size: 28,
                    borderColor: Colors.white24,
                    borderWidth: 1,
                  ),
                  const SizedBox(width: space6),
                  Expanded(
                    child: Text(
                      item.authorUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.labelS.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: AppTokens.feedTextShadow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveEmpty extends StatelessWidget {
  const _LiveEmpty({required this.hasFeed});

  final bool hasFeed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: colorBgCard,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.live,
                  size: 30,
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
            const SizedBox(height: space20),
            Text(
              hasFeed ? 'Aucun créateur dans cette catégorie' : 'Aucun direct pour le moment',
              textAlign: TextAlign.center,
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space8),
            Text(
              hasFeed
                  ? 'Choisis une autre catégorie pour voir les créateurs du feed.'
                  : 'Charge le feed pour voir apparaître les créateurs ici.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
