// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/heart_rate_record.dart';
import '../services/health_service.dart';

final healthServiceProvider = Provider((ref) => HealthService());

class RecordsNotifier extends Notifier<List<HeartRateRecord>> {
  /// True while a Health Connect sync is in progress — prevents double-sync.
  bool _isSyncing = false;

  @override
  List<HeartRateRecord> build() {
    _loadFromLocal();
    return [];
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app-data.json');
  }

  Future<void> _loadFromLocal() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      final records = jsonList.map((j) => HeartRateRecord.fromJson(j)).toList();
      state = records;
      debugPrint("Loaded ${records.length} records from local cache.");
    } catch (e) {
      debugPrint("Error loading from local cache: $e");
    }
  }

  Future<void> _saveToLocal(List<HeartRateRecord> records) async {
    try {
      final file = await _getLocalFile();
      final jsonList = records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
      debugPrint("Saved ${records.length} records to local cache.");
    } catch (e) {
      debugPrint("Error saving to local cache: $e");
    }
  }

  Future<void> refresh() async {
    if (_isSyncing) {
      debugPrint("Sync already in progress, skipping.");
      return;
    }
    _isSyncing = true;

    try {
      debugPrint("Starting sync refresh...");
      final healthService = ref.read(healthServiceProvider);

      // 1. Check Availability (Android specific)
      final isAvailable = await healthService.isHealthConnectAvailable();
      debugPrint("Health Connect Availability: $isAvailable");
      if (!isAvailable) {
        debugPrint("Sync skipped: Health Connect not supported on this platform.");
        return;
      }

      // 2. Request permissions if needed
      final hasAlready = await healthService.hasPermissions();
      debugPrint("Already has permissions: $hasAlready");

      if (!hasAlready) {
        debugPrint("No permissions, requesting now...");
        final success = await healthService.requestPermissions();
        debugPrint("Request permissions success: $success");
        if (!success) {
          debugPrint("Permissions denied. Aborting sync.");
          return;
        }
      }

      // 3. Fetch data day-by-day to avoid an OOM when loading 90 days of raw
      //    heart-rate samples all at once.
      debugPrint("Permissions confirmed. Fetching data in daily chunks...");
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 90));

      // Accumulate results in a map keyed by fullDate so duplicates are
      // replaced automatically (idempotent merging).
      final Map<String, HeartRateRecord> accumulated = {
        for (var r in state) r.fullDate: r,
      };

      await healthService.fetchHeartRateDataChunked(
        start: start,
        end: now,
        onChunk: (chunk) async {
          for (final record in chunk) {
            accumulated[record.fullDate] = record;
          }

          // Update state progressively so the UI shows data arriving in real time.
          final sorted = accumulated.values.toList()
            ..sort((a, b) => b.fullDate.compareTo(a.fullDate));
          state = sorted;

          debugPrint(
            "Chunk received — total accumulated: ${accumulated.length} hourly records",
          );
        },
      );

      // Final sorted state (already set above, but ensure consistency).
      final finalRecords = accumulated.values.toList()
        ..sort((a, b) => b.fullDate.compareTo(a.fullDate));
      state = finalRecords;

      // Save to disk once after the whole sync (not per-chunk) to reduce I/O.
      await _saveToLocal(finalRecords);
      debugPrint("Sync complete. Total records: ${finalRecords.length}");
    } finally {
      _isSyncing = false;
    }
  }

  void addRecord(HeartRateRecord record) {
    state = [record, ...state];
    _saveToLocal(state);
  }

  void setRecords(List<HeartRateRecord> records) {
    state = records;
    _saveToLocal(state);
  }
}

final recordsProvider =
    NotifierProvider<RecordsNotifier, List<HeartRateRecord>>(
      RecordsNotifier.new,
    );
