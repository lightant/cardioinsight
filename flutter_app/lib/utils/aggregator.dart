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

  ChartPoint({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.avg,
    required this.date,
  });
}

class DataAggregator {
  static List<ChartPoint> aggregateData(
    List<HeartRateRecord> records,
    String view, // 'day', 'week', 'month', 'all'
  ) {
    if (records.isEmpty) return [];

    if (view == 'day') {
      // Assuming records are already for a single day, or filtered by view logic
      return records.reversed.toList().asMap().entries.map((entry) {
        final i = entry.key;
        final r = entry.value;
        return ChartPoint(
          id: i.toString(),
          label: r.timeRange,
          min: r.minHr,
          max: r.maxHr,
          avg: r.avgHr ?? ((r.minHr + r.maxHr) / 2),
          date: r.date,
        );
      }).toList();
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
