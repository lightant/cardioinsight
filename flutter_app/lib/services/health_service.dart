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
  static final types = [HealthDataType.HEART_RATE];

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

    final bool hasPermissions = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    debugPrint("Request permissions result: $hasPermissions");
    return hasPermissions;
  }

  /// Fetches heart rate data day-by-day to avoid loading millions of raw
  /// HealthDataPoints into memory at once (which causes OOM on 90-day fetches).
  ///
  /// [onChunk] is called with each day's aggregated records as they finish, so
  /// the UI can update progressively. Awaiting the returned Future means the
  /// full 90-day window has been processed.
  Future<void> fetchHeartRateDataChunked({
    required DateTime start,
    required DateTime end,
    required Future<void> Function(List<HeartRateRecord> chunk) onChunk,
  }) async {
    // Walk one calendar day at a time so peak memory = one day of raw points.
    DateTime dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = DateTime(end.year, end.month, end.day);

    while (!dayStart.isAfter(dayEnd)) {
      final dayEndTime = DateTime(
        dayStart.year,
        dayStart.month,
        dayStart.day,
        23,
        59,
        59,
        999,
      );

      try {
        // Fetch one day of raw data — the list is scoped here and can be GC'd
        // as soon as we exit this block.
        final List<HealthDataPoint> rawPoints = await _health
            .getHealthDataFromTypes(
              startTime: dayStart,
              endTime: dayEndTime,
              types: types,
            );

        if (rawPoints.isNotEmpty) {
          final chunk = _aggregateToHourlyRecords(rawPoints);
          // Release rawPoints reference before the async gap so the GC can
          // reclaim it while we await the callback.
          await onChunk(chunk);
        }
      } catch (e) {
        debugPrint("Error fetching health data for $dayStart: $e");
        // Continue to the next day even if one day fails.
      }

      dayStart = dayStart.add(const Duration(days: 1));
    }
  }

  /// Groups [healthData] by hour and returns one [HeartRateRecord] per occupied hour.
  List<HeartRateRecord> _aggregateToHourlyRecords(
    List<HealthDataPoint> healthData,
  ) {
    // 1. Group by Hour (yyyy-MM-dd HH)
    final Map<String, List<HealthDataPoint>> groups = {};
    for (var point in healthData) {
      final dateKey = PointUtils.getHourKey(point.dateFrom);
      (groups[dateKey] ??= []).add(point);
    }

    // 2. Map groups to HeartRateRecord
    final List<HeartRateRecord> records = groups.values.map((points) {
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
  }

  Future<List<HealthDataPoint>> getRawHealthData({
    required DateTime start,
    required DateTime end,
  }) async {
    return await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: types,
    );
  }
}

class PointUtils {
  static String getHourKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    return '$y-$m-$d $h';
  }

  static String getDayKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
