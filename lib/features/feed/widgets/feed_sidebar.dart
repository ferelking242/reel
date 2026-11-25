import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contract/contract_provider.dart';
import '../../../core/haptics.dart';
import '../../../core/icons/reel_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reel_avatar.dart';
import '../../../core/widgets/reel_sheet.dart';
import '../models/feed_item.dart';
import '../providers/engagement_provider.dart';

/// Right-hand action rail of the feed: follow, like, comment, save, share and
/// the spinning sound disc.
class FeedSidebar extends ConsumerWidget {
  const FeedSidebar({
    super.key,
    required this.item,
    required this.isActive,
    required this.onOpenComments,
    required this.onOpenShare,
  });

  final FeedItem item;
  final bool isActive;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagement = ref.watch(engagementProvider);
    final liked = engagement.isLiked(item.id);
    final saved = engagement.isSaved(item.id);
    final following = engagement.isFollowing(item.authorUsername);
    final localComments = ref.watch(commentsProvider)[item.id]?.length ?? 0;
    final caps = ref.watch(uiContractValueProvider).capabilities;
    final likeLabel = _countLabel(caps.likes, item.likes, liked ? 1 : 0);
    final commentLabel =
        _countLabel(caps.comments, item.comments, localComments);
    final shareLabel = _countLabel(caps.shares, item.shares, 0);

    return SizedBox(
      width: AppTokens.sidebarWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarWithFollow(
            item: item,
            following: following,
            onToggleFollow: () {
              ref
                  .read(engagementProvider.notifier)
                  .toggleFollow(item.authorUsername);
            },
          ),
          const SizedBox(height: space24),
          if (caps.likes)
            _SidebarAction(
              glyph: ReelGlyph.heart,
              label: likeLabel,
              active: liked,
              activeColor: colorLike,
              semanticLabel: liked ? 'Retirer le like' : "J'aime",
              onTap: () {
                final nowLiked =
                    ref.read(engagementProvider.notifier).toggleLike(item.id);
                if (nowLiked) Haptics.medium();
              },
            ),
          if (caps.likes) const SizedBox(height: space20),
          if (caps.comments)
            _SidebarAction(
              glyph: ReelGlyph.comment,
              label: commentLabel,
              semanticLabel: 'Commentaires',
              onTap: onOpenComments,
            ),
          if (caps.comments) const SizedBox(height: space20),
          _SidebarAction(
            glyph: ReelGlyph.bookmark,
            label: _countLabel(true, item.bookmarks, saved ? 1 : 0),
            active: saved,
            activeColor: colorWarning,
            semanticLabel:
                saved ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onTap: () {
              final nowSaved =
                  ref.read(engagementProvider.notifier).toggleSave(item.id);
              Haptics.light();
              showReelToast(
                context,
                nowSaved ? 'Ajouté à tes favoris' : 'Retiré de tes favoris',
                icon: nowSaved ? ReelGlyph.bookmark : ReelGlyph.trash,
              );
            },
          ),
          if (caps.shares) const SizedBox(height: space20),
          if (caps.shares)
            _SidebarAction(
              glyph: ReelGlyph.share,
              label: shareLabel,
              semanticLabel: 'Partager',
              onTap: onOpenShare,
            ),
          if (caps.sounds && item.soundName != null) ...[
            const SizedBox(height: space20),
            _SpinningDisc(
              item: item,
              spinning: isActive && item.hasVideo,
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds the label under an action: the real counter when the extension
/// provides one, otherwise an empty label instead of a fabricated number.
String _countLabel(bool supported, int? base, int localDelta) {
  if (!supported || base == null) return '';
  return formatCount(base + localDelta);
}

class _AvatarWithFollow extends StatefulWidget {
  const _AvatarWithFollow({
    required this.item,
    required this.following,
    required this.onToggleFollow,
  });

  final FeedItem item;
  final bool following;
  final VoidCallback onToggleFollow;

  @override
  State<_AvatarWithFollow> createState() => _AvatarWithFollowState();
}

class _AvatarWithFollowState extends State<_AvatarWithFollow> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ReelAvatar(
            url: widget.item.authorAvatar,
            name: widget.item.authorUsername,
            size: 50,
            borderColor: colorTextPrimary,
            borderWidth: 1.5,
            onTap: () => showReelToast(
              context,
              'Profil de ${widget.item.authorUsername}',
              icon: ReelGlyph.profile,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _FollowBadge(
              following: widget.following,
              onTap: widget.onToggleFollow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Follow badge: the « + » rotates a quarter turn and morphs into a check.
class _FollowBadge extends StatefulWidget {
  const _FollowBadge({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  State<_FollowBadge> createState() => _FollowBadgeState();
}

class _FollowBadgeState extends State<_FollowBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: widget.following ? 1 : 0,
  );

  late final Animation<double> _plusTurn = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInBack));

  late final Animation<double> _checkTurn = Tween<double>(
    begin: -1,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(covariant _FollowBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.following != widget.following) {
      widget.following ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.85,
      onTap: widget.onTap,
      semanticLabel: widget.following
          ? 'Ne plus suivre'
          : 'Suivre',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Color.lerp(colorBrand, colorBgElevated, t),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16 * t),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: _plusTurn.value * 1.5708,
                    child: Transform.scale(
                      scale: 1 - 0.3 * t,
                      child: const ReelIcon(
                        ReelGlyph.plus,
                        size: 12,
                        color: Colors.white,
                        strokeWidth: 3.4,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: t,
                  child: Transform.rotate(
                    angle: _checkTurn.value * 1.5708,
                    child: const ReelIcon(
                      ReelGlyph.check,
                      size: 12,
                      color: colorTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SidebarAction extends StatefulWidget {
  const _SidebarAction({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = colorLike,
    this.semanticLabel,
  });

  final ReelGlyph glyph;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;
  final String? semanticLabel;

  @override
  State<_SidebarAction> createState() => _SidebarActionState();
}

class _SidebarActionState extends State<_SidebarAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: durationLike);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.32)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.32, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _SidebarAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? widget.activeColor : colorTextPrimary;
    return Pressable(
      scale: 0.9,
      haptic: HapticKind.none,
      onTap: widget.onTap,
      semanticLabel: widget.semanticLabel ?? widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: ReelIcon(
              widget.glyph,
              size: 34,
              color: color,
              filled: widget.active,
            ),
          ),
          const SizedBox(height: space4),
          AnimatedSwitcher(
            duration: durationFast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              style: AppTokens.labelM.copyWith(
                color: colorTextPrimary,
                fontWeight: FontWeight.w600,
                shadows: AppTokens.feedTextShadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({required this.item, required this.spinning});

  final FeedItem item;
  final bool spinning;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: () => showReelToast(
        context,
        widget.item.soundName ?? '',
        icon: ReelGlyph.music,
      ),
      semanticLabel: 'Son : ${widget.item.soundName ?? ''}',
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A2A2E), Color(0xFF0A0A0B)],
                  ),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF3A3A3E), width: 6),
                  ),
                ),
                child: ClipOval(
                  child: ReelAvatar(
                    url: widget.item.authorAvatar,
                    name: widget.item.authorUsername,
                    size: 34,
                  ),
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ReelIcon(
                  ReelGlyph.music,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
