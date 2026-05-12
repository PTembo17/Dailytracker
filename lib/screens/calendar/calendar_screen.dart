import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/task_provider.dart';
import '../../shared/widgets/score_pill.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/today_progress_bar.dart';
import 'widgets/today_task_list.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final logProvider = context.watch<LogProvider>();
    final statsProvider = context.watch<StatsProvider>();

    final selectedMonth = calendarProvider.selectedMonth;
    final selectedDay = calendarProvider.selectedDay;
    final todayKey = DateUtilsHelper.ymd(DateTime.now());
    final todayLogs = logProvider.logsByDate[todayKey] ?? [];
    final totalTasks = taskProvider.tasks.length;
    final doneToday = todayLogs.where((log) => log.completed).length;
    final monthRate = statsProvider.completionRateForMonth(selectedMonth) / 100;

    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // ── Header: month nav + score pill ──────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
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
                    DateUtilsHelper.formatMonthYear(selectedMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                const SizedBox(width: AppSpacing.sm),
                ScorePill(
                  label: '${statsProvider.completionRateForMonth(selectedMonth).toStringAsFixed(0)}%',
                  value: '',
                  rate: monthRate,
                ),
              ],
            ),
          ),

          // ── Today progress bar ──────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: TodayProgressBar(done: doneToday, total: totalTasks),
          ),

          const Divider(height: 1),

          // ── Calendar grid ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: CalendarGrid(
                      month: selectedMonth,
                      selectedDay: selectedDay,
                      onTapDay: calendarProvider.selectDay,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1),
                  TodayTaskList(selectedDay: selectedDay),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
