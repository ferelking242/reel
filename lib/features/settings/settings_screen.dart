import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../remote/remote_config_provider.dart';
import '../feed/providers/engagement_provider.dart';
import '../search/providers/search_provider.dart';
import '../search/search_filters_sheet.dart';

/// Account, content and storage settings.
///
/// Every row does something real: the toggles drive the feed, the connection
/// rows open the server screen, and the destructive rows ask for confirmation
/// before touching local state.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (!mounted) return;
          setState(() => _version = '${info.version} (${info.buildNumber})');
        })
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigProvider).asData?.value;
    final muted = ref.watch(feedMutedProvider);
    final hosted = config?.baseUrl == 'host://local';

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: colorBgBase,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: Pressable(
                scale: 0.88,
                semanticLabel: 'Retour',
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                child: const Center(
                  child: ReelIcon(
                    ReelGlyph.back,
                    size: 20,
                    color: colorTextPrimary,
                  ),
                ),
              ),
              title: Text(
                'Paramètres et confidentialité',
                style: AppTokens.titleS.copyWith(color: colorTextPrimary),
              ),
              centerTitle: false,
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(gutter, space8, gutter, space32),
              sliver: SliverList.list(
                children: [
                  _Section(
                    title: 'Compte',
                    children: [
                      _SettingsTile(
                        icon: ReelGlyph.profile,
                        title: 'Gérer mon compte',
                        subtitle: 'Profil local, sans inscription',
                        onTap: () => showReelToast(
                          context,
                          'Le compte est stocké sur cet appareil',
                          icon: ReelGlyph.profile,
                        ),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.shield,
                        title: 'Confidentialité',
                        subtitle: 'Aucune donnée envoyée hors de l\'appareil',
                        onTap: () => _showPrivacy(context),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.eye,
                        title: 'Contenu masqué',
                        subtitle: _hiddenSubtitle(),
                        onTap: () => _clearHidden(context),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Contenu et affichage',
                    children: [
                      _SwitchTile(
                        icon: ReelGlyph.volume,
                        title: 'Son du feed',
                        subtitle: 'Lecture avec audio au démarrage',
                        value: !muted,
                        onChanged: (_) =>
                            ref.read(feedMutedProvider.notifier).toggle(),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.filter,
                        title: 'Filtres de recherche',
                        subtitle: _filtersSubtitle(),
                        onTap: () => showSearchFiltersSheet(context),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.darkMode,
                        title: 'Apparence',
                        subtitle: 'Toujours sombre, comme le feed',
                        onTap: () => showReelToast(
                          context,
                          'Le thème sombre suit toujours le feed vidéo',
                          icon: ReelGlyph.darkMode,
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Connexion',
                    children: [
                      _SettingsTile(
                        icon: ReelGlyph.cloud,
                        title: 'Serveur Watchtower',
                        subtitle: hosted
                            ? 'Intégré à l\'application hôte'
                            : (config?.isConfigured ?? false
                                ? config!.baseUrl
                                : 'Non configuré'),
                        onTap: () => context.push('/connect'),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.grid,
                        title: 'Source active',
                        subtitle:
                            (config?.selectedSourceId.isNotEmpty ?? false)
                                ? 'Extension ${config!.selectedSourceId}'
                                : 'Automatique',
                        onTap: () => context.push('/connect'),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.key,
                        title: 'Clé d\'API',
                        subtitle: (config?.apiKey.isNotEmpty ?? false)
                            ? 'Enregistrée sur cet appareil'
                            : 'Aucune clé',
                        onTap: () => context.push('/connect'),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Stockage et cache',
                    children: [
                      _SettingsTile(
                        icon: ReelGlyph.storage,
                        title: 'Vider le cache d\'images',
                        subtitle: _clearing
                            ? 'Nettoyage…'
                            : '${_cachedImageCount()} images en mémoire',
                        onTap: _clearing ? null : _clearImageCache,
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.trash,
                        title: 'Effacer mes données locales',
                        subtitle: 'Likes, favoris, abonnements, commentaires',
                        destructive: true,
                        onTap: () => _confirmClear(context),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'À propos',
                    children: [
                      _SettingsTile(
                        icon: ReelGlyph.info,
                        title: 'Version de Reel',
                        subtitle: _version.isEmpty ? '1.0.0' : _version,
                        onTap: () => showReelToast(
                          context,
                          'Reel ${_version.isEmpty ? '1.0.0' : _version} · '
                              'Watchtower SDK',
                          icon: ReelGlyph.effects,
                        ),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.language,
                        title: 'Licence de la police',
                        subtitle: 'TikTok Sans — SIL Open Font License 1.1',
                        onTap: () => _showLicence(context),
                      ),
                      _SettingsTile(
                        icon: ReelGlyph.help,
                        title: 'Aide et support',
                        subtitle: 'Signaler un problème de lecture',
                        onTap: () => showReelToast(
                          context,
                          'Les journaux de lecture sont dans l\'écran Connexion',
                          icon: ReelGlyph.help,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: space16),
                  Center(
                    child: Text(
                      'Reel · construit sur Watchtower',
                      style: AppTokens.caption.copyWith(
                        color: colorTextSecondaryDark,
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

  int _cachedImageCount() => PaintingBinding.instance.imageCache.liveImageCount;

  String _hiddenSubtitle() {
    final hidden = ref.watch(hiddenItemsProvider).length;
    return hidden == 0 ? 'Aucun contenu masqué' : '$hidden masqué(s)';
  }

  String _filtersSubtitle() {
    final sort = ref.watch(searchSortProvider);
    return switch (sort) {
      SearchSort.recent => 'Tri : plus récents',
      SearchSort.popular => 'Tri : plus populaires',
      SearchSort.relevance => 'Tri : pertinence',
    };
  }

  Future<void> _clearImageCache() async {
    setState(() => _clearing = true);
    final cache = PaintingBinding.instance.imageCache;
    final had = cache.liveImageCount > 0 || cache.currentSizeBytes > 0;
    cache.clear();
    cache.clearLiveImages();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _clearing = false);
    showReelToast(
      context,
      had ? 'Cache d\'images vidé' : 'Le cache était déjà vide',
      icon: ReelGlyph.storage,
    );
  }

  void _clearHidden(BuildContext context) {
    if (ref.read(hiddenItemsProvider).isEmpty) {
      showReelToast(context, 'Aucun contenu masqué', icon: ReelGlyph.eye);
      return;
    }
    ref.read(hiddenItemsProvider.notifier).clear();
    showReelToast(context, 'Contenu masqué restauré', icon: ReelGlyph.eye);
  }

  void _showPrivacy(BuildContext context) {
    showReelSheet<void>(
      context,
      builder: (_) => ReelSheetSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, space32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ReelSheetHeader(title: 'Confidentialité'),
              const SizedBox(height: space12),
              Text(
                'Reel garde tes likes, favoris, abonnements et l\'historique '
                'de recherche sur cet appareil. Seules les requêtes vers '
                'l\'extension Watchtower choisie quittent le téléphone.',
                style: AppTokens.bodyS.copyWith(color: colorTextSecondary),
              ),
              const SizedBox(height: space16),
              const _PrivacyPoint(
                icon: ReelGlyph.lock,
                text: 'Aucun compte, aucun identifiant publicitaire.',
              ),
              const _PrivacyPoint(
                icon: ReelGlyph.cloud,
                text: 'Le serveur ne reçoit que la requête en cours.',
              ),
              const _PrivacyPoint(
                icon: ReelGlyph.shield,
                text: 'Les vidéos sont lues depuis la source, sans proxy.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicence(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBgElevated,
        title: Text(
          'TikTok Sans',
          style: AppTokens.titleS.copyWith(color: colorTextPrimary),
        ),
        content: Text(
          'La police est distribuée sous SIL Open Font License 1.1. Elle peut '
          'être utilisée et redistribuée librement, y compris dans une '
          'application commerciale. Le texte complet est livré dans '
          'assets/fonts/OFL.txt.',
          style: AppTokens.bodyS.copyWith(color: colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Fermer',
              style: AppTokens.labelM.copyWith(color: colorBrand),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBgElevated,
        title: Text(
          'Effacer les données locales ?',
          style: AppTokens.titleS.copyWith(color: colorTextPrimary),
        ),
        content: Text(
          'Tes likes, favoris, abonnements, commentaires et recherches seront '
          'supprimés de cet appareil.',
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
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(space4, space20, space4, space8),
          child: Text(
            title.toUpperCase(),
            style: AppTokens.labelS.copyWith(
              color: colorTextSecondaryDark,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorBgCard,
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 52,
                    color: colorDivider,
                  ),
              ],
            ],
          ),
        ),
      ],
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
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        child: Row(
          children: [
            ReelIcon(
              icon,
              size: 22,
              color: destructive ? colorBrand : colorTextSecondary,
            ),
            const SizedBox(width: space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.bodyS.copyWith(
                      color: destructive ? colorBrand : colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.labelS.copyWith(
                      color: colorTextSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: space8),
            const ReelIcon(
              ReelGlyph.chevronRight,
              size: 16,
              color: colorTextSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final ReelGlyph icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(space16, space10, space12, space10),
        child: Row(
          children: [
            ReelIcon(icon, size: 22, color: colorTextSecondary),
            const SizedBox(width: space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.bodyS.copyWith(
                      color: colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.labelS.copyWith(
                      color: colorTextSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: colorBrand,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});

  final ReelGlyph icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReelIcon(icon, size: 18, color: colorBrandCyan),
          const SizedBox(width: space10),
          Expanded(
            child: Text(
              text,
              style: AppTokens.bodyS.copyWith(color: colorTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
