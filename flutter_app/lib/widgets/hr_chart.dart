// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/aggregator.dart';
import '../l10n/generated/app_localizations.dart';

class HRChart extends StatelessWidget {
  final List<ChartPoint> data;
  final double maxHr;
  final bool isCompact;

  const HRChart({
    super.key,
    required this.data,
    required this.maxHr,
    this.isCompact = false,
  });

  Color _getZoneColor(double val) {
    final pct = val / maxHr;
    if (pct >= 0.9) return const Color(0xFFB91C1C); // Zone 5 - Red
    if (pct >= 0.8) return const Color(0xFFF97316); // Zone 4 - Orange
    if (pct >= 0.7) return const Color(0xFFEAB308); // Zone 3 - Yellow
    if (pct >= 0.6) return const Color(0xFF65A30D); // Zone 2 - Green
    return const Color(0xFF3B82F6); // Zone 1 - Blue
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (data.isEmpty) {
      return SizedBox(
        height: isCompact ? 60 : 200,
        child: Center(child: Text(l10n.noDataAvailable)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: isCompact ? 60 : 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxHr * 1.1,
              barTouchData: BarTouchData(
                enabled: !isCompact,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.white,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = data[group.x.toInt()];
                    return BarTooltipItem(
                      '${point.label}\n',
                      const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Range: ${point.min.round()} - ${point.max.round()} ${l10n.bpm}\n',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'Avg: ${point.avg.round()} ${l10n.bpm}',
                          style: const TextStyle(
                            color: Color(0xFFFF783C), // cardio-orange
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: !isCompact,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !isCompact,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value < 0 || value >= data.length) {
                        return const SizedBox.shrink();
                      }
                      if (data.length > 7 &&
                          value % (data.length / 4).floor() != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data[value.toInt()].label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !isCompact,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: !isCompact,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                if (p.isEmpty) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: 0,
                        color: Colors.transparent,
                        width: isCompact ? 4 : (data.length > 20 ? 6 : 12),
                      ),
                    ],
                  );
                }
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      fromY: p.min,
                      toY: p.max,
                      color: _getZoneColor(p.max),
                      width: isCompact ? 4 : (data.length > 20 ? 6 : 12),
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(show: false),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                l10n.hrZone('5', '>90%'),
                const Color(0xFFB91C1C),
              ),
              _buildLegendItem(
                l10n.hrZone('4', '80-90%'),
                const Color(0xFFF97316),
              ),
              _buildLegendItem(
                l10n.hrZone('3', '70-80%'),
                const Color(0xFFEAB308),
              ),
              _buildLegendItem(
                l10n.hrZone('2', '60-70%'),
                const Color(0xFF65A30D),
              ),
              _buildLegendItem(
                l10n.hrZone('1', '<60%'),
                const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
