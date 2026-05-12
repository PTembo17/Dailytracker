import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/stats_provider.dart';
import '../../shared/widgets/section_title.dart';
import 'widgets/history_list.dart';
import 'widgets/stat_card.dart';
import 'widgets/task_bar_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final logProvider = context.watch<LogProvider>();
    final statsProvider = context.watch<StatsProvider>();
    final month = calendarProvider.selectedMonth;
    final tasks = taskProvider.tasks;
    final logs = logProvider.logsByDate;
    final completion = statsProvider.completionRateForMonth(month);
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: calendarProvider.previousMonth,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      DateUtilsHelper.formatMonthYear(month),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: calendarProvider.nextMonth,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Stat cards 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('This month'),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        title: 'Completion',
                        value: '${completion.toStringAsFixed(0)}%',
                        subtitle: 'Month average',
                        rate: completion / 100,
                      ),
                      StatCard(
                        title: 'Perfect days',
                        value: '${statsProvider.perfectDaysCount(month)}',
                        subtitle: 'All tasks done',
                      ),
                      StatCard(
                        title: 'Top streak',
                        value: statsProvider.bestTaskByStreak(month),
                        subtitle: 'Most consistent',
                        small: true,
                      ),
                      StatCard(
                        title: 'Active tasks',
                        value: '${tasks.length}',
                        subtitle: 'Tracked daily',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle('Task completion rate'),
                  const SizedBox(height: AppSpacing.sm),
                  TaskBarChart(tasks: tasks, logsByDate: logs, month: month),

                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle('Previous months'),
                  const SizedBox(height: AppSpacing.sm),
                  HistoryList(logsByDate: logs, tasks: tasks, currentMonth: month),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
