import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.username,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.bio,
    this.photoPath,
    this.tier = 'Tier 3',
    this.kycStatus = 'Verified',
  });

  final String username;
  final String displayName;
  final String email;
  final String phone;
  final String bio;
  final String? photoPath;
  final String tier;
  final String kycStatus;

  File? get photoFile => photoPath != null && photoPath!.isNotEmpty ? File(photoPath!) : null;

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? email,
    String? phone,
    String? bio,
    String? photoPath,
    bool clearPhoto = false,
    String? tier,
    String? kycStatus,
  }) {
    return UserProfile(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      tier: tier ?? this.tier,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
      : super(const UserProfile(
          username: 'scorche',
          displayName: 'Scorche',
          email: 'issaabu399@gmail.com',
          phone: '+234 810 456 2311',
          bio: 'Building on ScorchePay · Money OS',
          photoPath: null,
          tier: 'Tier 3',
          kycStatus: 'Verified',
        )) {
    _loadFromPrefs();
  }

  static const _keyPhoto = 'user_profile_photo_path';
  static const _keyDisplayName = 'user_profile_display_name';
  static const _keyUsername = 'user_profile_username';
  static const _keyEmail = 'user_profile_email';
  static const _keyPhone = 'user_profile_phone';
  static const _keyBio = 'user_profile_bio';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photo = prefs.getString(_keyPhoto);
      final name = prefs.getString(_keyDisplayName);
      final uname = prefs.getString(_keyUsername);
      final email = prefs.getString(_keyEmail);
      final phone = prefs.getString(_keyPhone);
      final bio = prefs.getString(_keyBio);

      state = state.copyWith(
        photoPath: photo,
        displayName: name,
        username: uname,
        email: email,
        phone: phone,
        bio: bio,
      );
    } catch (_) {}
  }

  Future<void> setPhoto(String? path) async {
    state = state.copyWith(photoPath: path, clearPhoto: path == null);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path != null && path.isNotEmpty) {
        await prefs.setString(_keyPhoto, path);
      } else {
        await prefs.remove(_keyPhoto);
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? bio,
  }) async {
    state = state.copyWith(
      displayName: displayName,
      username: username,
      email: email,
      phone: phone,
      bio: bio,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (displayName != null) await prefs.setString(_keyDisplayName, displayName);
      if (username != null) await prefs.setString(_keyUsername, username);
      if (email != null) await prefs.setString(_keyEmail, email);
      if (phone != null) await prefs.setString(_keyPhone, phone);
      if (bio != null) await prefs.setString(_keyBio, bio);
    } catch (_) {}
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
