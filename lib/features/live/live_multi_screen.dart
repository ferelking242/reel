import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/live_badge.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/feed_provider.dart';

/// « Direct » tab.
///
/// The Watchtower API does not expose live streams yet, so this page previews
/// the live layout with the creators already present in the feed and states
/// clearly that nothing is actually streaming.
class LiveMultiScreen extends ConsumerWidget {
  const LiveMultiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(feedItemsProvider).asData?.value ?? const [];
    final creators = _uniqueCreators(items);

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(space4, space4, gutter, 0),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: space8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorBgCard,
                      borderRadius: BorderRadius.circular(radiusPill),
                    ),
                    child: Text(
                      'Aperçu',
                      style: AppTokens.caption.copyWith(
                        color: colorTextSecondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: creators.isEmpty
                  ? const _LiveEmpty()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: space32),
                      children: [
                        const _PreviewBanner(),
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
                                '${creators.length} créateurs',
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
                            itemCount: creators.length > 4
                                ? 4
                                : creators.length,
                            itemBuilder: (context, index) {
                              final creator = creators[index];
                              return _LiveTile(
                                item: creator,
                                viewers: 1200 + index * 3400,
                              );
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
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

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
          const ReelIcon(
            ReelGlyph.warning,
            size: 16,
            color: colorWarning,
          ),
          const SizedBox(width: space10),
          Expanded(
            child: Text(
              'Aperçu de l\'interface : l\'API Watchtower ne fournit pas encore de flux en direct.',
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
  const _LiveTile({required this.item, required this.viewers});

  final FeedItem item;
  final int viewers;

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
            Positioned(
              top: space8,
              left: space8,
              child: Row(
                children: [
                  const LiveBadge(compact: true),
                  const SizedBox(width: space6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: space6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(radiusSm),
                    ),
                    child: Row(
                      children: [
                        const ReelIcon(
                          ReelGlyph.profile,
                          size: 9,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          formatCount(viewers),
                          style: AppTokens.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
  const _LiveEmpty();

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
              'Aucun direct pour le moment',
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space8),
            Text(
              'Charge le feed pour voir apparaître les créateurs ici.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
