// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    loadProfile();
    return null;
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      state = UserProfile.fromJson(jsonDecode(profileJson));
    } else {
      state = UserProfile(
        name: 'User',
        dob: '2000-01-01',
        activityLevel: 'Moderate',
      );
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);
