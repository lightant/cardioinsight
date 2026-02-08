// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_profile_dialog.dart';
import '../providers/settings_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          if (profile != null) ...[
            _buildSectionHeader(context, l10n.userProfile),
            _buildSettingTile(
              context,
              ref,
              l10n.name,
              profile.name,
              Icons.person,
              onTap: () => _showEditProfile(context, profile),
            ),
            _buildSettingTile(
              context,
              ref,
              l10n.dob,
              profile.dob,
              Icons.calendar_today,
              onTap: () => _showEditProfile(context, profile),
            ),
            _buildSettingTile(
              context,
              ref,
              l10n.activityLevel,
              profile.activityLevel,
              Icons.directions_run,
              onTap: () => _showEditProfile(context, profile),
            ),
            if (profile.height != null)
              _buildSettingTile(
                context,
                ref,
                l10n.height,
                profile.height!,
                Icons.height,
                onTap: () => _showEditProfile(context, profile),
              ),
            if (profile.weight != null)
              _buildSettingTile(
                context,
                ref,
                l10n.weight,
                profile.weight!,
                Icons.monitor_weight,
                onTap: () => _showEditProfile(context, profile),
              ),
          ],
          const Divider(),
          _buildSectionHeader(context, l10n.application),
          _buildSettingTile(
            context,
            ref,
            l10n.language,
            settings.language,
            Icons.language,
            onTap: () => _showLanguageDialog(context, ref),
          ),
          _buildSettingTile(
            context,
            ref,
            l10n.theme,
            _themeLabel(context, settings.themeMode),
            Icons.dark_mode,
            onTap: () => _showThemeDialog(context, ref),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Cardio Insight v1.0.0 (Flutter)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light'; // TODO: Localize these if needed, or follow original app
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Light'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Simplified Chinese (简体中文)'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Traditional Chinese (繁體中文)'),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(
                      const Locale.fromSubtags(
                        languageCode: 'zh',
                        scriptCode: 'Hant',
                      ),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF783C),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context, profile) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(profile: profile),
    );
  }
}
