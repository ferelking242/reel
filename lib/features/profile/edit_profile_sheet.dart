import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/reel_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/reel_sheet.dart';
import 'providers/profile_edit_provider.dart';

Future<void> showEditProfileSheet(BuildContext context) {
  return showReelSheet<void>(
    context,
    builder: (_) => const EditProfileSheet(),
  );
}

/// Edits the local name, bio and link shown on the profile tab.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final LocalProfile _initial = ref.read(profileEditProvider);
  late final TextEditingController _name =
      TextEditingController(text: _initial.name);
  late final TextEditingController _bio =
      TextEditingController(text: _initial.bio);
  late final TextEditingController _link =
      TextEditingController(text: _initial.link);

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, space32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ReelSheetHeader(
              title: 'Modifier le profil',
              subtitle: 'Enregistré sur cet appareil uniquement',
            ),
            const SizedBox(height: space8),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorBgElevated,
                    ),
                    child: const Center(
                      child: ReelIcon(
                        ReelGlyph.profile,
                        size: 40,
                        color: colorTextSecondaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: colorBgCard,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: ReelIcon(
                          ReelGlyph.camera,
                          size: 15,
                          color: colorTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: space20),
            _Field(
              label: 'Nom',
              controller: _name,
              hint: '@toi',
              maxLength: 24,
            ),
            const SizedBox(height: space16),
            _Field(
              label: 'Bio',
              controller: _bio,
              hint: 'Parle de ton feed en une phrase',
              maxLines: 3,
              maxLength: 80,
            ),
            const SizedBox(height: space16),
            _Field(
              label: 'Lien',
              controller: _link,
              hint: 'https://',
              keyboardType: TextInputType.url,
              maxLength: 120,
            ),
            const SizedBox(height: space24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colorBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                ),
                child: Text(
                  'Enregistrer',
                  style: AppTokens.titleS.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final bio = _bio.text.trim();
    final link = _link.text.trim();
    await ref.read(profileEditProvider.notifier).save(
          LocalProfile(
            name: name.startsWith('@') ? name.substring(1) : name,
            bio: bio,
            link: link,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).maybePop();
    showReelToast(context, 'Profil mis à jour', icon: ReelGlyph.check);
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.labelS.copyWith(color: colorTextSecondaryDark),
        ),
        const SizedBox(height: space8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: AppTokens.bodyS.copyWith(color: colorTextPrimary),
          cursorColor: colorBrand,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTokens.bodyS.copyWith(
              color: colorTextSecondaryDark,
            ),
            counterStyle: AppTokens.caption.copyWith(
              color: colorTextSecondaryDark,
            ),
            filled: true,
            fillColor: colorBgCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: space12,
              vertical: space12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: const BorderSide(color: colorBrand, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
