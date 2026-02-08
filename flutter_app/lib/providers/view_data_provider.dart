// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/heart_rate_record.dart';
import '../utils/aggregator.dart';
import 'records_provider.dart';
import 'settings_provider.dart';

// State class for ViewData
class ViewDataState {
  final String selectedMonth; // "yyyy-MM" or "" for all time
  final int? selectedWeek; // Week number or null
  final String? selectedDay; // "yyyy-MM-dd" or null
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
    return _calculateState(records, '', null, null, locale);
  }

  void selectMonth(String month) {
    final records = ref.read(recordsProvider);
    final settings = ref.read(settingsProvider);
    final locale = settings.locale.toString();
    state = _calculateState(records, month, null, null, locale);
  }

  void selectWeek(int? week) {
    final records = ref.read(recordsProvider);
    final settings = ref.read(settingsProvider);
    final locale = settings.locale.toString();
    state = _calculateState(records, state.selectedMonth, week, null, locale);
  }

  void selectDay(String? day) {
    final records = ref.read(recordsProvider);
    final settings = ref.read(settingsProvider);
    final locale = settings.locale.toString();
    state = _calculateState(
      records,
      state.selectedMonth,
      state.selectedWeek,
      day,
      locale,
    );
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
        // Assuming r.date is "YYYY-MM-DD" or similar ISO-like for accurate parsing
        // Or if r.date is "d MMM", we need to use r.fullDate
        // Let's assume r.date is usable or parse r.fullDate
        // Ideally models should store DateTime object
        // For now using simple string check if format matches
        // Implementing logic based on App.tsx which uses date-fns
        // Here we'll do basic string matching for simplicity if possible,
        // or parse properly.
        // Let's assume we can compare "yyyy-MM"
        try {
          // r.fullDate format TBD, let's look at model.
          // Assuming ISO string for fullDate based on previous context
          // actually standard format usually "yyyy-MM-dd HH:mm"
          final date = DateTime.parse(r.fullDate.split(' ').first);
          return DateFormat('yyyy-MM').format(date) == month;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    if (week != null) {
      // Filter by week number
      // TODO: Implement week filtering logic matching date-fns getWeek
    }

    // Special logic: if no filters, show last 30 distinct days (from App.tsx)
    if (month.isEmpty && week == null) {
      final uniqueDates = filtered.map((r) => r.date).toSet().toList();
      if (uniqueDates.length > 30) {
        // Sort unique dates descending
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
      min = mins.isNotEmpty
          ? mins.reduce((a, b) => a < b ? a : b).toInt()
          : 0; // cast to int

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

    final dailyGroups = groups.entries.map((entry) {
      final records = entry.value;
      final mins = records.map((r) => r.minHr);
      final maxs = records.map((r) => r.maxHr);

      final groupMin = mins.reduce((a, b) => a < b ? a : b).toInt();
      final groupMax = maxs.reduce((a, b) => a > b ? a : b).toInt();
      final groupAvg =
          (records.map((r) => r.avgHr ?? 0).reduce((a, b) => a + b) /
                  records.length)
              .round();

      // Finding resting HR (tag == 'Resting')
      int? resting;
      try {
        final restingRecord = records.firstWhere((r) => r.tag == 'Resting');
        resting = restingRecord.minHr.toInt();
      } catch (_) {}

      // Human-readable date
      String displayDate = entry.key;
      try {
        final date = DateTime.parse(entry.key);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final recordDate = DateTime(date.year, date.month, date.day);

        if (recordDate == today) {
          displayDate =
              'today'; // Use key for translation in UI if needed, or pass l10n here
        } else if (recordDate == yesterday) {
          displayDate = 'yesterday';
        } else {
          displayDate = DateFormat('d MMM', locale).format(date);
        }
      } catch (_) {}

      // Hourly chart data for this daily record
      final groupChartData = DataAggregator.aggregateData(records, 'day');

      return DailyGroup(
        date: entry.key,
        displayDate: displayDate,
        min: groupMin,
        max: groupMax,
        avg: groupAvg,
        resting: resting,
        records: records,
        chartData: groupChartData,
      );
    }).toList();

    // Sort daily groups descending by date
    dailyGroups.sort((a, b) => b.date.compareTo(a.date));

    // 4. Chart Data Aggregation
    // Re-using DataAggregator logic but ensuring it matches App.tsx specific view logic
    List<ChartPoint> chartData = [];
    if (day != null) {
      // Day View: Hourly
      chartData = DataAggregator.aggregateData(statsRecords, 'day');
    } else if (week != null && month.isNotEmpty) {
      // Week View: Daily
      chartData = DataAggregator.aggregateData(statsRecords, 'week');
    } else if (month.isNotEmpty) {
      // Month View: Daily
      chartData = DataAggregator.aggregateData(statsRecords, 'month');
    } else {
      // All Time
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
        final date = DateTime.parse(r.fullDate.split(' ').first); // ISO
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
