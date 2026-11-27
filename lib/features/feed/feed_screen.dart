import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/reel_bottom_nav.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/skeletons.dart';
import '../comments/comments_sheet.dart';
import '../inbox/providers/inbox_provider.dart';
import '../share/share_sheet.dart';
import 'models/feed_item.dart';
import 'providers/engagement_provider.dart';
import 'providers/feed_provider.dart';
import 'widgets/create_sheet.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_page.dart';
import 'widgets/live_stories_bar.dart';

/// Number of players kept alive around the visible page.
const int _kPoolRadius = 1;

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Map<int, Player> _pool = {};

  int _index = 0;
  bool _refreshing = false;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      for (final player in _pool.values) {
        player.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final player in _pool.values) {
      player.dispose();
    }
    _pool.clear();
    _pageController.dispose();
    super.dispose();
  }

  /// Creates players for the visible page and its neighbours, disposes the rest.
  void _syncPool(List<FeedItem> items, int index) {
    final wanted = <int>{};
    for (var i = index - _kPoolRadius; i <= index + _kPoolRadius; i++) {
      if (i >= 0 && i < items.length && items[i].hasVideo) wanted.add(i);
    }

    var changed = false;
    for (final key in _pool.keys.toList(growable: false)) {
      if (!wanted.contains(key)) {
        _pool.remove(key)?.dispose();
        changed = true;
      }
    }
    for (final i in wanted) {
      if (!_pool.containsKey(i)) {
        final player = Player();
        player.open(Media(items[i].videoUrl), play: false);
        _pool[i] = player;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  List<FeedItem> _visibleItems(List<FeedItem> items, int tab, Set<String> hidden) {
    final engagement = ref.read(engagementProvider);
    return items.where((item) {
      if (hidden.contains(item.id)) return false;
      if (tab == 1 && !engagement.isFollowing(item.authorUsername)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  Widget _bottomNav({bool transparent = false}) {
    return ReelBottomNav(
      currentIndex: 0,
      transparent: transparent,
      unreadCount: ref.watch(unreadInboxProvider),
      onSelect: (index) {
        switch (index) {
          case 1:
            context.push('/friends');
          case 3:
            context.push('/inbox');
          case 4:
            context.push('/profile');
        }
      },
      onCreate: () => showCreateSheet(context),
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await ref.read(feedItemsProvider.notifier).refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  void _onPageChanged(int index, List<FeedItem> items) {
    setState(() {
      _index = index;
      _showSwipeHint = false;
    });
    ref.read(currentFeedIndexProvider.notifier).update(index);
    _syncPool(items, index);
    if (index >= items.length - 3) {
      ref.read(feedItemsProvider.notifier).loadMore();
    }
  }

  void _openComments(FeedItem item) => showCommentsSheet(context, item: item);

  void _openShare(FeedItem item) => showShareSheet(context, item: item);

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedItemsProvider);
    final tab = ref.watch(feedTabProvider);
    final muted = ref.watch(feedMutedProvider);
    final hidden = ref.watch(hiddenItemsProvider);
    final engagement = ref.watch(engagementProvider);

    // Rebuild the player pool whenever new items arrive.
    ref.listen(feedItemsProvider, (previous, next) {
      final items = next.asData?.value;
      if (items == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final visible = _visibleItems(items, tab, hidden);
        if (visible.isEmpty) return;
        _syncPool(visible, _index.clamp(0, visible.length - 1));
      });
    });

    return Scaffold(
      backgroundColor: colorBgBase,
      extendBody: true,
      body: feedAsync.when(
        loading: () => const _FeedSkeleton(),
        error: (error, _) => _FeedError(
          error: error,
          onRetry: _refresh,
        ),
        data: (allItems) {
          final items = _visibleItems(allItems, tab, hidden);
          if (items.isEmpty) {
            // Le bandeau « Pour toi / Suivis » reste visible : un feed vide ne
            // doit pas faire disparaître la navigation principale.
            return Scaffold(
              backgroundColor: colorBgBase,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const FeedHeader(),
                    Expanded(
                      child: _FeedEmpty(
                        tab: tab,
                        hasServerItems: allItems.isNotEmpty,
                        followedCount: engagement.followed.length,
                        onRetry: _refresh,
                        onExplore: () =>
                            ref.read(feedTabProvider.notifier).update(0),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _bottomNav(),
            );
          }

          final safeIndex = _index.clamp(0, items.length - 1);

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is OverscrollNotification &&
                  notification.overscroll < -60 &&
                  safeIndex == 0) {
                _refresh();
              }
              return false;
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const _FeedScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: (index) => _onPageChanged(index, items),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FeedPage(
                      key: ValueKey(item.id),
                      item: item,
                      player: _pool[index],
                      isActive: safeIndex == index,
                      muted: muted,
                      onOpenComments: () => _openComments(item),
                      onOpenShare: () => _openShare(item),
                    );
                  },
                ),

                // Floating header
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: FeedHeader(),
                  ),
                ),

                // Live creators strip, only on the first page.
                AnimatedPositioned(
                  duration: durationNormal,
                  curve: ReelCurves.emphasized,
                  top: safeIndex == 0 ? 104 : 84,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: safeIndex == 0 ? 1 : 0,
                    duration: durationNormal,
                    child: SafeArea(
                      bottom: false,
                      child: LiveStoriesBar(
                        items: allItems,
                        onSelect: (item) {
                          final target = items.indexOf(item);
                          if (target >= 0) {
                            _pageController.animateToPage(
                              target,
                              duration: durationSlow,
                              curve: ReelCurves.emphasized,
                            );
                          } else {
                            showReelToast(
                              context,
                              '${item.authorUsername} n\'est pas dans ce fil',
                              icon: ReelGlyph.profile,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Pull-to-refresh feedback
                if (_refreshing)
                  const Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(child: _RefreshPill()),
                  ),

                // Swipe hint
                if (_showSwipeHint && items.length > 1 && safeIndex == 0)
                  const Positioned(
                    bottom: 96,
                    left: 0,
                    right: 0,
                    child: Center(child: _SwipeHint()),
                  ),

                // Pagination spinner
                const Positioned(
                  bottom: 88,
                  left: 0,
                  right: 0,
                  child: _LoadingMoreIndicator(),
                ),

                // Bottom navigation
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _bottomNav(transparent: true),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Physics
// ─────────────────────────────────────────────────────────────────────────────

class _FeedScrollPhysics extends ScrollPhysics {
  const _FeedScrollPhysics({super.parent});

  @override
  _FeedScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _FeedScrollPhysics(parent: buildParent(ancestor));

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small overlays
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshPill extends StatelessWidget {
  const _RefreshPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: space12,
        vertical: space6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC1C1C1E),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: colorBrandCyan,
            ),
          ),
          const SizedBox(width: space8),
          Text(
            'Actualisation…',
            style: AppTokens.labelS.copyWith(color: colorTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset =
              reduceMotion ? 0.0 : -6 * Curves.easeInOut.transform(_controller.value);
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ReelIcon(
              ReelGlyph.chevronDown,
              size: 18,
              color: Color(0xCCFFFFFF),
            ),
            Text(
              'Glisse vers le haut',
              style: AppTokens.labelS.copyWith(
                color: const Color(0xCCFFFFFF),
                shadows: AppTokens.feedTextShadow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingMoreIndicator extends ConsumerWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loadingMoreProvider);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: loading ? 1 : 0,
        duration: durationNormal,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    // The shimmer wraps the shapes only: masking the whole screen turned the
    // skeleton into a flat gradient where no placeholder could be seen.
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1C), Color(0xFF0B0B0C)],
            ),
          ),
        ),
        Shimmer(
          baseColor: Color(0xFF232326),
          highlightColor: Color(0xFF3C3C44),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: space16,
                right: space16,
                bottom: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: space10),
                    SkeletonBox(width: 260, height: 12),
                    SizedBox(height: space8),
                    SkeletonBox(width: 200, height: 12),
                    SizedBox(height: space16),
                    SkeletonBox(width: 160, height: 12),
                  ],
                ),
              ),
              Positioned(
                right: space12,
                bottom: 120,
                child: Column(
                  children: [
                    SkeletonBox(width: 50, height: 50, radius: 25),
                    SizedBox(height: space24),
                    SkeletonBox(width: 34, height: 34, radius: 17),
                    SizedBox(height: space24),
                    SkeletonBox(width: 34, height: 34, radius: 17),
                    SizedBox(height: space24),
                    SkeletonBox(width: 34, height: 34, radius: 17),
                    SizedBox(height: space24),
                    SkeletonBox(width: 46, height: 46, radius: 23),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedError extends StatefulWidget {
  const _FeedError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  State<_FeedError> createState() => _FeedErrorState();
}

class _FeedErrorState extends State<_FeedError> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final message =
        error is FeedException ? error.message : 'Une erreur est survenue.';
    final details = error is FeedException
        ? error.details
        : error.toString();

    return _StateScaffold(
      icon: ReelGlyph.warning,
      title: 'Impossible de charger le feed',
      message: message,
      children: [
        if (details != null && details.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _showDetails = !_showDetails),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showDetails ? 'Masquer les détails' : 'Voir les détails',
                  style: AppTokens.labelM.copyWith(color: colorTextSecondary),
                ),
                AnimatedRotation(
                  turns: _showDetails ? 0.5 : 0,
                  duration: durationFast,
                  child: const ReelIcon(
                    ReelGlyph.chevronDown,
                    size: 14,
                    color: colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_showDetails)
            Container(
              margin: const EdgeInsets.only(top: space12),
              padding: const EdgeInsets.all(space12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorBgCard,
                borderRadius: BorderRadius.circular(radiusMd),
              ),
              child: Text(
                details,
                style: AppTokens.labelS.copyWith(
                  color: colorTextSecondary,
                  height: 1.4,
                ),
              ),
            ),
        ],
        const SizedBox(height: space24),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: widget.onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: colorBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: space12),
                ),
                child: Text(
                  'Réessayer',
                  style: AppTokens.titleS.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: space12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/connect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorTextPrimary,
                  side: const BorderSide(color: colorDivider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: space12),
                ),
                child: Text(
                  'Serveur',
                  style: AppTokens.titleS.copyWith(color: colorTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({
    required this.tab,
    required this.hasServerItems,
    required this.followedCount,
    required this.onRetry,
    required this.onExplore,
  });

  final int tab;
  final bool hasServerItems;
  final int followedCount;
  final VoidCallback onRetry;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) {
      return _StateScaffold(
        icon: ReelGlyph.friends,
        title: 'Ton fil « Suivis » est vide',
        message: followedCount == 0
            ? 'Suis des créateurs depuis « Pour toi » pour retrouver leurs vidéos ici.'
            : 'Les créateurs que tu suis n\'ont pas publié récemment.',
        children: [
          const SizedBox(height: space24),
          FilledButton(
            onPressed: onExplore,
            style: FilledButton.styleFrom(
              backgroundColor: colorBrand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: space24,
                vertical: space12,
              ),
            ),
            child: Text(
              'Explorer « Pour toi »',
              style: AppTokens.titleS.copyWith(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return _StateScaffold(
      icon: ReelGlyph.play,
      title: hasServerItems ? 'Rien à afficher' : 'Aucun contenu disponible',
      message: hasServerItems
          ? 'Tout le contenu a été masqué. Réinitialise pour revoir le feed.'
          : 'Configure un serveur Watchtower pour voir du contenu.',
      children: [
        const SizedBox(height: space24),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => context.push('/connect'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: space12),
                ),
                child: Text(
                  'Configurer',
                  style: AppTokens.titleS.copyWith(color: Colors.white),
                ),
              ),
            ),

          ],
        ),
        const SizedBox(height: space8),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Actualiser',
            style: AppTokens.labelM.copyWith(color: colorTextSecondary),
          ),
        ),
      ],
    );
  }
}

class _StateScaffold extends StatelessWidget {
  const _StateScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.children,
  });

  final ReelGlyph icon;
  final String title;
  final String message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: space32),
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
                child: Center(
                  child: ReelIcon(icon, size: 32, color: colorTextSecondary),
                ),
              ),
              const SizedBox(height: space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTokens.titleL.copyWith(color: colorTextPrimary),
              ),
              const SizedBox(height: space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTokens.bodyS.copyWith(
                  color: colorTextSecondary,
                  height: 1.5,
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
