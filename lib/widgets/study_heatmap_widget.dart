import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudyHeatmapWidget extends StatelessWidget {
  final Map<String, int> data; // date string (yyyy-MM-dd) → seconds
  final int weeks;

  const StudyHeatmapWidget({
    super.key,
    required this.data,
    this.weeks = 52,
  });

  static const _cellSize = 14.0;
  static const _cellGap = 2.0;

  Color _colorForSeconds(int seconds, ColorScheme colorScheme) {
    if (seconds <= 0) return colorScheme.surfaceContainerHighest;
    if (seconds < 1800) return const Color(0xFF9BE9A8); // <30m
    if (seconds < 3600) return const Color(0xFF40C463); // <1h
    if (seconds < 7200) return const Color(0xFF30A14E); // <2h
    return const Color(0xFF216E39); // ≥2h
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy-MM-dd');

    // Calculate the grid starting from (weeks) weeks ago, aligned to Monday
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // End on this week's Sunday
    final endDate = today.add(Duration(days: 7 - today.weekday));
    // Start from (weeks) weeks before endDate's Monday
    final startDate = endDate.subtract(Duration(days: weeks * 7 - 1));

    // Build month labels
    final monthLabels = <_MonthLabel>[];
    int? lastMonth;
    for (int w = 0; w < weeks; w++) {
      final colDate = startDate.add(Duration(days: w * 7));
      if (colDate.month != lastMonth) {
        lastMonth = colDate.month;
        monthLabels.add(_MonthLabel(
          column: w,
          label: DateFormat('MMM').format(colDate),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: SizedBox(
            height: 16,
            child: Stack(
              children: monthLabels.map((m) {
                return Positioned(
                  left: m.column * (_cellSize + _cellGap),
                  child: Text(
                    m.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Grid with day labels
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day of week labels
            Column(
              children: [
                const SizedBox(height: 0), // Mon
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Text('', style: TextStyle(fontSize: 9)),
                ),
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tue',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Text('', style: TextStyle(fontSize: 9)),
                ),
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Thu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Text('', style: TextStyle(fontSize: 9)),
                ),
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // Heatmap grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeks, (w) {
                    return Column(
                      children: List.generate(7, (d) {
                        final date =
                            startDate.add(Duration(days: w * 7 + d));
                        if (date.isAfter(today)) {
                          return SizedBox(
                            width: _cellSize + _cellGap,
                            height: _cellSize + _cellGap,
                          );
                        }
                        final key = fmt.format(date);
                        final seconds = data[key] ?? 0;
                        return Tooltip(
                          message: seconds > 0
                              ? '$key: ${(seconds / 60).round()}m'
                              : '$key: No study',
                          child: Container(
                            width: _cellSize,
                            height: _cellSize,
                            margin: const EdgeInsets.all(_cellGap / 2),
                            decoration: BoxDecoration(
                              color: _colorForSeconds(
                                  seconds, theme.colorScheme),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        // Legend
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            _legendBox(theme.colorScheme.surfaceContainerHighest),
            _legendBox(const Color(0xFF9BE9A8)),
            _legendBox(const Color(0xFF40C463)),
            _legendBox(const Color(0xFF30A14E)),
            _legendBox(const Color(0xFF216E39)),
            const SizedBox(width: 4),
            Text(
              'More',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _MonthLabel {
  final int column;
  final String label;
  const _MonthLabel({required this.column, required this.label});
}
