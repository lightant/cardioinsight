// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(
  ApiKeyNotifier.new,
);

class ApiKeyNotifier extends Notifier<String> {
  static const _key = 'gemini_api_key';

  @override
  String build() {
    _loadKey();
    return '';
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '';
  }

  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key);
    state = key;
  }
}
