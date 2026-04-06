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
      // Optimization: Aggregate stats during the initial loop instead of iterating again for each hour.
      final Map<int, {'count': int, 'minSum': double, 'maxSum': double, 'minHr': double, 'maxHr': double, 'avgSum': double}> hourlyStats = {};
      final String fallbackDate = records.isNotEmpty ? records.first.date : '';

      for (var r in records) {
        try {
          final hour = int.parse(r.timeRange.split(':').first);
          final avgHr = r.avgHr ?? ((r.minHr + r.maxHr) / 2);

          hourlyStats.putIfAbsent(hour, () => ({
            'count': 0, 
            'minSum': 0.0, 
            'maxSum': 0.0, 
            'minHr': double.infinity, 
            'maxHr': -double.infinity, 
            'avgSum': 0.0
          })).update((stats) {
            stats['count'] = stats['count']! + 1;
            stats['minSum'] = stats['minSum']! + r.minHr;
            stats['maxSum'] = stats['maxSum']! + r.maxHr;
            stats['minHr'] = (r.minHr < stats['minHr']!) ? r.minHr : stats['minHr']!;
            stats['maxHr'] = (r.maxHr > stats['maxHr']!) ? r.maxHr : stats['maxHr']!;
            stats['avgSum'] = stats['avgSum']! + avgHr;
            return stats;
          });
        } catch (_) {}
      }

      return List.generate(24, (hour) {
        final label = '${hour.toString().padLeft(2, '0')}:00';
        final stats = hourlyStats[hour];

        if (stats == null || stats['count'] == 0) {
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

        return ChartPoint(
          id: hour.toString(),
          label: label,
          min: stats['minHr'].round(),
          max: stats['maxHr'].round(),
          avg: (stats['avgSum']! / stats['count']!).roundToDouble(),
          date: fallbackDate,
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
