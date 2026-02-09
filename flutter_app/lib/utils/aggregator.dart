// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'dart:math';
import '../models/heart_rate_record.dart';

class ChartPoint {
  final String id;
  final String label;
  final double min;
  final double max;
  final double avg;
  final String date;
  final bool isEmpty;

  ChartPoint({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.avg,
    required this.date,
    this.isEmpty = false,
  });
}

class DataAggregator {
  static List<ChartPoint> aggregateData(
    List<HeartRateRecord> records,
    String view, // 'day', 'week', 'month', 'all'
  ) {
    if (records.isEmpty && view != 'day') return [];

    if (view == 'day') {
      final Map<int, List<HeartRateRecord>> hourlyGroups = {};
      for (var r in records) {
        try {
          // r.timeRange is "HH:mm - HH:mm" or "HH:mm"
          final hour = int.parse(r.timeRange.split(':').first);
          hourlyGroups.putIfAbsent(hour, () => []).add(r);
        } catch (_) {}
      }

      final String fallbackDate = records.isNotEmpty ? records.first.date : '';

      return List.generate(24, (hour) {
        final label = '${hour.toString().padLeft(2, '0')}:00';
        final hourRecords = hourlyGroups[hour] ?? [];
        if (hourRecords.isEmpty) {
          return ChartPoint(
            id: hour.toString(),
            label: label,
            min: 0,
            max: 0,
            avg: 0,
            date: fallbackDate,
            isEmpty: true,
          );
        }

        final mins = hourRecords.map((r) => r.minHr);
        final maxs = hourRecords.map((r) => r.maxHr);
        final avgs = hourRecords.map(
          (r) => r.avgHr ?? ((r.minHr + r.maxHr) / 2),
        );

        return ChartPoint(
          id: hour.toString(),
          label: label,
          min: mins.reduce(min),
          max: maxs.reduce(max),
          avg: (avgs.reduce((a, b) => a + b) / avgs.length).roundToDouble(),
          date: hourRecords.first.date,
          isEmpty: false,
        );
      });
    }

    if (view == 'week' || view == 'month' || view == 'all') {
      final Map<String, List<HeartRateRecord>> groups = {};

      for (var r in records) {
        if (!groups.containsKey(r.date)) {
          groups[r.date] = [];
        }
        groups[r.date]!.add(r);
      }

      return groups.entries
          .toList()
          .asMap()
          .entries
          .map((groupEntry) {
            final i = groupEntry.key;
            final date = groupEntry.value.key;
            final group = groupEntry.value.value;

            final mins = group.map((r) => r.minHr);
            final maxs = group.map((r) => r.maxHr);
            final avgs = group.map((r) => r.avgHr ?? 0);

            return ChartPoint(
              id: i.toString(),
              label: date,
              min: mins.reduce(min),
              max: maxs.reduce(max),
              avg: (avgs.reduce((a, b) => a + b) / avgs.length).roundToDouble(),
              date: date,
            );
          })
          .toList()
          .reversed
          .toList();
    }

    return [];
  }
}
