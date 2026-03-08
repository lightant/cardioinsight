// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiSource { geminiApi, aiCore, gemmaInApp }

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final AiSource aiSource;

  SettingsState({
    required this.themeMode,
    required this.locale,
    required this.aiSource,
  });

  String get language {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant'
          ? 'Traditional Chinese'
          : 'Simplified Chinese';
    }
    return 'English';
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    AiSource? aiSource,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      aiSource: aiSource ?? this.aiSource,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeKey = 'settings_theme';
  static const _langKey = 'settings_lang';
  static const _aiSourceKey = 'settings_ai_source';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      themeMode: ThemeMode.system,
      locale: const Locale('en'),
      aiSource: AiSource.geminiApi,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    final lang = prefs.getString(_langKey) ?? 'en';
    final aiSourceIndex = prefs.getInt(_aiSourceKey);

    state = SettingsState(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      locale: _parseLocale(lang),
      aiSource: aiSourceIndex != null
          ? AiSource.values[aiSourceIndex]
          : AiSource.geminiApi,
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

  Future<void> setAiSource(AiSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiSourceKey, source.index);
    state = state.copyWith(aiSource: source);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
