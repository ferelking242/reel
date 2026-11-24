import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local identity shown on the profile tab.
///
/// Reel has no account server: the name, bio and link live on the device and
/// are only used to render the profile header.
class LocalProfile {
  const LocalProfile({this.name = '', this.bio = '', this.link = ''});

  final String name;
  final String bio;
  final String link;

  String get handle => name.trim().isEmpty ? '@toi' : name.trim();

  LocalProfile copyWith({String? name, String? bio, String? link}) {
    return LocalProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      link: link ?? this.link,
    );
  }
}

class ProfileEditNotifier extends Notifier<LocalProfile> {
  static const _kName = 'reel_profile_name';
  static const _kBio = 'reel_profile_bio';
  static const _kLink = 'reel_profile_link';

  @override
  LocalProfile build() {
    _restore();
    return const LocalProfile();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = LocalProfile(
      name: prefs.getString(_kName) ?? '',
      bio: prefs.getString(_kBio) ?? '',
      link: prefs.getString(_kLink) ?? '',
    );
  }

  Future<void> save(LocalProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, profile.name);
    await prefs.setString(_kBio, profile.bio);
    await prefs.setString(_kLink, profile.link);
  }
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, LocalProfile>(
  ProfileEditNotifier.new,
);
