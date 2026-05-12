import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/task.dart';
import '../../../data/models/task_log.dart';

class TaskBarChart extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, List<TaskLog>> logsByDate;
  final DateTime month;

  const TaskBarChart({
    super.key,
    required this.tasks,
    required this.logsByDate,
    required this.month,
  });

  double _completionRate(Task task) {
    final monthKey =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final monthLogs = logsByDate.entries
        .where((e) => e.key.startsWith(monthKey))
        .expand((e) => e.value)
        .where((log) => log.taskId == task.id)
        .toList();
    if (monthLogs.isEmpty) return 0;
    return monthLogs.where((log) => log.completed).length / monthLogs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Text(
        'No tasks to show',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    final sorted = [...tasks]
      ..sort((a, b) => _completionRate(b).compareTo(_completionRate(a)));

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: sorted.map((task) {
        final rate = _completionRate(task);
        final pct = (rate * 100).round();
        final color = AppColors.scoreColor(rate);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(task.name,
                      style: TextStyle(fontSize: 12, color: cs.onSurface)),
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 5,
                  color: color,
                  backgroundColor: cs.outline.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
