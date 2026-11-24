import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contract/contract_provider.dart';
import '../../../core/haptics.dart';
import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/pressable.dart';
import '../providers/engagement_provider.dart';
import '../providers/feed_provider.dart';

/// Floating header of the feed: live entry point, « Suivis / Pour toi » tabs,
/// search and sound toggle.
class FeedHeader extends ConsumerWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(feedTabProvider);
    final muted = ref.watch(feedMutedProvider);
    final status = ref.watch(serverStatusProvider);
    final liveEnabled = ref.watch(uiContractValueProvider).capabilities.live;

    final showBanner = status != null && !status.startsWith('✓');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: space12),
              if (liveEnabled)
                Pressable(
                  scale: 0.9,
                  onTap: () => context.push('/live'),
                  semanticLabel: 'Ouvrir le direct',
                  child: const _LiveEntry(),
                ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeedTab(
                        label: 'Suivis',
                        active: tab == 1,
                        onTap: () {
                          Haptics.tap();
                          ref.read(feedTabProvider.notifier).update(1);
                        },
                      ),
                      const SizedBox(width: space20),
                      _FeedTab(
                        label: 'Pour toi',
                        active: tab == 0,
                        onTap: () {
                          Haptics.tap();
                          ref.read(feedTabProvider.notifier).update(0);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Pressable(
                scale: 0.88,
                onTap: () => context.push('/search'),
                semanticLabel: 'Rechercher',
                child: const Padding(
                  padding: EdgeInsets.all(space6),
                  child: ReelIcon(
                    ReelGlyph.search,
                    size: iconHeader,
                    color: colorTextPrimary,
                  ),
                ),
              ),
              Pressable(
                scale: 0.88,
                onTap: () => ref.read(feedMutedProvider.notifier).toggle(),
                semanticLabel: muted ? 'Activer le son' : 'Couper le son',
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: space6,
                    right: space12,
                    top: space6,
                    bottom: space6,
                  ),
                  child: ReelIcon(
                    muted ? ReelGlyph.mute : ReelGlyph.volume,
                    size: 22,
                    color: colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showBanner) _StatusBanner(message: status),
      ],
    );
  }
}

class _LiveEntry extends StatelessWidget {
  const _LiveEntry();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveBadge(compact: true),
        const SizedBox(width: space4),
        ReelIcon(
          ReelGlyph.chevronRight,
          size: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: active,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: durationNormal,
              style: DefaultTextStyle.of(context).style.merge(TextStyle(
                color: active
                    ? colorTextPrimary
                    : colorTextPrimary.withValues(alpha: 0.62),
                fontSize: 16,
                height: 1.2,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                shadows: AppTokens.feedTextShadow,
              )),
              child: Text(label),
            ),
            const SizedBox(height: space4),
            AnimatedContainer(
              duration: durationNormal,
              curve: ReelCurves.emphasized,
              height: 2,
              width: active ? 22 : 0,
              decoration: const BoxDecoration(
                color: colorTextPrimary,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: space16,
        vertical: space6,
      ),
      color: const Color(0xB3000000),
      child: Row(
        children: [
          const ReelIcon(
            ReelGlyph.warning,
            size: 14,
            color: colorWarning,
          ),
          const SizedBox(width: space8),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.labelS.copyWith(color: colorTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

