import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_bottom_nav.dart';
import '../../core/widgets/reel_sheet.dart';
import '../feed/providers/feed_provider.dart';
import '../feed/widgets/create_sheet.dart';
import '../feed/widgets/item_sheet.dart';
import 'providers/inbox_provider.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(inboxTabProvider);
    final entries = ref.watch(visibleActivityProvider);
    final unread = ref.watch(unreadInboxProvider);
    final seen = ref.watch(inboxReadProvider);

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, space8, space8, 0),
              child: Row(
                children: [
                  Text(
                    'Boîte de réception',
                    style: AppTokens.titleM.copyWith(
                      color: colorTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Pressable(
                    scale: 0.9,
                    onTap: unread == 0
                        ? null
                        : () {
                            ref.read(inboxReadProvider.notifier).markSeen(
                                  [
                                    ...ref.read(activityProvider),
                                    ...ref.read(systemMessagesProvider),
                                  ].map((e) => e.id),
                                );
                            showReelToast(
                              context,
                              'Tout est marqué comme lu',
                            );
                          },
                    semanticLabel: 'Tout marquer comme lu',
                    child: Padding(
                      padding: const EdgeInsets.all(space8),
                      child: ReelIcon(
                        ReelGlyph.check,
                        size: 20,
                        color: unread == 0
                            ? colorTextSecondaryDark
                            : colorTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, space8, gutter, space12),
              child: _SegmentedTabs(
                selected: tab,
                onSelect: (index) =>
                    ref.read(inboxTabProvider.notifier).select(index),
                labels: const ['Tout', 'Activité', 'Système'],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const _InboxEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: space32),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 0.5, indent: 76),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isUnread = !seen.contains(entry.id);
                        return _ActivityTile(
                          entry: entry,
                          unread: isUnread,
                          onTap: () => _open(context, ref, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReelBottomNav(
        currentIndex: 3,
        unreadCount: unread,
        onSelect: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/friends');
            case 4:
              context.go('/profile');
          }
        },
        onCreate: () => showCreateSheet(context),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, ActivityEntry entry) {
    ref.read(inboxReadProvider.notifier).markSeen([entry.id]);
    final itemId = entry.itemId;
    if (itemId == null) {
      showReelToast(
        context,
        entry.subtitle,
        icon: ReelGlyph.inbox,
      );
      return;
    }
    final items = ref.read(feedItemsProvider).asData?.value ?? const [];
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) {
      showReelToast(context, 'Cette vidéo n\'est plus dans le feed');
      return;
    }
    showItemSheet(context, item: item);
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.onSelect,
    required this.labels,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final List<String> labels;

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
                    color: selected == i ? colorBgElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(radiusPill),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.entry,
    required this.unread,
    required this.onTap,
  });

  final ActivityEntry entry;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(gutter, space12, gutter, space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Leading(entry: entry),
            const SizedBox(width: space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTokens.bodyS.copyWith(
                      color: colorTextPrimary,
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.labelS.copyWith(
                      color: colorTextSecondaryDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: space4),
                  Text(
                    activityTimeLabel(entry),
                    style: AppTokens.caption.copyWith(
                      color: colorTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(top: space8, left: space8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: colorBrand,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final (glyph, color) = switch (entry.kind) {
      ActivityKind.like => (ReelGlyph.heart, colorLike),
      ActivityKind.save => (ReelGlyph.bookmark, colorWarning),
      ActivityKind.follow => (ReelGlyph.friends, colorBrandCyan),
      ActivityKind.comment => (ReelGlyph.comment, const Color(0xFF7C3AED)),
      ActivityKind.system => (ReelGlyph.effects, colorTextSecondary),
    };

    if (entry.kind == ActivityKind.system) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorBgCard,
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        child: Center(child: ReelIcon(glyph, size: 22, color: color)),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ReelAvatar(
          url: entry.avatarUrl,
          name: entry.title,
          size: 48,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: colorBgBase, width: 2),
            ),
            child: Center(
              child: ReelIcon(glyph, size: 10, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty();

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
                  ReelGlyph.inbox,
                  size: 26,
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
            const SizedBox(height: space16),
            Text(
              'Rien pour le moment',
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              'Aime, enregistre ou commente une vidéo pour voir ton activité ici.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
