import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contract/contract_provider.dart';
import '../contract/ui_contract.dart';
import '../haptics.dart';
import '../icons/reel_icons.dart';
import '../theme/tokens.dart';

/// Persistent navigation shared by every tab.
///
/// Destinations, layout and behaviour come from the `shell.dock` section of
/// `assets/contract.json`; [UiContract.fallback] is used until it loads.
/// [transparent] renders the dock over the video feed (scrim, no surface).
class ReelBottomNav extends ConsumerWidget {
  const ReelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
    this.unreadCount = 0,
    this.transparent = false,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final int unreadCount;
  final bool transparent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dock = ref.watch(uiContractValueProvider).dock;
    if (!dock.enabled || dock.items.isEmpty) return const SizedBox.shrink();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isFloating = dock.type == DockType.floating && !transparent;

    final bar = SizedBox(
      height: dock.height,
      child: Row(
        children: [
          for (var i = 0; i < dock.items.length; i++)
            Expanded(
              child: dock.items[i].isAction
                  ? _CreateButton(onTap: onCreate, enabled: dock.haptics)
                  : _NavButton(
                      item: dock.items[i],
                      active: currentIndex == i,
                      showLabel: dock.showsLabels,
                      indicator: dock.activeIndicator,
                      haptics: dock.haptics,
                      badge: dock.items[i].badge == 'unread' ? unreadCount : 0,
                      onTap: () => onSelect(i),
                    ),
            ),
        ],
      ),
    );

    if (isFloating) {
      return Padding(
        padding: EdgeInsets.fromLTRB(dock.margin, 0, dock.margin, dock.margin),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dock.cornerRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE6141416),
                borderRadius: BorderRadius.circular(dock.cornerRadius),
                border: Border.all(color: const Color(0x1AFFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: bar,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: _backgroundFor(dock),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: dock.type == DockType.centered
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: bar,
              ),
            )
          : bar,
    );
  }

  BoxDecoration? _backgroundFor(DockConfig dock) {
    if (transparent) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Color(0x00000000)],
        ),
      );
    }
    if (dock.type == DockType.edgeToEdge ||
        dock.elevation == DockElevation.none) {
      return null;
    }
    if (dock.elevation == DockElevation.blur) {
      return const BoxDecoration(color: Color(0xE6141416));
    }
    return const BoxDecoration(
      color: colorBgSurface,
      border: Border(top: BorderSide(color: colorDivider, width: 0.5)),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.showLabel,
    required this.indicator,
    required this.haptics,
    required this.onTap,
    this.badge = 0,
  });

  final DockItem item;
  final bool active;
  final bool showLabel;
  final DockIndicator indicator;
  final bool haptics;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? colorTextPrimary : colorTextTertiary;

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (haptics) Haptics.tap();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: active ? 1.0 : 0.94,
                  duration: durationNormal,
                  curve: ReelCurves.emphasized,
                  child: ReelIcon(
                    item.glyph,
                    size: iconNav,
                    color: color,
                    filled: active && indicator == DockIndicator.fill,
                  ),
                ),
                if (badge > 0)
                  Positioned(right: -8, top: -4, child: _Badge(count: badge)),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
            if (active && indicator == DockIndicator.dot)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: colorBrand,
                  shape: BoxShape.circle,
                ),
              ),
            if (active && indicator == DockIndicator.underline)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: colorTextPrimary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorBrand,
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: colorBgBase, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTokens.caption.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Créer',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (enabled) Haptics.medium();
          onTap();
        },
        child: Center(
          child: SizedBox(
            width: 46,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 42,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorBrandCyan,
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 42,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorBrand,
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 42,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radiusMd),
                    ),
                    child: const Center(
                      child: ReelIcon(
                        ReelGlyph.plus,
                        size: 18,
                        color: Color(0xFF161823),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
