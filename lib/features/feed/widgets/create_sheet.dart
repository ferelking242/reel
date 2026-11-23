import 'package:flutter/material.dart';

import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reel_sheet.dart';

/// Creation menu opened by the centre button of the bottom bar.
Future<void> showCreateSheet(BuildContext context) {
  return showReelSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space4, gutter, space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer',
            style: AppTokens.titleM.copyWith(color: colorTextPrimary),
          ),
          const SizedBox(height: space6),
          Text(
            'Publier une vidéo depuis Reel',
            style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
          ),
          const SizedBox(height: space16),
          Row(
            children: [
              for (final option in const [
                (ReelGlyph.camera, 'Caméra', 'Filmer une vidéo'),
                (ReelGlyph.grid, 'Importer', 'Depuis la galerie'),
                (ReelGlyph.live, 'Direct', 'Passer en LIVE'),
                (ReelGlyph.effects, 'Effets', 'Filtres et sons'),
              ])
                Expanded(
                  child: Pressable(
                    scale: 0.94,
                    onTap: () {
                      Navigator.of(sheetContext).maybePop();
                      showReelToast(
                        context,
                        '${option.$2} — bientôt disponible',
                        icon: option.$1,
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorBgElevated,
                            borderRadius: BorderRadius.circular(radiusLg),
                          ),
                          child: Center(
                            child: ReelIcon(
                              option.$1,
                              size: 24,
                              color: colorTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: space8),
                        Text(
                          option.$2,
                          style: AppTokens.labelM.copyWith(
                            color: colorTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
