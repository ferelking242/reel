import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_sheet.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';

/// Share / report sheet for a feed item.
Future<void> showShareSheet(BuildContext context, {required FeedItem item}) {
  return showReelSheet<void>(
    context,
    builder: (_) => ShareSheet(item: item),
  );
}

class ShareSheet extends ConsumerWidget {
  const ShareSheet({super.key, required this.item});

  final FeedItem item;

  String get _link =>
      item.videoUrl.isNotEmpty ? item.videoUrl : 'reel://${item.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(engagementProvider).isSaved(item.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReelSheetHeader(title: 'Partager'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: space12),
                    decoration: BoxDecoration(
                      color: colorBgElevated,
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                    child: Row(
                      children: [
                        const ReelIcon(
                          ReelGlyph.link,
                          size: 16,
                          color: colorTextSecondaryDark,
                        ),
                        const SizedBox(width: space8),
                        Expanded(
                          child: Text(
                            _link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTokens.bodyS.copyWith(
                              color: colorTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: space8),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: () => copyToClipboard(context, _link),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: space20,
                      ),
                    ),
                    child: Text(
                      'Copier',
                      style: AppTokens.labelM.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: space20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: gutter),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: space16,
              crossAxisSpacing: space12,
              childAspectRatio: 0.82,
              children: [
                _ShareAction(
                  glyph: ReelGlyph.link,
                  label: 'Copier le lien',
                  color: colorBrandCyan,
                  onTap: () => copyToClipboard(context, _link),
                ),
                _ShareAction(
                  glyph: ReelGlyph.send,
                  label: 'Copier le texte',
                  color: const Color(0xFF7C3AED),
                  onTap: () => copyToClipboard(
                    context,
                    '${item.title}\n${item.authorUsername}',
                  ),
                ),
                _ShareAction(
                  glyph: ReelGlyph.bookmark,
                  label: saved ? 'Retirer' : 'Enregistrer',
                  color: colorWarning,
                  onTap: () {
                    final nowSaved = ref
                        .read(engagementProvider.notifier)
                        .toggleSave(item.id);
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      nowSaved ? 'Enregistré' : 'Retiré des favoris',
                      icon: ReelGlyph.bookmark,
                    );
                  },
                ),
                _ShareAction(
                  glyph: ReelGlyph.clock,
                  label: 'Plus tard',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      'Ajouté à « À regarder plus tard »',
                      icon: ReelGlyph.clock,
                    );
                  },
                ),
                _ShareAction(
                  glyph: ReelGlyph.music,
                  label: 'Voir le son',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      item.soundName,
                      icon: ReelGlyph.music,
                    );
                  },
                ),
                _ShareAction(
                  glyph: ReelGlyph.close,
                  label: 'Pas intéressé',
                  color: const Color(0xFF6B7280),
                  onTap: () {
                    ref.read(hiddenItemsProvider.notifier).hide(item.id);
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      'Ce contenu ne sera plus proposé',
                      icon: ReelGlyph.check,
                      actionLabel: 'Annuler',
                      onAction: () =>
                          ref.read(hiddenItemsProvider.notifier).clear(),
                    );
                  },
                ),
                _ShareAction(
                  glyph: ReelGlyph.warning,
                  label: 'Signaler',
                  color: colorBrand,
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      'Signalement envoyé, merci.',
                      icon: ReelGlyph.warning,
                    );
                  },
                ),
                _ShareAction(
                  glyph: ReelGlyph.profile,
                  label: 'Voir le profil',
                  color: const Color(0xFFDB2777),
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showReelToast(
                      context,
                      item.authorUsername,
                      icon: ReelGlyph.profile,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: space16),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.glyph,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final ReelGlyph glyph;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.92,
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ReelIcon(glyph, size: 24, color: color),
            ),
          ),
          const SizedBox(height: space8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTokens.labelS.copyWith(
              color: colorTextSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
