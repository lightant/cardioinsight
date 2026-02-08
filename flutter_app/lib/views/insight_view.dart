// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/records_provider.dart';
import '../providers/profile_provider.dart';
import '../services/insight_service.dart';
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

final insightsFutureProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(apiKeyProvider);
  if (apiKey.isEmpty) {
    return "Please set your Gemini API Key in Settings or click below.";
  }

  final profile = ref.watch(profileProvider);
  final records = ref.watch(recordsProvider);

  if (profile == null || records.isEmpty) {
    return "Please sync your health data first to get insights.";
  }

  return ref.read(insightServiceProvider).getHealthInsights(profile, records);
});

class InsightView extends ConsumerWidget {
  const InsightView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsFutureProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.insights)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    ref.invalidate(insightsFutureProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: l10n.regenerate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: insightsAsync.when(
                  data: (text) {
                    if (text.contains("Please set your Gemini API Key")) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.key_off,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(text, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showApiKeyDialog(context, ref),
                            child: Text(l10n.setApiKey),
                          ),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
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
                // ignore: unused_result
                ref.refresh(insightsFutureProvider);
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
