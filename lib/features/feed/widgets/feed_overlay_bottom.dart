import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../models/feed_item.dart';

/// Bottom-left block of a feed page: author, description and sound.
class FeedOverlayBottom extends StatelessWidget {
  const FeedOverlayBottom({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.authorUsername,
                style: AppTokens.titleS.copyWith(
                  color: colorTextPrimary,
                  fontSize: 16,
                  shadows: AppTokens.feedTextShadow,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.authorVerified) ...[
              const SizedBox(width: space4),
              const ReelIcon(
                ReelGlyph.verified,
                size: 15,
                color: colorVerified,
              ),
            ],
            if (item.createdAt != null) ...[
              const SizedBox(width: space8),
              Text(
                '· ${formatRelativeTime(item.createdAt!)}',
                style: AppTokens.labelS.copyWith(
                  color: colorTextTertiary,
                  shadows: AppTokens.feedTextShadow,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: space6),
        _ExpandableDescription(item: item),
        const SizedBox(height: space10),
        _SoundTicker(soundName: item.soundName),
      ],
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.item});

  final FeedItem item;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans();
    const collapsedLines = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseStyle = DefaultTextStyle.of(context).style.merge(
          _descriptionStyle,
        );
        final painter = TextPainter(
          text: TextSpan(children: spans, style: baseStyle),
          maxLines: collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: durationNormal,
              curve: ReelCurves.emphasized,
              alignment: Alignment.topLeft,
              child: RichText(
                maxLines: _expanded ? null : collapsedLines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                text: TextSpan(children: spans, style: baseStyle),
              ),
            ),
            if (overflows || _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: space4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'moins' : 'plus',
                        style: AppTokens.labelM.copyWith(
                          color: colorTextSecondary,
                          fontWeight: FontWeight.w700,
                          shadows: AppTokens.feedTextShadow,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: durationFast,
                        child: const ReelIcon(
                          ReelGlyph.chevronDown,
                          size: 14,
                          color: colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static final TextStyle _descriptionStyle = AppTokens.bodyS.copyWith(
    color: colorTextPrimary,
    height: 1.45,
    shadows: AppTokens.feedTextShadow,
  );

  List<InlineSpan> _buildSpans() {
    return [
      TextSpan(text: widget.item.title),
      for (final tag in widget.item.hashtags)
        TextSpan(
          text: ' #$tag',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
    ];
  }
}

class _SoundTicker extends StatelessWidget {
  const _SoundTicker({required this.soundName});

  final String soundName;

  @override
  Widget build(BuildContext context) {
    final style = AppTokens.bodyS.copyWith(
      color: colorTextPrimary,
      fontWeight: FontWeight.w500,
      shadows: AppTokens.feedTextShadow,
    );

    return Row(
      children: [
        const ReelIcon(ReelGlyph.music, size: 14, color: colorTextPrimary),
        const SizedBox(width: space6),
        Expanded(
          child: SizedBox(
            height: 18,
            child: soundName.isEmpty
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final painter = TextPainter(
                        text: TextSpan(text: soundName, style: style),
                        textDirection: Directionality.of(context),
                        maxLines: 1,
                      )..layout();
                      final fits = painter.width <= constraints.maxWidth;
                      painter.dispose();

                      if (fits) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            soundName,
                            style: style,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return Marquee(
                        text: soundName,
                        style: style,
                        scrollAxis: Axis.horizontal,
                        velocity: 32,
                        blankSpace: 60,
                        pauseAfterRound: const Duration(seconds: 2),
                        startPadding: 0,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
