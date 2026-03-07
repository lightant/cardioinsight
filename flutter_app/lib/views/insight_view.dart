// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/records_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/view_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/insight_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(
  ApiKeyNotifier.new,
);

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() {
    _loadKey();
    return '';
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('gemini_api_key') ?? '';
  }

  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    state = key;
  }
}

final insightServiceProvider = Provider((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return InsightService(apiKey);
});

// NEW: Notifier that handles generation and persistence of insights
final insightProvider = AsyncNotifierProvider<InsightNotifier, String>(
  InsightNotifier.new,
);

class InsightNotifier extends AsyncNotifier<String> {
  static const _cacheKey = 'gemini_insight_report';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final apiKey = ref.watch(apiKeyProvider);
    if (apiKey.isEmpty) return "SET_KEY_REQUIRED";

    return "TAP_TO_GENERATE";
  }

  Future<void> generateInsights() async {
    state = const AsyncLoading();

    try {
      final profile = ref.read(profileProvider);
      final records = ref.read(recordsProvider);

      if (profile == null || records.isEmpty) {
        state = const AsyncData(
          "Please sync your health data first to get insights.",
        );
        return;
      }

      final viewData = ref.read(viewDataProvider);
      final settings = ref.read(settingsProvider);
      final languageCode = settings.locale.languageCode;

      final result = await ref
          .read(insightServiceProvider)
          .getHealthInsights(
            profile,
            records,
            avgHr: viewData.stats.avg,
            minHr: viewData.stats.min,
            peakHr: viewData.stats.peak,
            languageCode: languageCode,
          );

      // Persist the result
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, result);

      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class InsightView extends ConsumerWidget {
  const InsightView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.insights)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      l10n.yourReport,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // Trigger manual generation
                    ref.read(insightProvider.notifier).generateInsights();
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: l10n.regenerate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: insightsAsync.when(
                data: (text) {
                  if (text == "SET_KEY_REQUIRED") {
                    return _buildCenteredMessage(
                      context,
                      icon: Icons.key_off,
                      message:
                          "Please set your Gemini API Key in Settings or click below.",
                      action: ElevatedButton(
                        onPressed: () => _showApiKeyDialog(context, ref),
                        child: Text(l10n.setApiKey),
                      ),
                    );
                  }

                  if (text == "TAP_TO_GENERATE") {
                    return _buildCenteredMessage(
                      context,
                      icon: Icons.analytics_outlined,
                      message:
                          "Tap the refresh button to generate your AI health insights.",
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: MarkdownBody(
                        data: text,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                            ),
                        selectable: true,
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.orange.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Gemini API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'Paste your key here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(apiKeyProvider.notifier)
                    .setKey(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
