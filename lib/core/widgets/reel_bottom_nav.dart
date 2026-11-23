import 'package:flutter/material.dart';

import '../haptics.dart';
import '../icons/reel_icons.dart';
import '../theme/tokens.dart';

/// Persistent bottom navigation shared by every tab.
///
/// [transparent] renders the bar over the video feed (gradient scrim, no
/// background), otherwise it uses the opaque app surface.
class ReelBottomNav extends StatelessWidget {
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

  static const _items = <_NavItemData>[
    _NavItemData('Accueil', ReelGlyph.home),
    _NavItemData('Amis', ReelGlyph.friends),
    _NavItemData('Créer', ReelGlyph.plus),
    _NavItemData('Boîte', ReelGlyph.inbox),
    _NavItemData('Profil', ReelGlyph.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: transparent
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE6000000), Color(0x00000000)],
              ),
            )
          : const BoxDecoration(
              color: colorBgSurface,
              border: Border(
                top: BorderSide(color: colorDivider, width: 0.5),
              ),
            ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: AppTokens.bottomNavHeight,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: i == 2
                    ? _CreateButton(onTap: onCreate)
                    : _NavButton(
                        data: _items[i],
                        active: currentIndex == i,
                        badge: i == 3 ? unreadCount : 0,
                        onTap: () => onSelect(i),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.glyph);

  final String label;
  final ReelGlyph glyph;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final _NavItemData data;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? colorTextPrimary : colorTextTertiary;
    return Semantics(
      button: true,
      selected: active,
      label: data.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.tap();
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
                    data.glyph,
                    size: iconNav,
                    color: color,
                    filled: active,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: colorBrand,
                        borderRadius: BorderRadius.circular(radiusPill),
                        border: Border.all(
                          color: colorBgBase,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: AppTokens.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                height: 1.1,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Créer',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.medium();
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
