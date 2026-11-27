import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/haptics.dart';
import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_sheet.dart';
import '../feed/models/feed_item.dart';
import '../feed/providers/engagement_provider.dart';

/// Opens the comment sheet for [item].
Future<void> showCommentsSheet(BuildContext context, {required FeedItem item}) {
  return showReelSheet<void>(
    context,
    heightFactor: 0.9,
    builder: (_) => CommentsSheet(item: item),
  );
}

/// Dark comment sheet with local persistence.
///
/// Watchtower has no comments API, so comments written here are stored on the
/// device and merged with the item's server-side counter.
class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.item});

  final FeedItem item;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _newestFirst = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(commentsProvider.notifier).add(widget.item.id, text);
    _controller.clear();
    _focusNode.unfocus();
    Haptics.light();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: durationNormal,
        curve: ReelCurves.decelerate,
      );
    });
  }

  void _insertEmoji(String emoji) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.isValid ? selection.start : text.length;
    final updated = text.replaceRange(offset, offset, emoji);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset + emoji.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider)[widget.item.id] ?? const [];
    final ordered = _newestFirst
        ? comments.reversed.toList(growable: false)
        : comments;
    final total = (widget.item.comments ?? 0) + comments.length;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      children: [
        ReelSheetHeader(
          title: '${formatCount(total)} commentaires',
          subtitle: comments.isEmpty
              ? 'Aucun commentaire pour le moment'
              : '${comments.length} depuis cet appareil',
          trailing: Pressable(
            scale: 0.9,
            onTap: () => setState(() => _newestFirst = !_newestFirst),
            semanticLabel: 'Changer le tri',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _newestFirst ? 'Récents' : 'Pertinence',
                  style: AppTokens.labelM.copyWith(color: colorTextSecondary),
                ),
                const SizedBox(width: space4),
                const ReelIcon(
                  ReelGlyph.chevronDown,
                  size: 14,
                  color: colorTextSecondary,
                ),
                const SizedBox(width: space8),
              ],
            ),
          ),
        ),
        const Divider(height: 0.5),
        Expanded(
          child: ordered.isEmpty
              ? const _EmptyComments()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    gutter,
                    space12,
                    gutter,
                    space24,
                  ),
                  itemCount: ordered.length,
                  itemBuilder: (context, index) {
                    final comment = ordered[index];
                    return _CommentTile(
                      comment: comment,
                      onDelete: () => ref
                          .read(commentsProvider.notifier)
                          .remove(widget.item.id, comment.id),
                    );
                  },
                ),
        ),
        AnimatedPadding(
          duration: durationFast,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Container(
            decoration: const BoxDecoration(
              color: colorBgElevated,
              border: Border(
                top: BorderSide(color: colorDivider, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(space12, space8, space12, space8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EmojiRow(onPick: _insertEmoji),
                  Row(
                    children: [
                      const ReelAvatar(
                        url: '',
                        name: 'vous',
                        size: 34,
                      ),
                      const SizedBox(width: space10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) => setState(() {}),
                          style: AppTokens.bodyS.copyWith(
                            color: colorTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire…',
                            hintStyle: AppTokens.bodyS.copyWith(
                              color: colorTextSecondaryDark,
                            ),
                            fillColor: colorBgCard,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: space16,
                              vertical: space10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: space8),
                      Pressable(
                        scale: 0.88,
                        onTap: _controller.text.trim().isEmpty ? null : _submit,
                        semanticLabel: 'Envoyer',
                        child: AnimatedContainer(
                          duration: durationFast,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _controller.text.trim().isEmpty
                                ? colorBgCard
                                : colorBrand,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: ReelIcon(
                              ReelGlyph.send,
                              size: 17,
                              color: _controller.text.trim().isEmpty
                                  ? colorTextSecondaryDark
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: colorBgElevated,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.comment,
                  size: 28,
                  color: colorTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: space16),
            Text(
              'Sois la première personne à commenter',
              textAlign: TextAlign.center,
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
            const SizedBox(height: space6),
            Text(
              'Les commentaires sont enregistrés sur cet appareil.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({required this.comment, required this.onDelete});

  final LocalComment comment;
  final VoidCallback onDelete;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: space20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReelAvatar(url: '', name: 'vous', size: 36),
          const SizedBox(width: space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author,
                  style: AppTokens.labelM.copyWith(
                    color: colorTextSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: space2),
                Text(
                  comment.text,
                  style: AppTokens.bodyS.copyWith(
                    color: colorTextPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: space6),
                Row(
                  children: [
                    Text(
                      formatRelativeTime(comment.createdAt),
                      style: AppTokens.labelS.copyWith(
                        color: colorTextSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: space16),
                    GestureDetector(
                      onTap: () => showReelToast(
                        context,
                        'Les réponses arrivent bientôt',
                        icon: ReelGlyph.comment,
                      ),
                      child: Text(
                        'Répondre',
                        style: AppTokens.labelS.copyWith(
                          color: colorTextSecondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: space16),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Text(
                        'Supprimer',
                        style: AppTokens.labelS.copyWith(
                          color: colorTextSecondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: space8),
          Column(
            children: [
              Pressable(
                scale: 0.85,
                onTap: () => setState(() => _liked = !_liked),
                semanticLabel: "J'aime ce commentaire",
                child: ReelIcon(
                  ReelGlyph.heart,
                  size: 18,
                  filled: _liked,
                  color: _liked ? colorLike : colorTextSecondaryDark,
                ),
              ),
              const SizedBox(height: space4),
              Text(
                formatCount(comment.likes + (_liked ? 1 : 0)),
                style: AppTokens.caption.copyWith(
                  color: colorTextSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiRow extends StatelessWidget {
  const _EmojiRow({required this.onPick});

  final ValueChanged<String> onPick;

  static const _emojis = ['❤️', '😂', '😮', '😍', '🔥', '👏', '🙌', '💯'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: space6),
        itemCount: _emojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: space8),
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return GestureDetector(
            onTap: () => onPick(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: space10),
              decoration: BoxDecoration(
                color: colorBgCard,
                borderRadius: BorderRadius.circular(radiusPill),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji'],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
