import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/review_item.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/study_heatmap_widget.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressViewModelProvider).loadProgress(_uid);
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _showGoalDialog() {
    final vm = ref.read(progressViewModelProvider);
    double hours = vm.weeklyGoalMinutes / 60;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Set Weekly Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${hours.round()} hours / week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: hours,
                    min: 1,
                    max: 112,
                    divisions: 111,
                    label: '${hours.round()}h',
                    onChanged: (v) {
                      setDialogState(() => hours = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    vm.updateWeeklyGoal(_uid, (hours * 60).round());
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(progressViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Learning Progress'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadProgress(_uid),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeeklyGoalCard(vm, theme),
                    const SizedBox(height: 16),
                    _buildReviewProgressCard(vm, theme),
                    const SizedBox(height: 16),
                    _buildForgettingRiskCard(vm, theme),
                    const SizedBox(height: 16),
                    _buildHeatmapCard(vm, theme),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/stats'),
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('View Detailed Statistics'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklyGoalCard(ProgressViewModel vm, ThemeData theme) {
    final goalSeconds = vm.weeklyGoalMinutes * 60;
    final progress =
        goalSeconds > 0 ? (vm.weeklyStudiedSeconds / goalSeconds).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();
    final isComplete = percent >= 100;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: isComplete ? Colors.green : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Goal',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _showGoalDialog,
                  tooltip: 'Edit goal',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: isComplete ? Colors.green : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatDuration(vm.weeklyStudiedSeconds)} / ${_formatDuration(goalSeconds)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewProgressCard(ProgressViewModel vm, ThemeData theme) {
    final total = vm.weeklyReviewsNeeded;
    final completed = vm.weeklyReviewsCompleted;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Review Progress This Week',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed / $total reviews',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  total > 0 ? '$percent%' : 'No reviews due',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgettingRiskCard(ProgressViewModel vm, ThemeData theme) {
    final totalItems =
        vm.dangerItems.length + vm.warningItems.length + vm.safeItems.length;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Forgetting Risk',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (totalItems == 0) ...[
              const SizedBox(height: 12),
              Text(
                'No review items yet. Add items after studying!',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ] else ...[
              const SizedBox(height: 8),
              if (vm.dangerItems.isNotEmpty)
                _buildRiskSection(
                  theme,
                  color: Colors.red,
                  icon: Icons.warning,
                  label: 'Overdue',
                  items: vm.dangerItems,
                  initiallyExpanded: true,
                ),
              if (vm.warningItems.isNotEmpty)
                _buildRiskSection(
                  theme,
                  color: Colors.amber.shade700,
                  icon: Icons.schedule,
                  label: 'Due Soon',
                  items: vm.warningItems,
                  initiallyExpanded: vm.dangerItems.isEmpty,
                ),
              if (vm.safeItems.isNotEmpty)
                _buildRiskSection(
                  theme,
                  color: Colors.green,
                  icon: Icons.check_circle,
                  label: 'Safe',
                  items: vm.safeItems,
                  initiallyExpanded: false,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSection(
    ThemeData theme, {
    required Color color,
    required IconData icon,
    required String label,
    required List<ReviewItem> items,
    bool initiallyExpanded = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: initiallyExpanded,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        '$label (${items.length})',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      children: items.map((item) {
        final reviewDate = DateTime(
          item.nextReviewDate.year,
          item.nextReviewDate.month,
          item.nextReviewDate.day,
        );
        final diff = reviewDate.difference(today).inDays;
        String daysLabel;
        if (diff < 0) {
          daysLabel = '${-diff} day${diff == -1 ? '' : 's'} overdue';
        } else if (diff == 0) {
          daysLabel = 'Due today';
        } else {
          daysLabel = 'In $diff day${diff == 1 ? '' : 's'}';
        }

        return ListTile(
          contentPadding: const EdgeInsets.only(left: 16),
          dense: true,
          title: Text(
            item.title,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: item.detail.isNotEmpty
              ? Text(
                  item.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                )
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              daysLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onTap: () => context.go('/review'),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmapCard(ProgressViewModel vm, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Study Heatmap',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (vm.currentStreak > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${vm.currentStreak}-day streak',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StudyHeatmapWidget(data: vm.heatmapData),
          ],
        ),
      ),
    );
  }
}
