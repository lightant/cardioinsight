// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/heart_rate_record.dart';
import 'health_service.dart'; // For PointUtils
import 'dart:math';

class DebugService {
  Future<List<HeartRateRecord>> loadDebugData() async {
    try {
      // 1. Load the HTML file from assets
      final htmlContent = await rootBundle.loadString(
        'assets/health_debug.html',
      );

      // 2. Extract the JSON part
      // The JSON is inside a <pre> tag based on the file inspection
      final startIndex = htmlContent.indexOf('<pre>') + 5;
      final endIndex = htmlContent.indexOf('</pre>');

      if (startIndex < 5 || endIndex == -1) {
        throw Exception('Could not find JSON content in health_debug.html');
      }

      final jsonString = htmlContent.substring(startIndex, endIndex).trim();

      // 3. Parse JSON
      final List<dynamic> jsonList = json.decode(jsonString);

      // 4. Transform to HeartRateRecord (Grouping logic similar to HealthService)
      final Map<String, List<Map<String, dynamic>>> groups = {};

      for (var series in jsonList) {
        if (series['type'] == 'HeartRateSeries') {
          final samples = series['samples'] as List<dynamic>;
          for (var sample in samples) {
            final timeStr = sample['time'] as String;
            final bpm = sample['beatsPerMinute'] as int;
            final dateTime = DateTime.parse(timeStr).toLocal();

            final dateKey = PointUtils.getHourKey(dateTime);
            if (!groups.containsKey(dateKey)) groups[dateKey] = [];

            groups[dateKey]!.add({'time': dateTime, 'value': bpm});
          }
        }
      }

      // 5. Create Records
      List<HeartRateRecord> records = groups.values.map((points) {
        // Sort by time
        points.sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
        );

        final hrs = points.map((p) => (p['value'] as int).toDouble()).toList();
        final minHr = hrs.reduce(min);
        final maxHr = hrs.reduce(max);
        final avgHr = hrs.reduce((a, b) => a + b) / hrs.length;

        final startTime = points.first['time'] as DateTime;
        final endTime = points.last['time'] as DateTime;

        return HeartRateRecord(
          date: PointUtils.getDayKey(startTime),
          fullDate: DateFormat('yyyy-MM-dd HH:mm').format(startTime),
          timeRange:
              "${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}",
          minHr: minHr,
          maxHr: maxHr,
          avgHr: avgHr.roundToDouble(),
          tag: "Debug Data",
          notes: "Simulated ${points.length} samples",
        );
      }).toList();

      // Sort descending
      records.sort((a, b) => b.fullDate.compareTo(a.fullDate));

      return records;
    } catch (e) {
      // ignore: avoid_print
      print('Error loading debug data: $e');
      return [];
    }
  }
}
