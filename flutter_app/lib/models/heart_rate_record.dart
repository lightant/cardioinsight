// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

class HeartRateRecord {
  final String date; // "Today", "Yesterday", "18 Nov"
  final String fullDate; // "Thu 20 Nov"
  final String timeRange; // "20:00 - 20:32" or "16:12"
  final double minHr;
  final double maxHr;
  final double? avgHr;
  final String tag; // "Resting", "Exercising", ""
  final String notes;

  HeartRateRecord({
    required this.date,
    required this.fullDate,
    required this.timeRange,
    required this.minHr,
    required this.maxHr,
    this.avgHr,
    required this.tag,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'fullDate': fullDate,
      'timeRange': timeRange,
      'minHr': minHr,
      'maxHr': maxHr,
      'avgHr': avgHr,
      'tag': tag,
      'notes': notes,
    };
  }

  factory HeartRateRecord.fromJson(Map<String, dynamic> json) {
    return HeartRateRecord(
      date: json['date'],
      fullDate: json['fullDate'],
      timeRange: json['timeRange'],
      minHr: (json['minHr'] as num).toDouble(),
      maxHr: (json['maxHr'] as num).toDouble(),
      avgHr: json['avgHr'] != null ? (json['avgHr'] as num).toDouble() : null,
      tag: json['tag'],
      notes: json['notes'],
    );
  }
}
