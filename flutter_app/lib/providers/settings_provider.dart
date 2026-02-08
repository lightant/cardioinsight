// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  SettingsState({required this.themeMode, required this.locale});

  String get language {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant'
          ? 'Traditional Chinese'
          : 'Simplified Chinese';
    }
    return 'English';
  }

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeKey = 'settings_theme';
  static const _langKey = 'settings_lang';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      themeMode: ThemeMode.system,
      locale: const Locale('en'),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    final lang = prefs.getString(_langKey) ?? 'en';

    state = SettingsState(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      locale: _parseLocale(lang),
    );
  }

  Locale _parseLocale(String lang) {
    if (lang == 'zh_Hans') return const Locale('zh');
    if (lang == 'zh_Hant') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    }
    return const Locale('en');
  }

  String _serializeLocale(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? 'zh_Hant' : 'zh_Hans';
    }
    return 'en';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, _serializeLocale(locale));
    state = state.copyWith(locale: locale);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
