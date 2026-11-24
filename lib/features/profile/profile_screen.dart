import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_bottom_nav.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';
import '../feed/providers/feed_provider.dart';
import '../feed/widgets/create_sheet.dart';
import '../feed/widgets/item_sheet.dart';
import 'edit_profile_sheet.dart';
import 'providers/profile_edit_provider.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: ref.read(profileTabProvider),
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    ref.read(profileTabProvider.notifier).select(_tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    _tabs.animateTo(index);
    ref.read(profileTabProvider.notifier).select(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileTabProvider, (previous, next) {
      if (next != _tabs.index) _tabs.animateTo(next);
    });

    final engagement = ref.watch(engagementProvider);
    final feed = ref.watch(profileFeedItemsProvider);
    final saved = ref.watch(profileSavedItemsProvider);
    final liked = ref.watch(profileLikedItemsProvider);

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                following: engagement.followed.length,
                followers: null,
                liked: liked.length,
                onOpenSettings: () => _showSettings(context),
                onOpenFriends: () => context.go('/friends'),
                onOpenLiked: () => _goToTab(2),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabs,
                  indicatorColor: colorTextPrimary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelColor: colorTextPrimary,
                  unselectedLabelColor: colorTextSecondaryDark,
                  tabs: [
                    Tab(text: 'Vidéos ${feed.length}'),
                    Tab(text: 'Favoris ${saved.length}'),
                    Tab(text: 'J\'aime ${liked.length}'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _VideoGrid(
                items: feed,
                emptyIcon: ReelGlyph.play,
                emptyTitle: 'Aucune vidéo',
                emptyMessage:
                    'Les vidéos chargées depuis le serveur apparaissent ici.',
              ),
              _VideoGrid(
                items: saved,
                emptyIcon: ReelGlyph.bookmark,
                emptyTitle: 'Aucun favori',
                emptyMessage:
                    'Enregistre une vidéo avec le signet pour la retrouver ici.',
              ),
              _VideoGrid(
                items: liked,
                emptyIcon: ReelGlyph.heart,
                emptyTitle: 'Aucun like',
                emptyMessage: 'Les vidéos que tu aimes apparaissent ici.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ReelBottomNav(
        currentIndex: 4,
        onSelect: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/friends');
            case 3:
              context.go('/inbox');
          }
        },
        onCreate: () => showCreateSheet(context),
      ),
    );
  }

  void _showSettings(BuildContext context) => context.push('/settings');
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.following,
    required this.followers,
    required this.liked,
    required this.onOpenSettings,
    required this.onOpenFriends,
    required this.onOpenLiked,
  });

  final int following;

  /// Le serveur ne publie pas encore de compteur d'abonnés : `null` affiche
  /// un tiret plutôt qu'un zéro trompeur.
  final int? followers;
  final int liked;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusProvider);
    final profile = ref.watch(profileEditProvider);

    return Column(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.handle,
                    style: AppTokens.titleM.copyWith(color: colorTextPrimary),
                  ),
                  const SizedBox(width: space4),
                  const ReelIcon(
                    ReelGlyph.verified,
                    size: 16,
                    color: colorVerified,
                  ),
                ],
              ),
              const Spacer(),
              Pressable(
                scale: 0.88,
                onTap: () => copyToClipboard(context, 'reel://@toi'),
                semanticLabel: 'Partager le profil',
                child: const Padding(
                  padding: EdgeInsets.all(space8),
                  child: ReelIcon(
                    ReelGlyph.qr,
                    size: 22,
                    color: colorTextPrimary,
                  ),
                ),
              ),
              Pressable(
                scale: 0.88,
                onTap: onOpenSettings,
                semanticLabel: 'Paramètres',
                child: const Padding(
                  padding: EdgeInsets.all(space8),
                  child: ReelIcon(
                    ReelGlyph.more,
                    size: 22,
                    color: colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: space12),
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorBrandCyan, colorBrand, colorBrandPink],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorBgBase,
                  ),
                  child: const ReelAvatar(
                    url: '',
                    size: 88,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Pressable(
                  scale: 0.9,
                  onTap: () => showEditProfileSheet(context),
                  semanticLabel: 'Modifier la photo',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: colorBgElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: ReelIcon(
                        ReelGlyph.plus,
                        size: 14,
                        color: colorTextPrimary,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: space12),
        Center(
          child: Text(
            profile.handle,
            style: AppTokens.titleM.copyWith(
              color: colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: space6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: space40),
            child: Text(
              profile.bio.isNotEmpty
                  ? profile.bio
                  : (status ?? 'Feed vertical · compte local'),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ),
        ),
        if (profile.link.isNotEmpty) ...[
          const SizedBox(height: space6),
          Center(
            child: Pressable(
              scale: 0.96,
              onTap: () => copyToClipboard(context, profile.link),
              semanticLabel: 'Copier le lien du profil',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ReelIcon(
                    ReelGlyph.link,
                    size: 14,
                    color: colorTextSecondaryDark,
                  ),
                  const SizedBox(width: space4),
                  Text(
                    profile.link,
                    style: AppTokens.labelS.copyWith(
                      color: colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showEditProfileSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorTextPrimary,
                    side: const BorderSide(color: colorDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: space10),
                  ),
                  child: Text(
                    'Modifier le profil',
                    style: AppTokens.labelM.copyWith(
                      color: colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: space8),
              SizedBox(
                width: 46,
                height: 38,
                child: OutlinedButton(
                  onPressed: () => copyToClipboard(context, 'reel://@toi'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colorTextPrimary,
                    side: const BorderSide(color: colorDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                  ),
                  child: const ReelIcon(
                    ReelGlyph.share,
                    size: 18,
                    color: colorTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: space8),
              SizedBox(
                width: 46,
                height: 38,
                child: OutlinedButton(
                  onPressed: onOpenLiked,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colorTextPrimary,
                    side: const BorderSide(color: colorDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                  ),
                  child: const ReelIcon(
                    ReelGlyph.bookmark,
                    size: 18,
                    color: colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: space20),
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: following,
                label: 'Abonnements',
                onTap: onOpenFriends,
              ),
            ),
            Expanded(
              child: _Stat(
                value: followers,
                label: 'Abonnés',
                onTap: onOpenFriends,
              ),
            ),
            Expanded(
              child: _Stat(
                value: liked,
                label: 'J\'aime',
                onTap: onOpenLiked,
              ),
            ),
          ],
        ),
        const SizedBox(height: space16),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int? value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      semanticLabel: value == null ? label : '$label : $value',
      child: Column(
        children: [
          Text(
            value == null ? '—' : formatCount(value!),
            style: AppTokens.titleM.copyWith(
              color: colorTextPrimary,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.caption.copyWith(
              color: colorTextSecondaryDark,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: colorBgBase, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid
// ─────────────────────────────────────────────────────────────────────────────

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<FeedItem> items;
  final ReelGlyph emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
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
                child: Center(
                  child: ReelIcon(
                    emptyIcon,
                    size: 26,
                    color: colorTextSecondaryDark,
                  ),
                ),
              ),
              const SizedBox(height: space16),
              Text(
                emptyTitle,
                style: AppTokens.titleS.copyWith(color: colorTextPrimary),
              ),
              const SizedBox(height: space6),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: AppTokens.bodyS.copyWith(
                  color: colorTextSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(space2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTokens.gridGap,
        mainAxisSpacing: AppTokens.gridGap,
        childAspectRatio: 9 / 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Pressable(
          scale: 0.97,
          onTap: () => showItemSheet(context, item: item),
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
                      item.formattedViews ?? item.formattedLikes ?? '—',
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
    );
  }
}
