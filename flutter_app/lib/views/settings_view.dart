// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_profile_dialog.dart';
import '../providers/settings_provider.dart';
import 'package:gemini_nano_android/gemini_nano_android.dart';
import '../providers/api_key_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
          const Divider(),
          _buildSectionHeader(context, l10n.aiSource),
          const _AiSourceSelector(),
          const Divider(),
          _buildSectionHeader(context, l10n.aboutAndLicenses),
          _buildSettingTile(
            context,
            ref,
            l10n.aboutApp,
            '',
            Icons.info_outline,
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingTile(
            context,
            ref,
            l10n.openSourceLibraries,
            '',
            Icons.code,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OpenSourceLicensesView(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Cardio Insight v1.0.0 (Flutter)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.aboutApp),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cardio Insight v1.0.0'),
              const SizedBox(height: 16),
              Text(
                l10n.aiProvider,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(l10n.gemmaTerms),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
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
              title: Text(l10n.system),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.light),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.dark),
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
              title: Text(l10n.english),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.simplifiedChinese),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.traditionalChinese),
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
          if (value.isNotEmpty)
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

class _AiSourceSelector extends ConsumerStatefulWidget {
  const _AiSourceSelector();

  @override
  ConsumerState<_AiSourceSelector> createState() => _AiSourceSelectorState();
}

class _AiSourceSelectorState extends ConsumerState<_AiSourceSelector> {
  bool? _isAiCoreAvailable;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelPathController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: ref.read(apiKeyProvider));
    _modelPathController = TextEditingController(
      text: ref.read(settingsProvider).gemmaModelPath,
    );
    _checkAiCore();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelPathController.dispose();
    super.dispose();
  }

  Future<void> _checkAiCore() async {
    if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) {
      if (mounted) {
        setState(() {
          _isAiCoreAvailable = false;
        });
      }
      return;
    }

    final nano = GeminiNanoAndroid();
    final isAvailable = await nano.isAvailable();
    if (mounted) {
      setState(() {
        _isAiCoreAvailable = isAvailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final aiSource = settings.aiSource;

    // Keep controllers in sync with provider
    ref.listen(apiKeyProvider, (prev, next) {
      if (_apiKeyController.text != next) {
        _apiKeyController.text = next;
      }
    });

    ref.listen(settingsProvider.select((s) => s.gemmaModelPath), (prev, next) {
      if (_modelPathController.text != (next ?? '')) {
        _modelPathController.text = next ?? '';
      }
    });

    return RadioGroup<AiSource>(
      groupValue: aiSource,
      onChanged: (value) => _setAiSource(value),
      child: Column(
        children: [
          RadioListTile<AiSource>(
            title: Text(l10n.geminiApiKey),
            subtitle: Text(l10n.usesCloudApi),
            value: AiSource.geminiApi,
          ),
          if (aiSource == AiSource.geminiApi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'Enter API Key',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  ref.read(apiKeyProvider.notifier).setKey(value.trim());
                },
              ),
            ),
          RadioListTile<AiSource>(
            title: Text(l10n.onDeviceAi),
            subtitle: Text(
              _isAiCoreAvailable == null
                  ? 'Checking status...'
                  : (_isAiCoreAvailable! ? 'Supported ✅' : 'Unsupported ❌'),
            ),
            value: AiSource.aiCore,
          ),
          RadioListTile<AiSource>(
            title: Text(l10n.inAppAi),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.modelName),
                if (aiSource == AiSource.gemmaInApp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _modelPathController,
                          decoration: InputDecoration(
                            labelText: 'Model File Path',
                            hintText: '/storage/emulated/0/Download/...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.file_open),
                              onPressed: _pickModelFile,
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .setGemmaModelPath(value.trim());
                          },
                        ),
                        const SizedBox(height: 8),
                         Row(
                           children: [
                             Expanded(
                               child: TextButton.icon(
                                 onPressed: _pickModelFile,
                                 icon: const Icon(Icons.file_open, size: 16),
                                 label: const Text('Pick File'),
                               ),
                             ),
                             Expanded(
                               child: TextButton.icon(
                                 onPressed: () {
                                   const path = '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm';
                                   _modelPathController.text = path;
                                   ref.read(settingsProvider.notifier).setGemmaModelPath(path);
                                 },
                                 icon: const Icon(Icons.download_done, size: 16),
                                 label: const Text('Use Sideloaded'),
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
               ],
             ),
             value: AiSource.gemmaInApp,
           ),
        ],
      ),
    );
  }

  void _setAiSource(AiSource? value) {
    if (value != null) {
      ref.read(settingsProvider.notifier).setAiSource(value);
    }
  }

  Future<void> _pickModelFile() async {
    // Request storage permissions
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        // Permissions granted
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to pick a model file.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // LiteRT-LM models use .litertlm or .tflite
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await ref.read(settingsProvider.notifier).setGemmaModelPath(path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Model path updated: ${path.split('/').last}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }
}

class OpenSourceLicensesView extends StatelessWidget {
  const OpenSourceLicensesView({super.key});

  @override
  Widget build(BuildContext context) {
    final libraries = [
      'flutter (SDK)',
      'cupertino_icons',
      'health',
      'fl_chart',
      'google_generative_ai',
      'lucide_icons_flutter',
      'flutter_riverpod',
      'shared_preferences',
      'intl',
      'path_provider',
      'share_plus',
      'flutter_markdown',
      'gemini_nano_android',
      'flutter_tts',
      'google_fonts',
      'flutter_gemma',
      'lucide_icons_flutter',
    ];

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.openSourceLibraries)),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: libraries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.library_books_outlined, size: 20),
                title: Text(libraries[index]),
                subtitle: const Text(
                  'Distributed under their respective licenses (MIT/Apache/BSD)',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF783C),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
