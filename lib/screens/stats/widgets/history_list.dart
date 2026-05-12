import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task.dart';
import '../../../data/models/task_log.dart';

class HistoryList extends StatelessWidget {
  final Map<String, List<TaskLog>> logsByDate;
  final List<Task> tasks;
  final DateTime currentMonth;

  const HistoryList({
    super.key,
    required this.logsByDate,
    required this.tasks,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build the list of months (excluding current month), sorted newest first
    final currentKey = DateUtilsHelper.monthKey(currentMonth);
    final months = logsByDate.keys
        .map((key) => key.substring(0, 7))
        .toSet()
        .where((m) => m != currentKey)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (months.isEmpty) {
      return Text(
        'No previous months yet',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      );
    }

    return Column(
      children: months.map((monthKey) {
        final days = logsByDate.entries.where((e) => e.key.startsWith(monthKey)).toList();
        final totalDays = days.length;
        double score = 0.0;
        if (tasks.isNotEmpty && totalDays > 0) {
          final total = days.fold<int>(
              0,
              (sum, entry) =>
                  sum + entry.value.where((log) => log.completed).length);
          score = total / (totalDays * tasks.length);
        }

        final color = AppColors.scoreColor(score);
        final pct = (score * 100).round();
        final label = DateUtilsHelper.formatMonthYear(DateTime.parse('$monthKey-01'));

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  label.split(' ').first, // "May", "April" etc.
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 5,
                    color: color,
                    backgroundColor: cs.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 32,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
