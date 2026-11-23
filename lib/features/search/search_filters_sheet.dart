import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_sheet.dart';
import 'providers/search_provider.dart';

Future<void> showSearchFiltersSheet(BuildContext context) {
  return showReelSheet<void>(
    context,
    builder: (_) => const SearchFiltersSheet(),
  );
}

class SearchFiltersSheet extends ConsumerWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(searchSortProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space4, gutter, space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trier les résultats',
                style: AppTokens.titleS.copyWith(color: colorTextPrimary),
              ),
              const Spacer(),
              Pressable(
                scale: 0.92,
                onTap: () {
                  ref
                      .read(searchSortProvider.notifier)
                      .select(SearchSort.relevance);
                  Navigator.of(context).maybePop();
                },
                child: Text(
                  'Réinitialiser',
                  style: AppTokens.labelM.copyWith(
                    color: colorTextSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: space16),
          for (final sort in SearchSort.values)
            _SortTile(
              label: sort.label,
              selected: sort == current,
              onTap: () {
                ref.read(searchSortProvider.notifier).select(sort);
                Navigator.of(context).maybePop();
              },
            ),
          const SizedBox(height: space16),
          Text(
            'Les filtres s\'appliquent aux résultats de la source active.',
            style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
          ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: space8),
        padding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        decoration: BoxDecoration(
          color: selected ? colorBgElevated : colorBgCard,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(
            color: selected ? colorBrand : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTokens.bodyS.copyWith(
                color: colorTextPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (selected)
              const ReelIcon(
                ReelGlyph.check,
                size: 18,
                color: colorBrand,
              ),
          ],
        ),
      ),
    );
  }
}
