import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/score_utils.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/streak_badge.dart';

class TodayTaskList extends StatelessWidget {
  final DateTime selectedDay;

  const TodayTaskList({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final logProvider = context.watch<LogProvider>();
    final selectedKey = DateUtilsHelper.ymd(selectedDay);
    final logs = logProvider.logsByDate[selectedKey] ?? [];
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Tasks'),
              Text(
                selectedKey,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (taskProvider.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No tasks yet — add one in the Tasks tab',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ...taskProvider.tasks.map((task) {
              final completed =
                  logs.any((log) => log.taskId == task.id && log.completed);
              final streak = ScoreUtils.taskStreak(
                  task.id, selectedDay, logProvider.logsByDate);

              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: cs.outline.withValues(alpha: 0.5),
                          width: 0.5)),
                ),
                child: InkWell(
                  onTap: () =>
                      context.read<LogProvider>().toggleTask(task.id, selectedDay),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Custom checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: completed
                                ? AppColors.green400
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: completed
                                  ? AppColors.green400
                                  : cs.outline,
                              width: 1.5,
                            ),
                          ),
                          child: completed
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: completed
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        StreakBadge(streak: streak),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
