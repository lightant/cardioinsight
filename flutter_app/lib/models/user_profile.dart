// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

class UserProfile {
  final String name;
  final String dob;
  final String activityLevel;
  final String? sex;
  final String? height;
  final String? weight;

  UserProfile({
    required this.name,
    required this.dob,
    required this.activityLevel,
    this.sex,
    this.height,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob,
      'activityLevel': activityLevel,
      'sex': sex,
      'height': height,
      'weight': weight,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      dob: json['dob'],
      activityLevel: json['activityLevel'],
      sex: json['sex'],
      height: json['height'],
      weight: json['weight'],
    );
  }
}
