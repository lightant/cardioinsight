// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'heart_rate_record.dart';
import 'user_profile.dart';

class AppData {
  final UserProfile profile;
  final List<HeartRateRecord> records;

  AppData({required this.profile, required this.records});

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'records': records.map((r) => r.toJson()).toList(),
    };
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      profile: UserProfile.fromJson(json['profile']),
      records: (json['records'] as List)
          .map((r) => HeartRateRecord.fromJson(r))
          .toList(),
    );
  }
}
