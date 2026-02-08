// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/heart_rate_record.dart';
import 'package:intl/intl.dart';

class HealthService {
  final Health _health = Health();

  // Define the types that we want to access
  static final types = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_SESSION,
  ];

  Future<bool> isHealthConnectAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint("Health Connect not available: Not Android");
      return false;
    }
    final status = await _health.getHealthConnectSdkStatus();
    debugPrint("Health Connect SDK Status: $status");
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  Future<bool> installHealthConnect() async {
    await _health.installHealthConnect();
    return true;
  }

  Future<bool> hasPermissions() async {
    final permissions = types.map((e) => HealthDataAccess.READ).toList();
    final has =
        await _health.hasPermissions(types, permissions: permissions) ?? false;
    debugPrint("Has permissions: $has");
    return has;
  }

  Future<bool> requestPermissions() async {
    // Request permissions for Health Connect
    debugPrint("Requesting permissions for: $types");
    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    // Some versions of the plugin or Android might need explicit Activity Recognition
    // for certain health data. We'll ensure it's in the types list if needed.

    final bool hasPermissions = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    debugPrint("Request permissions result: $hasPermissions");
    return hasPermissions;
  }

  Future<List<HeartRateRecord>> fetchHeartRateData({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      // 1. Group by Hour (yyyy-MM-dd HH)
      final Map<String, List<HealthDataPoint>> groups = {};
      for (var point in healthData) {
        final dateKey = PointUtils.getHourKey(point.dateFrom);
        if (!groups.containsKey(dateKey)) groups[dateKey] = [];
        groups[dateKey]!.add(point);
      }

      // 2. Map groups to HeartRateRecord
      List<HeartRateRecord> records = groups.values.map((points) {
        points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

        final hrs = points
            .map((p) => (p.value as NumericHealthValue).numericValue.toDouble())
            .toList();
        final minHr = hrs.reduce(min);
        final maxHr = hrs.reduce(max);
        final avgHr = hrs.reduce((a, b) => a + b) / hrs.length;

        final startTime = points.first.dateFrom;
        final endTime = points.last.dateFrom;

        return HeartRateRecord(
          date: PointUtils.getDayKey(startTime),
          fullDate: DateFormat('yyyy-MM-dd HH:mm').format(startTime),
          timeRange:
              "${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}",
          minHr: minHr,
          maxHr: maxHr,
          avgHr: avgHr.roundToDouble(),
          tag: "Health Connect",
          notes: "Imported ${points.length} samples",
        );
      }).toList();

      // 3. Sort by date descending
      records.sort((a, b) => b.fullDate.compareTo(a.fullDate));

      return records;
    } catch (e) {
      debugPrint("Error fetching health data: $e");
      return [];
    }
  }
}

class PointUtils {
  static String getHourKey(DateTime date) =>
      DateFormat('yyyy-MM-dd HH').format(date);
  static String getDayKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
}
