// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/records_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/view_data_provider.dart';
import '../providers/sync_status_provider.dart';
import '../widgets/hr_chart.dart';
import '../widgets/edit_profile_dialog.dart';
import '../services/debug_service.dart';
import '../services/health_service.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final viewData = ref.watch(viewDataProvider);
    final notifier = ref.read(viewDataProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(recordsProvider.notifier).refresh();
            await ref.read(syncStatusProvider.notifier).updateSyncTime();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Profile Header
              if (profile != null) _buildProfileHeader(context, ref, profile),

              const SizedBox(height: 16),

              // Month Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildSelectorChip(
                      context,
                      label: l10n.allTime,
                      isSelected: viewData.selectedMonth.isEmpty,
                      onTap: () => notifier.selectMonth(''),
                    ),
                    ...notifier.availableMonths.map(
                      (m) => _buildSelectorChip(
                        context,
                        label: m.label,
                        isSelected: viewData.selectedMonth == m.value,
                        onTap: () => notifier.selectMonth(m.value),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsGrid(context, viewData.stats),
              ),

              const SizedBox(height: 16),

              // Chart Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildChartSection(context, viewData, notifier),
              ),

              const SizedBox(height: 16),

              // Daily List Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.dailyRecords,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Empty state or List
              if (viewData.dailyGroups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(l10n.noRecordsFound),
                  ),
                )
              else
                ...viewData.dailyGroups
                    .take(10)
                    .map(
                      (group) =>
                          _buildDailyCard(context, group, notifier, viewData),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF783C)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, profile) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final records = ref.watch(recordsProvider);
    final lastSync = ref.watch(syncStatusProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF783C),
                      Color(0xFFEF4444),
                    ], // Orange to red-500
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF783C).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeBack,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${profile.activityLevel} • ${profile.height ?? '-'} • ${profile.weight ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditProfileDialog(profile: profile),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recordsImported(records.length),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.lastSync(lastSync),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildCircleButton(
                    context,
                    icon: Icons.sync,
                    onPressed: () async {
                      await ref.read(recordsProvider.notifier).refresh();
                      await ref.read(syncStatusProvider.notifier).updateSyncTime();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    context,
                    icon: Icons.bug_report,
                    onPressed: () async {
                      final debugService = DebugService();
                      final debugRecords = await debugService.loadDebugData();
                      ref.read(recordsProvider.notifier).setRecords(debugRecords);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.debugRecordsLoaded(debugRecords.length),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    context,
                    icon: Icons.file_download,
                    onPressed: () async {
                      final healthService = HealthService();
                      final debugService = DebugService();
                      final start = DateTime.now().subtract(const Duration(days: 365));
                      final end = DateTime.now();
                      final rawData = await healthService.getRawHealthData(
                        start: start,
                        end: end,
                      );
                      final filePath = await debugService.exportRawHealthData(rawData);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              filePath.isNotEmpty
                                  ? l10n.readyToExport
                                  : l10n.exportFailed,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Stats stats) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      children: [
        _buildStatCard(
          context,
          l10n.avgHr,
          stats.avg.toString(),
          Colors.grey,
          theme.colorScheme.onSurface,
        ),
        _buildStatCard(
          context,
          l10n.minHr,
          stats.min.toString(),
          Colors.blue,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          l10n.peakHr,
          stats.peak.toString(),
          Colors.red,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            l10n.bpm,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    ViewDataState viewData,
    ViewDataNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Determine title
    String title = l10n.heartRateTrend;
    if (viewData.selectedDay != null) {
      title += ' - ${viewData.selectedDay}';
    } else if (viewData.selectedMonth.isNotEmpty) {
      title += ' - ${viewData.selectedMonth}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => notifier.selectDay(null),
                child: Text(l10n.clearSelection),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HRChart(data: viewData.chartData, maxHr: 200),
        ],
      ),
    );
  }

  Widget _buildDailyCard(
    BuildContext context,
    DailyGroup group,
    ViewDataNotifier notifier,
    ViewDataState viewData,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSelected = viewData.selectedDay == group.date;

    return InkWell(
      onTap: () => notifier.selectDay(isSelected ? null : group.date),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFFF783C), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.displayDate == 'today'
                          ? l10n.today
                          : group.displayDate == 'yesterday'
                          ? l10n.yesterday
                          : group.displayDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.recordsCount(group.records.length),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildMiniStat(
                          l10n.avgHr,
                          group.avg.toString(),
                          Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniStat(
                          l10n.minHr,
                          group.min.toString(),
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniStat(
                          l10n.peakHr,
                          group.max.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: HRChart(
                data: group.chartData,
                maxHr: 200,
                isCompact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
