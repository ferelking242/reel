import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reel_sheet.dart';
import '../../../core/widgets/video_thumbnail.dart';
import '../../comments/comments_sheet.dart';
import '../../share/share_sheet.dart';
import '../models/feed_item.dart';
import '../providers/engagement_provider.dart';

/// Compact sheet used when tapping a video outside the feed (search, profile).
Future<void> showItemSheet(BuildContext context, {required FeedItem item}) {
  return showReelSheet<void>(
    context,
    builder: (_) => ItemSheet(item: item),
  );
}

class ItemSheet extends ConsumerWidget {
  const ItemSheet({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(engagementProvider).isSaved(item.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space4, gutter, space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                child: VideoThumbnail(
                  url: item.thumbnailUrl,
                  aspectRatio: 9 / 16,
                  showPlayIcon: false,
                ),
              ),
              const SizedBox(width: space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.authorUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleS.copyWith(
                        color: colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: space8),
                    Text(
                      item.title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.bodyS.copyWith(
                        color: colorTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: space12),
                    Row(
                      children: [
                        const ReelIcon(
                          ReelGlyph.heart,
                          size: 14,
                          color: colorTextSecondaryDark,
                        ),
                        const SizedBox(width: space4),
                        Text(
                          item.formattedLikes ?? '—',
                          style: AppTokens.labelS.copyWith(
                            color: colorTextSecondaryDark,
                          ),
                        ),
                        const SizedBox(width: space12),
                        const ReelIcon(
                          ReelGlyph.comment,
                          size: 14,
                          color: colorTextSecondaryDark,
                        ),
                        const SizedBox(width: space4),
                        Text(
                          item.formattedComments ?? '—',
                          style: AppTokens.labelS.copyWith(
                            color: colorTextSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: space20),
          Row(
            children: [
              Expanded(
                child: _SheetAction(
                  glyph: ReelGlyph.comment,
                  label: 'Commenter',
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showCommentsSheet(context, item: item);
                  },
                ),
              ),
              const SizedBox(width: space12),
              Expanded(
                child: _SheetAction(
                  glyph: ReelGlyph.share,
                  label: 'Partager',
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showShareSheet(context, item: item);
                  },
                ),
              ),
              const SizedBox(width: space12),
              Expanded(
                child: _SheetAction(
                  glyph: ReelGlyph.bookmark,
                  label: saved ? 'Retirer' : 'Enregistrer',
                  active: saved,
                  onTap: () {
                    ref
                        .read(engagementProvider.notifier)
                        .toggleSave(item.id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final ReelGlyph glyph;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: active ? colorBrand.withValues(alpha: 0.16) : colorBgElevated,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(
            color: active ? colorBrand : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ReelIcon(
              glyph,
              size: 16,
              color: active ? colorBrand : colorTextPrimary,
              filled: active,
            ),
            const SizedBox(width: space6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.labelM.copyWith(
                  color: active ? colorBrand : colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
