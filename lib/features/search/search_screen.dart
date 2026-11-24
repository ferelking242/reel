import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_avatar.dart';
import '../../core/widgets/reel_sheet.dart';
import 'providers/search_provider.dart';
import 'search_results_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _submitted = '';

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchQueryProvider);
    _controller.text = initial;
    _submitted = initial;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), () {
      ref.read(searchQueryProvider.notifier).update(value);
      if (mounted) setState(() => _submitted = value.trim());
    });
    setState(() {});
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    _debounce?.cancel();
    ref.read(searchHistoryProvider.notifier).add(query);
    ref.read(searchQueryProvider.notifier).update(query);
    setState(() => _submitted = query);
    _focusNode.unfocus();
    Haptics.light();
  }

  void _searchFor(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _submit(query);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() => _submitted = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _submitted.isNotEmpty;

    return Scaffold(
      backgroundColor: colorBgSurface,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              showClear: _controller.text.isNotEmpty,
              onChanged: _onChanged,
              onSubmit: () => _submit(_controller.text),
              onClear: _clear,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              onVoice: () => _showVoiceSheet(context),
            ),
            Expanded(
              child: hasQuery
                  ? SearchResultsScreen(
                      key: ValueKey(_submitted),
                      query: _submitted,
                    )
                  : _SuggestionsView(
                      history: ref.watch(searchHistoryProvider),
                      onSearch: _searchFor,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceSheet(BuildContext context) {
    showReelSheet<void>(
      context,
      builder: (_) => const _VoiceSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.showClear,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onBack,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(space4, space8, space12, space8),
      child: Row(
        children: [
          Pressable(
            scale: 0.88,
            onTap: onBack,
            semanticLabel: 'Retour',
            child: const Padding(
              padding: EdgeInsets.all(space8),
              child: ReelIcon(
                ReelGlyph.back,
                size: 22,
                color: colorTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: colorBgCard,
                borderRadius: BorderRadius.circular(radiusPill),
              ),
              child: Row(
                children: [
                  const SizedBox(width: space12),
                  const ReelIcon(
                    ReelGlyph.search,
                    size: 18,
                    color: colorTextSecondaryDark,
                  ),
                  const SizedBox(width: space8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmit(),
                      style: AppTokens.bodyS.copyWith(
                        color: colorTextPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rechercher des vidéos, créateurs…',
                        hintStyle: AppTokens.bodyS.copyWith(
                          color: colorTextSecondaryDark,
                          fontSize: 14,
                        ),
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (showClear)
                    Pressable(
                      scale: 0.85,
                      onTap: onClear,
                      semanticLabel: 'Effacer',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: space4),
                        child: ReelIcon(
                          ReelGlyph.close,
                          size: 14,
                          color: colorTextSecondaryDark,
                        ),
                      ),
                    ),
                  Pressable(
                    scale: 0.85,
                    onTap: onVoice,
                    semanticLabel: 'Recherche vocale',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: space8),
                      child: ReelIcon(
                        ReelGlyph.mic,
                        size: 18,
                        color: colorTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Pressable(
            scale: 0.92,
            onTap: onSubmit,
            child: Padding(
              padding: const EdgeInsets.only(left: space12),
              child: Text(
                'Rechercher',
                style: AppTokens.labelM.copyWith(
                  color: colorBrand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestions
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsView extends ConsumerWidget {
  const _SuggestionsView({required this.history, required this.onSearch});

  final List<String> history;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(trendingTagsProvider);
    final creators = ref.watch(trendingCreatorsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: space32),
      children: [
        if (history.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recherches récentes',
            action: 'Effacer',
            onAction: () => ref.read(searchHistoryProvider.notifier).clear(),
          ),
          for (final entry in history)
            _HistoryTile(
              text: entry,
              onTap: () => onSearch(entry),
              onDismiss: () =>
                  ref.read(searchHistoryProvider.notifier).remove(entry),
            ),
        ] else
          const _SearchHint(),
        if (creators.isNotEmpty) ...[
          const _SectionHeader(title: 'Créateurs du feed'),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: gutter),
              itemCount: creators.length,
              separatorBuilder: (_, __) => const SizedBox(width: space16),
              itemBuilder: (context, index) {
                final creator = creators[index];
                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      ReelAvatar(
                        url: creator.avatar,
                        name: creator.username,
                        size: 60,
                        showVerified: creator.verified,
                        onTap: () => onSearch(
                          creator.username.replaceFirst('@', ''),
                        ),
                      ),
                      const SizedBox(height: space8),
                      Text(
                        creator.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTokens.labelS.copyWith(
                          color: colorTextPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const _SectionHeader(title: 'Tendances'),
          for (final tag in tags)
            _TrendingTile(tag: tag, onTap: () => onSearch(tag.tag)),
        ],
        if (history.isEmpty && tags.isEmpty && creators.isEmpty)
          Padding(
            padding: const EdgeInsets.all(space32),
            child: Text(
              'Connecte un serveur Watchtower pour voir les tendances.',
              textAlign: TextAlign.center,
              style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
            ),
          ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space32, gutter, space8),
      child: Column(
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
                ReelGlyph.search,
                size: 28,
                color: colorTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: space16),
          Text(
            'Cherche dans la source active',
            style: AppTokens.titleS.copyWith(color: colorTextPrimary),
          ),
          const SizedBox(height: space6),
          Text(
            'Titres, créateurs et hashtags. Tes recherches récentes apparaissent ici.',
            textAlign: TextAlign.center,
            style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space20, gutter, space8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTokens.titleS.copyWith(color: colorTextPrimary),
            ),
          ),
          if (action != null)
            Pressable(
              scale: 0.92,
              onTap: onAction,
              child: Text(
                action!,
                style: AppTokens.labelM.copyWith(
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.text,
    required this.onTap,
    required this.onDismiss,
  });

  final String text;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: gutter,
          vertical: space10,
        ),
        child: Row(
          children: [
            const ReelIcon(
              ReelGlyph.clock,
              size: 18,
              color: colorTextSecondaryDark,
            ),
            const SizedBox(width: space12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.bodyS.copyWith(color: colorTextPrimary),
              ),
            ),
            Pressable(
              scale: 0.85,
              onTap: onDismiss,
              semanticLabel: 'Supprimer « $text »',
              child: const Padding(
                padding: EdgeInsets.all(space4),
                child: ReelIcon(
                  ReelGlyph.close,
                  size: 14,
                  color: colorTextSecondaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTile extends StatelessWidget {
  const _TrendingTile({required this.tag, required this.onTap});

  final SearchTag tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: gutter,
          vertical: space10,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorBgCard,
                borderRadius: BorderRadius.circular(radiusMd),
              ),
              child: const Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    color: colorTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: space12),
            Expanded(
              child: Text(
                tag.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.bodyS.copyWith(color: colorTextPrimary),
              ),
            ),
            Text(
              countLabel(tag.videos, 'vidéo'),
              style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
            ),
            const SizedBox(width: space8),
            const ReelIcon(
              ReelGlyph.trend,
              size: 16,
              color: colorBrand,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice sheet
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(gutter, space8, gutter, space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recherche vocale',
            style: AppTokens.titleM.copyWith(color: colorTextPrimary),
          ),
          const SizedBox(height: space6),
          Text(
            'La dictée arrive dans une prochaine version.',
            style: AppTokens.bodyS.copyWith(color: colorTextSecondaryDark),
          ),
          const SizedBox(height: space24),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Transform.scale(
                scale: 0.92 + _pulse.value * 0.12,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorBrand.withValues(alpha: 0.16),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorBrand,
                      ),
                      child: const Center(
                        child: ReelIcon(
                          ReelGlyph.music,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: space24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: colorBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: space12),
              ),
              child: Text(
                'Rechercher par texte',
                style: AppTokens.titleS.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
