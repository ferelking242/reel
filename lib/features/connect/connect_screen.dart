import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reel_sheet.dart';
import '../../core/widgets/skeletons.dart';
import '../../remote/remote_client.dart';
import '../../remote/remote_config_provider.dart';
import '../feed/providers/feed_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _testing = false;
  bool _saving = false;
  bool _obscureKey = true;
  String? _testResult;
  bool _testOk = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _sources = [];
  String? _selectedSourceId;

  List<Map<String, dynamic>> get _filteredSources {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _sources;
    return _sources.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final lang = (s['lang'] as String? ?? '').toLowerCase();
      return name.contains(q) || lang.contains(q);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final config = ref.read(remoteConfigProvider).asData?.value;
    _urlCtrl = TextEditingController(text: config?.baseUrl ?? '');
    _keyCtrl = TextEditingController(text: config?.apiKey ?? '');
    _selectedSourceId = config?.selectedSourceId ?? kDefaultSourceId;
    if (config != null && config.isConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _test());
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _testing = true;
      _testResult = null;
      _sources = [];
    });

    try {
      final client = RemoteApiClient(
        baseUrl: url,
        apiKey: _keyCtrl.text.trim(),
      );

      final result = await client.ping().timeout(const Duration(seconds: 12));
      final rawSources =
          await client.sources().timeout(const Duration(seconds: 12));
      final sources =
          rawSources.whereType<Map<String, dynamic>>().toList(growable: false);
      if (!mounted) return;

      setState(() {
        _testOk = true;
        _testResult =
            'Serveur joignable · ${sources.length} sources · version ${result["version"] ?? "?"}';
        _sources = sources;
        final savedId = _selectedSourceId ?? kDefaultSourceId;
        final exists = sources.any((s) => s['id']?.toString() == savedId);
        if (!exists && sources.isNotEmpty) {
          final preferred = sources.firstWhere(
            (s) =>
                (s['name'] as String? ?? '').toLowerCase().contains('redgif'),
            orElse: () => sources.first,
          );
          _selectedSourceId = preferred['id']?.toString();
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testResult = 'Connexion impossible : ${_friendly(error)}';
        _sources = [];
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      showReelToast(
        context,
        'Renseigne l\'URL du serveur',
        icon: ReelGlyph.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(remoteConfigProvider.notifier).save(
            baseUrl: url,
            apiKey: _keyCtrl.text.trim(),
            selectedSourceId: _selectedSourceId ?? kDefaultSourceId,
          );
      await ref.read(feedItemsProvider.notifier).refresh();
      if (!mounted) return;
      showReelToast(context, 'Serveur enregistré');
      _close();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String _friendly(Object error) {
    final text = error.toString().replaceAll('Exception: ', '');
    return text.length > 160 ? '${text.substring(0, 160)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigProvider).asData?.value;

    return Scaffold(
      backgroundColor: colorBgBase,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(space4, space4, space8, 0),
              child: Row(
                children: [
                  Pressable(
                    scale: 0.88,
                    onTap: _close,
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
                  const SizedBox(width: space4),
                  Text(
                    'Serveur',
                    style: AppTokens.titleM.copyWith(color: colorTextPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  gutter,
                  space16,
                  gutter,
                  space40,
                ),
                children: [
                  _Hero(configured: config?.isConfigured ?? false),
                  const SizedBox(height: space24),
                  _Field(
                    label: 'URL du serveur',
                    controller: _urlCtrl,
                    hint: 'https://mon-serveur.exemple.com',
                    keyboardType: TextInputType.url,
                    icon: ReelGlyph.link,
                  ),
                  const SizedBox(height: space16),
                  _Field(
                    label: 'Clé API',
                    controller: _keyCtrl,
                    hint: 'Laisse vide si aucune clé',
                    icon: ReelGlyph.settings,
                    obscure: _obscureKey,
                    trailing: Pressable(
                      scale: 0.9,
                      onTap: () =>
                          setState(() => _obscureKey = !_obscureKey),
                      child: Text(
                        _obscureKey ? 'Afficher' : 'Masquer',
                        style: AppTokens.labelS.copyWith(
                          color: colorBrandCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: space20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _test,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorTextPrimary,
                            side: const BorderSide(color: colorDivider),
                            padding:
                                const EdgeInsets.symmetric(vertical: space12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusMd),
                            ),
                          ),
                          child: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorTextPrimary,
                                  ),
                                )
                              : Text(
                                  'Tester la connexion',
                                  style: AppTokens.labelM.copyWith(
                                    color: colorTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: space12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorBrand,
                            padding:
                                const EdgeInsets.symmetric(vertical: space12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusMd),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Enregistrer',
                                  style: AppTokens.labelM.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: space16),
                    _TestResult(
                      ok: _testOk,
                      message: _testResult!,
                    ),
                  ],
                  if (_testOk && _sources.isNotEmpty) ...[
                    const SizedBox(height: space24),
                    Row(
                      children: [
                        Text(
                          'Source par défaut',
                          style: AppTokens.titleS.copyWith(
                            color: colorTextPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_sources.length} disponibles',
                          style: AppTokens.labelS.copyWith(
                            color: colorTextSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: space8),
                    _SourcePicker(
                      searchController: _searchCtrl,
                      searchQuery: _searchQuery,
                      onSearch: (value) => setState(() => _searchQuery = value),
                      sources: _filteredSources,
                      selectedId: _selectedSourceId,
                      onSelect: (id) =>
                          setState(() => _selectedSourceId = id),
                    ),
                  ],
                  if (config?.isConfigured ?? false) ...[
                    const SizedBox(height: space20),
                    Center(
                      child: TextButton(
                        onPressed: _confirmDisconnect,
                        child: Text(
                          'Déconnecter ce serveur',
                          style: AppTokens.labelM.copyWith(
                            color: colorTextSecondaryDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBgElevated,
        title: Text(
          'Déconnecter le serveur ?',
          style: AppTokens.titleS.copyWith(color: colorTextPrimary),
        ),
        content: Text(
          'L\'URL et la clé API seront effacées de cet appareil.',
          style: AppTokens.bodyS.copyWith(color: colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Annuler',
              style: AppTokens.labelM.copyWith(color: colorTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Déconnecter',
              style: AppTokens.labelM.copyWith(
                color: colorBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(remoteConfigProvider.notifier)
        .save(baseUrl: '', apiKey: '', selectedSourceId: '');
    _urlCtrl.clear();
    _keyCtrl.clear();
    setState(() {
      _sources = [];
      _testResult = null;
      _testOk = false;
      _selectedSourceId = kDefaultSourceId;
    });
    if (mounted) showReelToast(context, 'Serveur déconnecté');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(space20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1020), Color(0xFF101014)],
        ),
        border: Border.all(color: colorDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorBrand.withValues(alpha: 0.16),
            ),
            child: const Center(
              child: ReelIcon(ReelGlyph.effects, size: 24, color: colorBrand),
            ),
          ),
          const SizedBox(width: space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  configured
                      ? 'Serveur connecté'
                      : 'Connecte ton serveur Watchtower',
                  style: AppTokens.titleS.copyWith(color: colorTextPrimary),
                ),
                const SizedBox(height: space4),
                Text(
                  configured
                      ? 'Tu peux changer d\'URL ou de source à tout moment.'
                      : 'Reel lit le catalogue de ton serveur. Rien n\'est partagé avec des tiers.',
                  style: AppTokens.labelS.copyWith(
                    color: colorTextSecondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ReelGlyph icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.labelM.copyWith(color: colorTextSecondaryDark),
        ),
        const SizedBox(height: space8),
        Container(
          decoration: BoxDecoration(
            color: colorBgCard,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: space12),
          child: Row(
            children: [
              ReelIcon(icon, size: 18, color: colorTextSecondaryDark),
              const SizedBox(width: space8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: AppTokens.bodyS.copyWith(
                    color: colorTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTokens.bodyS.copyWith(
                      color: colorTextSecondaryDark,
                      fontSize: 13,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: space12),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({required this.ok, required this.message});

  final bool ok;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = ok ? colorSuccess : colorBrand;
    return Container(
      padding: const EdgeInsets.all(space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ReelIcon(
            ok ? ReelGlyph.check : ReelGlyph.warning,
            size: 16,
            color: color,
          ),
          const SizedBox(width: space8),
          Expanded(
            child: Text(
              message,
              style: AppTokens.labelM.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    required this.searchController,
    required this.searchQuery,
    required this.onSearch,
    required this.sources,
    required this.selectedId,
    required this.onSelect,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final List<Map<String, dynamic>> sources;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(space12, space8, space12, space4),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: colorBgElevated,
                borderRadius: BorderRadius.circular(radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: space8),
              child: Row(
                children: [
                  const ReelIcon(
                    ReelGlyph.search,
                    size: 15,
                    color: colorTextSecondaryDark,
                  ),
                  const SizedBox(width: space6),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      style: AppTokens.labelM.copyWith(
                        color: colorTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Filtrer les sources…',
                        hintStyle: AppTokens.labelM.copyWith(
                          color: colorTextSecondaryDark,
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
                  if (searchQuery.isNotEmpty)
                    Pressable(
                      scale: 0.85,
                      onTap: () {
                        searchController.clear();
                        onSearch('');
                      },
                      child: const ReelIcon(
                        ReelGlyph.close,
                        size: 13,
                        color: colorTextSecondaryDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 0.5),
          Flexible(
            child: sources.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(space20),
                    child: Text(
                      'Aucune source ne correspond.',
                      style: AppTokens.labelM.copyWith(
                        color: colorTextSecondaryDark,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: sources.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0.5, indent: 52),
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      final id = source['id']?.toString() ?? '';
                      final name = source['name'] as String? ?? id;
                      final lang = source['lang'] as String? ?? '';
                      final nsfw = source['isNsfw'] == true;
                      final selected = id == selectedId;

                      return InkWell(
                        onTap: () => onSelect(id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: space12,
                            vertical: space10,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: durationFast,
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? colorBrand
                                        : colorTextSecondaryDark,
                                    width: selected ? 5 : 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: space12),
                              _SourceIcon(source: source),
                              const SizedBox(width: space10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTokens.bodyS.copyWith(
                                              color: selected
                                                  ? colorTextPrimary
                                                  : colorTextSecondary,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        if (nsfw) ...[
                                          const SizedBox(width: space6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorBrand.withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              '18+',
                                              style: AppTokens.caption
                                                  .copyWith(
                                                color: colorBrand,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (lang.isNotEmpty)
                                      Text(
                                        lang,
                                        style: AppTokens.caption.copyWith(
                                          color: colorTextSecondaryDark,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const ReelIcon(
                                  ReelGlyph.check,
                                  size: 16,
                                  color: colorBrand,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.source});

  final Map<String, dynamic> source;

  @override
  Widget build(BuildContext context) {
    final iconUrl = source['iconUrl'] as String?;
    if (iconUrl == null || iconUrl.isEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorBgElevated,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        child: const Center(
          child: ReelIcon(
            ReelGlyph.grid,
            size: 14,
            color: colorTextSecondaryDark,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusSm),
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Shimmer(
          child: SizedBox(width: 28, height: 28),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 28,
          height: 28,
          color: colorBgElevated,
        ),
      ),
    );
  }
}

