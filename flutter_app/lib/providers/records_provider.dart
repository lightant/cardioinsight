// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heart_rate_record.dart';
import '../services/health_service.dart';

final healthServiceProvider = Provider((ref) => HealthService());

class RecordsNotifier extends Notifier<List<HeartRateRecord>> {
  @override
  List<HeartRateRecord> build() {
    return [];
  }

  Future<void> refresh() async {
    debugPrint("Starting sync refresh...");
    final healthService = ref.read(healthServiceProvider);

    // 1. Check Availability (Android specific)
    final isAvailable = await healthService.isHealthConnectAvailable();
    debugPrint("Health Connect Availability: $isAvailable");

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

    // 3. Fetch data
    debugPrint("Permissions confirmed. Fetching data...");
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));

    final records = await healthService.fetchHeartRateData(
      start: start,
      end: now,
    );

    debugPrint("Fetched ${records.length} records.");
    state = records;
  }

  void addRecord(HeartRateRecord record) {
    state = [record, ...state];
  }

  void setRecords(List<HeartRateRecord> records) {
    state = records;
  }
}

final recordsProvider =
    NotifierProvider<RecordsNotifier, List<HeartRateRecord>>(
      RecordsNotifier.new,
    );
