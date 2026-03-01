import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/subject.dart';
import '../models/time_period.dart';
import '../viewmodels/stats_view_model.dart';
import '../viewmodels/subject_view_model.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _periods = TimePeriod.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsViewModelProvider).loadStats(_uid, TimePeriod.week);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    ref
        .read(statsViewModelProvider)
        .changePeriod(_uid, _periods[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String _formatTotalTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h時間${m}分';
    return '$m分';
  }

  @override
  Widget build(BuildContext context) {
    final statsVM = ref.watch(statsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('学習統計'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _periods.map((p) => Tab(text: p.label)).toList(),
        ),
      ),
      body: statsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statsVM.dailyStats.isEmpty
              ? _buildEmptyState(theme)
              : _buildContent(statsVM, theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'まだ学習記録がありません',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StatsViewModel statsVM, ThemeData theme) {
    final studyDays = statsVM.dailyStats.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  icon: Icons.schedule,
                  label: '総学習時間',
                  value: _formatTotalTime(statsVM.totalSeconds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  icon: Icons.calendar_today,
                  label: '学習日数',
                  value: '$studyDays日',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart
          Text(
            '日別学習時間',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildBarChart(statsVM, theme),
          ),
          const SizedBox(height: 24),

          // Pie chart
          Text(
            '科目別学習時間',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildPieChart(theme),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(StatsViewModel statsVM, ThemeData theme) {
    final stats = statsVM.dailyStats;
    if (stats.isEmpty) return const SizedBox.shrink();

    final maxMinutes = stats
        .map((s) => s.totalDuration / 60)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = maxMinutes < 10 ? 10.0 : (maxMinutes * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = rod.toY.round();
              return BarTooltipItem(
                '$minutes分',
                TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox.shrink();
                }
                final label = _formatBarLabel(
                  stats[index].date,
                  statsVM.selectedPeriod,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(drawVerticalLine: false),
        barGroups: List.generate(stats.length, (i) {
          final minutes = stats[i].totalDuration / 60;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: minutes,
                width: stats.length > 20 ? 6 : 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withAlpha(160),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatBarLabel(String dateStr, TimePeriod period) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    final month = parts[1];
    final day = parts[2];

    switch (period) {
      case TimePeriod.week:
        final date = DateTime.tryParse(dateStr);
        if (date == null) return day;
        const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
        return weekdays[(date.weekday - 1) % 7];
      case TimePeriod.month:
        return '$day日';
      case TimePeriod.year:
        return '$month月';
      case TimePeriod.allTime:
        return '$month/$day';
    }
  }

  Widget _buildPieChart(ThemeData theme) {
    return StreamBuilder<List<Subject>>(
      stream: ref.read(subjectViewModelProvider).streamSubjects(_uid),
      builder: (context, snapshot) {
        final subjects = (snapshot.data ?? [])
            .where((s) => s.totalStudyTime > 0)
            .toList();
        if (subjects.isEmpty) {
          return Center(
            child: Text(
              'データなし',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          );
        }

        final colors = [
          Colors.blue,
          Colors.orange,
          Colors.green,
          Colors.purple,
          Colors.red,
          Colors.teal,
          Colors.amber,
          Colors.pink,
        ];

        final totalTime =
            subjects.fold<int>(0, (sum, s) => sum + s.totalStudyTime);

        return Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: List.generate(subjects.length, (i) {
                    final s = subjects[i];
                    final pct = (s.totalStudyTime / totalTime * 100);
                    return PieChartSectionData(
                      value: s.totalStudyTime.toDouble(),
                      color: colors[i % colors.length],
                      radius: 50,
                      title: '${pct.round()}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(subjects.length, (i) {
                final s = subjects[i];
                final minutes = s.totalStudyTime ~/ 60;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.icon} ${s.name} (${minutes}分)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
