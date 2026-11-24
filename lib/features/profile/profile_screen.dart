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
import '../../remote/remote_config_provider.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';
import '../feed/providers/feed_provider.dart';
import '../feed/widgets/create_sheet.dart';
import '../feed/widgets/item_sheet.dart';
import '../search/providers/search_provider.dart';
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
                  tabs: const [
                    Tab(text: 'Vidéos'),
                    Tab(text: 'Favoris'),
                    Tab(text: 'J\'aime'),
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

  void _showSettings(BuildContext context) {
    showReelSheet<void>(
      context,
      builder: (_) => const _SettingsSheet(),
    );
  }
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
              Text(
                'Profil',
                style: AppTokens.titleM.copyWith(color: colorTextPrimary),
              ),
              const Spacer(),
              Pressable(
                scale: 0.88,
                onTap: onOpenSettings,
                semanticLabel: 'Paramètres',
                child: const Padding(
                  padding: EdgeInsets.all(space8),
                  child: ReelIcon(
                    ReelGlyph.settings,
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
                  onTap: () => showReelToast(
                    context,
                    'La modification du profil arrive bientôt',
                    icon: ReelGlyph.profile,
                  ),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@toi',
                style: AppTokens.titleM.copyWith(color: colorTextPrimary),
              ),
              const SizedBox(width: space6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: space6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorBgCard,
                  borderRadius: BorderRadius.circular(radiusSm),
                ),
                child: Text(
                  'local',
                  style: AppTokens.caption.copyWith(
                    color: colorTextSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: space4),
        Center(
          child: Text(
            status ?? 'Compte local · aucune donnée envoyée',
            style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
          ),
        ),
        const SizedBox(height: space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showReelToast(
                    context,
                    'La modification du profil arrive bientôt',
                    icon: ReelGlyph.profile,
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigProvider).asData?.value;
    final muted = ref.watch(feedMutedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(gutter, space4, gutter, space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: AppTokens.titleM.copyWith(color: colorTextPrimary),
          ),
          const SizedBox(height: space16),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: ReelGlyph.settings,
                title: 'Serveur Watchtower',
                subtitle: config == null || config.baseUrl.isEmpty
                    ? 'Non configuré'
                    : config.baseUrl,
                onTap: () {
                  Navigator.of(context).maybePop();
                  context.push('/connect');
                },
              ),
              _SettingsTile(
                icon: ReelGlyph.grid,
                title: 'Source active',
                subtitle: (config?.selectedSourceId.isNotEmpty ?? false)
                    ? config!.selectedSourceId
                    : 'Automatique',
                onTap: () {
                  Navigator.of(context).maybePop();
                  context.push('/connect');
                },
              ),
            ],
          ),
          const SizedBox(height: space12),
          _SettingsGroup(
            children: [
              SwitchListTile.adaptive(
                value: !muted,
                onChanged: (_) => ref.read(feedMutedProvider.notifier).toggle(),
                title: Text(
                  'Son du feed',
                  style: AppTokens.bodyS.copyWith(color: colorTextPrimary),
                ),
                subtitle: Text(
                  'Lecture avec audio au démarrage',
                  style: AppTokens.labelS.copyWith(
                    color: colorTextSecondaryDark,
                  ),
                ),
                activeTrackColor: colorBrand,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: space16,
                ),
              ),
            ],
          ),
          const SizedBox(height: space12),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: ReelGlyph.trash,
                title: 'Effacer mes données locales',
                subtitle: 'Likes, favoris, abonnements, commentaires',
                destructive: true,
                onTap: () => _confirmClear(context, ref),
              ),
              _SettingsTile(
                icon: ReelGlyph.warning,
                title: 'À propos de Reel',
                subtitle: 'Version 1.0.0 · Watchtower SDK',
                onTap: () => showReelToast(
                  context,
                  'Reel 1.0.0 — UI inspirée des feeds verticaux modernes',
                  icon: ReelGlyph.effects,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBgElevated,
        title: Text(
          'Effacer les données locales ?',
          style: AppTokens.titleS.copyWith(color: colorTextPrimary),
        ),
        content: Text(
          'Tes likes, favoris, abonnements, commentaires et recherches seront supprimés de cet appareil.',
          style: AppTokens.bodyS.copyWith(color: colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Annuler',
              style: AppTokens.labelM.copyWith(color: colorTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Effacer',
              style: AppTokens.labelM.copyWith(
                color: colorBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(engagementProvider.notifier).clearAll();
    await ref.read(commentsProvider.notifier).clearAll();
    ref.read(searchHistoryProvider.notifier).clear();
    ref.read(hiddenItemsProvider.notifier).clear();
    if (!context.mounted) return;
    showReelToast(context, 'Données locales effacées');
    Navigator.of(context).maybePop();
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final ReelGlyph icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: space16),
      leading: ReelIcon(
        icon,
        size: 20,
        color: destructive ? colorBrand : colorTextSecondary,
      ),
      title: Text(
        title,
        style: AppTokens.bodyS.copyWith(
          color: destructive ? colorBrand : colorTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
