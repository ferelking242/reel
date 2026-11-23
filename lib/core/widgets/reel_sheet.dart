import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../haptics.dart';
import '../icons/reel_icons.dart';
import '../theme/tokens.dart';

/// Opens a bottom sheet using the Reel surface style.
///
/// [heightFactor] caps the sheet height (0..1 of the screen). When null the
/// sheet wraps its content.
Future<T?> showReelSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double? heightFactor,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? const Color(0x99000000),
    builder: (sheetContext) {
      final height = heightFactor == null
          ? null
          : MediaQuery.sizeOf(sheetContext).height * heightFactor;
      return ReelSheetSurface(
        height: height,
        child: builder(sheetContext),
      );
    },
  );
}

/// Rounded dark surface with a drag handle, used by every sheet.
class ReelSheetSurface extends StatelessWidget {
  const ReelSheetSurface({
    super.key,
    required this.child,
    this.height,
    this.backgroundColor,
  });

  final Widget child;
  final double? height;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorBgCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const _SheetHandle(),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: space20,
        width: double.infinity,
        child: Center(
          child: Container(
            width: AppTokens.sheetHandleWidth,
            height: AppTokens.sheetHandleHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row used by sheets: title on the left, optional trailing action.
class ReelSheetHeader extends StatelessWidget {
  const ReelSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(
      gutter,
      space4,
      gutter,
      space12,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showClose;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTokens.titleS.copyWith(color: colorTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTokens.labelS.copyWith(
                      color: colorTextSecondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showClose)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const ReelIcon(
                ReelGlyph.close,
                size: 20,
                color: colorTextSecondary,
              ),
              tooltip: 'Fermer',
            ),
        ],
      ),
    );
  }
}

/// Lightweight toast that does not steal focus from the feed.
void showReelToast(
  BuildContext context,
  String message, {
  ReelGlyph icon = ReelGlyph.check,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            ReelIcon(icon, size: 18, color: Colors.white),
            const SizedBox(width: space10),
            Expanded(
              child: Text(
                message,
                style: AppTokens.bodyS.copyWith(color: Colors.white),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Text(
                  actionLabel,
                  style: AppTokens.labelM.copyWith(color: colorBrandCyan),
                ),
              ),
          ],
        ),
      ),
    );
}

/// Copies [text] and shows a confirmation toast.
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  Haptics.light();
  if (context.mounted) {
    showReelToast(context, 'Lien copié dans le presse-papiers');
  }
}
