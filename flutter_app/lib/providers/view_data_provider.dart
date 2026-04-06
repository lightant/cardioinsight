// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/heart_rate_record.dart';
import '../utils/aggregator.dart';
import 'records_provider.dart';
import 'settings_provider.dart';

// Selection Notifiers to ensure state persists during records refresh
class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String value) => super.state = value;
}

class SelectedWeekNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  @override
  set state(int? value) => super.state = value;
}

class SelectedDayNotifier extends Notifier<String?> {
  @override
  String? build() {
    final records = ref.watch(recordsProvider);
    if (records.isEmpty) return null;
    // Records are already sorted latest first in recordsProvider
    return records.first.date;
  }

  @override
  set state(String? value) => super.state = value;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(
  SelectedMonthNotifier.new,
);
final selectedWeekProvider = NotifierProvider<SelectedWeekNotifier, int?>(
  SelectedWeekNotifier.new,
);
final selectedDayProvider = NotifierProvider<SelectedDayNotifier, String?>(
  SelectedDayNotifier.new,
);

// State class for ViewData
class ViewDataState {
  final String selectedMonth;
  final int? selectedWeek;
  final String? selectedDay;
  final List<HeartRateRecord> filteredRecords;
  final List<ChartPoint> chartData;
  final List<DailyGroup> dailyGroups;
  final Stats stats;
  
  ViewDataState({
    this.selectedMonth = '',
    this.selectedWeek,
    this.selectedDay,
    this.filteredRecords = const [],
    this.chartData = const [],
    this.dailyGroups = const [],
    this.stats = const Stats(avg: 0, min: 0, peak: 0),
  });
  
  Stats calculateStats(List<HeartRateRecord> records) {
    if (records.isEmpty) {
      return const Stats(avg: 0, min: 0, peak: 0);
    }

    final avgs = records
        .map((r) => r.avgHr ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg = avgs.isNotEmpty
        ? (avgs.reduce((a, b) => a + b) / avgs.length).round()
        : 0;

    final mins = records
        .map((r) => r.minHr)
        .where((v) => v > 0)
        .toList();
    final min = mins.isNotEmpty ? mins.reduce((a, b) => a < b ? a : b).toInt() : 0;

    final peaks = records.map((r) => r.maxHr).toList();
    final peak = peaks.isNotEmpty ? peaks.reduce((a, b) => a > b ? a : b).toInt() : 0;

    return Stats(avg: avg, min: min, peak: peak);
  }

  ViewDataState copyWith({
    String? selectedMonth,
    int? selectedWeek,
    String? selectedDay,
    List<HeartRateRecord>? filteredRecords,
    List<ChartPoint>? chartData,
    List<DailyGroup>? dailyGroups,
    Stats? stats,
  }) {
    return ViewDataState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedWeek: selectedWeek ?? this.selectedWeek,
      selectedDay: selectedDay ?? this.selectedDay,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      chartData: chartData ?? this.chartData,
      dailyGroups: dailyGroups ?? this.dailyGroups,
      stats: stats ?? this.stats,
    );
  }
}

class DailyGroup {
  final String date;
  final int min;
  final int max;
  final int avg;
  final int? resting;
  final String displayDate;
  final List<HeartRateRecord> records;
  final List<ChartPoint> chartData;

  DailyGroup({
    required this.date,
    required this.displayDate,
    required this.min,
    required this.max,
    required this.avg,
    this.resting,
    required this.records,
    required this.chartData,
  });
}

class Stats {
  final int avg;
  final int min;
  final int peak;

  const Stats({required this.avg, required this.min, required this.peak});
}

class ImageData {
  final String value;
  final String label;
  ImageData({required this.value, required this.label});
}

class WeekData {
  final int weekNum;
  final String label;
  WeekData({required this.weekNum, required this.label});
}

class ViewDataNotifier extends Notifier<ViewDataState> {
  @override
  ViewDataState build() {
    final records = ref.watch(recordsProvider);
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale.toString();

    // Watch selection providers so we react to user input AND record changes
    // while keeping the selection stable.
    final month = ref.watch(selectedMonthProvider);
    final week = ref.watch(selectedWeekProvider);
    final day = ref.watch(selectedDayProvider);

    return _calculateState(records, month, week, day, locale);
  }

  void selectMonth(String month) {
    ref.read(selectedMonthProvider.notifier).state = month;
    // Clearing sub-selections when month changes to avoid invalid states
    ref.read(selectedWeekProvider.notifier).state = null;
    ref.read(selectedDayProvider.notifier).state = null;
  }

  void selectWeek(int? week) {
    ref.read(selectedWeekProvider.notifier).state = week;
    ref.read(selectedDayProvider.notifier).state = null;
  }

  void selectDay(String? day) {
    ref.read(selectedDayProvider.notifier).state = day;
  }

  ViewDataState _calculateState(
    List<HeartRateRecord> allRecords,
    String month,
    int? week,
    String? day,
    String locale,
  ) {
    // 1. Filter Records
    List<HeartRateRecord> filtered = allRecords;

    if (month.isNotEmpty) {
      filtered = filtered.where((r) {
        try {
          final date = DateTime.parse(r.fullDate.split(' ').first);
          return DateFormat('yyyy-MM').format(date) == month;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Special logic: if no filters, show last 30 distinct days
    if (month.isEmpty && week == null) {
      final uniqueDates = filtered.map((r) => r.date).toSet().toList();
      if (uniqueDates.length > 30) {
        uniqueDates.sort((a, b) => b.compareTo(a));
        final latest30 = uniqueDates.take(30).toSet();
        filtered = filtered.where((r) => latest30.contains(r.date)).toList();
      }
    }

    // Stats Records (Reactive to Day Selection)
    List<HeartRateRecord> statsRecords = filtered;
    if (day != null) {
      statsRecords = filtered.where((r) => r.date == day).toList();
    }

    // 2. Calculate Stats
    int avg = 0, min = 0, peak = 0;
    if (statsRecords.isNotEmpty) {
      final avgs = statsRecords
          .map((r) => r.avgHr ?? 0)
          .where((v) => v > 0)
          .toList();
      avg = avgs.isNotEmpty
          ? (avgs.reduce((a, b) => a + b) / avgs.length).round()
          : 0;

      final mins = statsRecords
          .map((r) => r.minHr)
          .where((v) => v > 0)
          .toList();
      min = mins.isNotEmpty ? mins.reduce((a, b) => a < b ? a : b).toInt() : 0;

      final peaks = statsRecords.map((r) => r.maxHr).toList();
      peak = peaks.isNotEmpty
          ? peaks.reduce((a, b) => a > b ? a : b).toInt()
          : 0;
    }

    // 3. Group by Day (for Daily List)
    final Map<String, List<HeartRateRecord>> groups = {};
    for (var r in filtered) {
      if (!groups.containsKey(r.date)) groups[r.date] = [];
      groups[r.date]!.add(r);
    }

      final dailyGroups = <DailyGroup>[];
      for (var entry in groups.entries) {
        final records = entry.value;
        
        int minVal = 0;
        int maxVal = 0;
        double totalAvg = 0;
        
        if (records.isNotEmpty) {
          minVal = records.map((r) => r.minHr).reduce((a, b) => a < b ? a : b).toInt();
          maxVal = records.map((r) => r.maxHr).reduce((a, b) => a > b ? a : b).toInt();
          totalAvg = records.map((r) => r.avgHr ?? 0).reduce((a, b) => a + b) / records.length;
        }

        int? resting;
        try {
          final restingRecord = records.firstWhere((r) => r.tag == 'Resting');
          resting = restingRecord.minHr.toInt();
        } catch (_) {}

        String displayDate = entry.key;
        try {
          final date = DateTime.parse(entry.key);
          final now = DateTime.now();
          final today = DateTime(now.year, 
            now.month, 
            now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final recordDate = DateTime(date.year, date.month, date.day);

          if (recordDate == today) {
            displayDate = 'today';
          } else if (recordDate == yesterday) {
            displayDate = 'yesterday';
          } else {
            displayDate = DateFormat('d MMM', locale).format(date);
          }
        } catch (_) {}

        final groupChartData = DataAggregator.aggregateData(records, 'day');

        dailyGroups.add(
          DailyGroup(
            date: entry.key,
            displayDate: displayDate,
            min: minVal,
            max: maxVal,
            avg: totalAvg.round(),
            resting: resting,
            records: records,
            chartData: groupChartData,
          ),
        );
      }
      
      dailyGroups.sort((a, b) => b.date.compareTo(a.date));

    // 4. Chart Data Aggregation
    List<ChartPoint> chartData = [];
    if (day != null) {
      chartData = DataAggregator.aggregateData(statsRecords, 'day');
    } else if (week != null && month.isNotEmpty) {
      chartData = DataAggregator.aggregateData(statsRecords, 'week');
    } else if (month.isNotEmpty) {
      chartData = DataAggregator.aggregateData(statsRecords, 'month');
    } else {
      chartData = DataAggregator.aggregateData(statsRecords, 'all');
    }

    return ViewDataState(
      selectedMonth: month,
      selectedWeek: week,
      selectedDay: day,
      filteredRecords: filtered,
      chartData: chartData,
      dailyGroups: dailyGroups,
      stats: Stats(avg: avg, min: min, peak: peak),
    );
  }

  // Computed Getters for UI Selectors (Available Months/Weeks)
  List<ImageData> get availableMonths {
    final records = ref.read(recordsProvider);
    final settings = ref.read(settingsProvider);
    final locale = settings.locale.toString();
    final months = <String>{};
    for (var r in records) {
      try {
        final date = DateTime.parse(r.fullDate.split(' ').first);
        months.add(DateFormat('yyyy-MM').format(date));
      } catch (_) {}
    }

    return months.map((m) {
      final date = DateFormat('yyyy-MM').parse(m);
      return ImageData(
        value: m,
        label: DateFormat('MMM yyyy', locale).format(date),
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));
  }
}

final viewDataProvider = NotifierProvider<ViewDataNotifier, ViewDataState>(
  ViewDataNotifier.new,
);
