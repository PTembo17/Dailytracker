import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/score_utils.dart';
import '../../../data/models/task_log.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final List<TaskLog> logs;
  final int totalTasks;
  final bool isToday;
  final bool isFuture;
  final bool selected;

  const DayCell({
    super.key,
    required this.date,
    required this.logs,
    required this.totalTasks,
    required this.isToday,
    required this.isFuture,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = ScoreUtils.dailyScore(logs, totalTasks);
    final doneCount = logs.where((log) => log.completed).length;
    final scoreColor = AppColors.scoreColor(score);

    Color borderColor = cs.outline.withValues(alpha: 0.5);
    Color bgColor = cs.surface;

    if (isToday) {
      borderColor = AppColors.blue400;
      bgColor = cs.surface;
    } else if (selected) {
      bgColor = cs.surfaceContainerHighest;
      borderColor = cs.primary.withValues(alpha: 0.4);
    }

    return Opacity(
      opacity: isFuture ? 0.35 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.radiusMd,
          border: Border.all(
            color: borderColor,
            width: isToday ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Text(
              date.day.toString(),
              style: AppTextStyles.dayNumber.copyWith(
                color: isToday ? AppColors.blue600 : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            // Dots
            if (!isFuture)
              Wrap(
                spacing: 1.5,
                runSpacing: 1.5,
                children: List.generate(totalTasks, (index) {
                  final filled = index < doneCount;
                  return Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: filled ? AppColors.green400 : AppColors.gray200,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  );
                }),
              ),
            const Spacer(),
            // Score label
            if (!isFuture && totalTasks > 0)
              Text(
                '$doneCount/$totalTasks',
                style: AppTextStyles.dotScore.copyWith(color: scoreColor),
              ),
          ],
        ),
      ),
    );
  }
}
