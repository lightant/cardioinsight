// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  Future<void> refresh({bool forceFullSync = false}) async {
    if (_isSyncing) {
      debugPrint("Sync already in progress, skipping.");
      return;
    }
    _isSyncing = true;

    try {
      final healthService = ref.read(healthServiceProvider);

      // 1. Check Availability (Android specific)
      final isAvailable = await healthService.isHealthConnectAvailable();
      if (!isAvailable) {
        debugPrint("Sync skipped: Health Connect not supported on this platform.");
        return;
      }

      // 2. Request permissions if needed
      final hasAlready = await healthService.hasPermissions();
      if (!hasAlready) {
        final success = await healthService.requestPermissions();
        if (!success) {
          debugPrint("Permissions denied. Aborting sync.");
          return;
        }
      }

      // 3. Determine Start Date (Full vs Incremental)
      DateTime now = DateTime.now();
      DateTime start = now.subtract(const Duration(days: 90));

      if (!forceFullSync && state.isNotEmpty) {
        try {
          // Records are sorted latest-first, so first is most recent
          final latestFullDate = state.first.fullDate;
          final lastSync = DateFormat('yyyy-MM-dd HH:mm').parse(latestFullDate);
          
          // Overlap by 1 hour to ensure any partial sync in the last session is completed
          final incrementalStart = lastSync.subtract(const Duration(hours: 1));
          
          // Only use incremental if it's within the last 90 days
          if (incrementalStart.isAfter(start)) {
            start = incrementalStart;
            debugPrint("Performing incremental sync starting from: $start");
          } else {
            debugPrint("Latest record is too old. Performing full sync starting from: $start");
          }
        } catch (e) {
          debugPrint("Error parsing latest record date ($e). Falling back to full sync.");
        }
      } else {
        debugPrint("Starting full sync (90 days)...");
      }

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
        },
      );

      // Final sorted state and save to disk once.
      final finalRecords = accumulated.values.toList()
        ..sort((a, b) => b.fullDate.compareTo(a.fullDate));
      state = finalRecords;

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
