import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/task_provider.dart';
import 'day_cell.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final void Function(DateTime) onTapDay;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final logProvider = context.watch<LogProvider>();
    final firstOffset = DateUtilsHelper.firstDayOffset(month);
    final days = DateUtilsHelper.monthDays(month);
    final today = DateUtilsHelper.ymd(DateTime.now());
    final cs = Theme.of(context).colorScheme;

    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Weekday headers
        Row(
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        // Day grid
        GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 0.72,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          children: [
            // Leading empty cells
            ...List.generate(firstOffset, (_) => const SizedBox()),

            // Day cells
            ...days.map((date) {
              final key = DateUtilsHelper.ymd(date);
              final logs = logProvider.logsByDate[key] ?? [];
              final isToday = today == key;
              final isFuture = date.isAfter(DateTime.now());
              final isSelected = DateUtilsHelper.ymd(selectedDay) == key;

              return GestureDetector(
                onTap: isFuture ? null : () => onTapDay(date),
                child: DayCell(
                  date: date,
                  logs: logs,
                  totalTasks: taskProvider.tasks.length,
                  isToday: isToday,
                  isFuture: isFuture,
                  selected: isSelected,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
