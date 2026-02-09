// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/records_provider.dart';
import '../services/debug_service.dart';
import '../services/health_service.dart';
import '../l10n/generated/app_localizations.dart';

class ImportView extends ConsumerWidget {
  const ImportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncHealthData)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              l10n.connectHealthConnect,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.importDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => ref.read(recordsProvider.notifier).refresh(),
              icon: const Icon(Icons.sync),
              label: Text(l10n.syncNow),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final debugService = DebugService();
                final debugRecords = await debugService.loadDebugData();
                ref.read(recordsProvider.notifier).setRecords(debugRecords);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Loaded ${debugRecords.length} debug records',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bug_report),
              label: Text(l10n.debugLoadSample),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final healthService = HealthService();
                final debugService = DebugService();

                // Fetch 365 days of data for "all data" debug requirements
                final start = DateTime.now().subtract(
                  const Duration(days: 365),
                );
                final end = DateTime.now();

                final rawData = await healthService.getRawHealthData(
                  start: start,
                  end: end,
                );

                final filePath = await debugService.exportRawHealthData(
                  rawData,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        filePath.isNotEmpty
                            ? 'Ready to export. Use the share dialog to save to Documents.'
                            : 'Export failed or no data',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.file_download),
              label: const Text('DEBUG HC data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Last Sync: ${records.isEmpty ? "Never" : "Just now"}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Imported ${records.length} records',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
