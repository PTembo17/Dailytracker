// lib/screens/tasks/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/score_utils.dart';
import '../../providers/log_provider.dart';
import '../../providers/task_provider.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/reminder_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static Future<void> showAddTaskSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final logProvider = context.watch<LogProvider>();
    final today = DateTime.now();
    final todayKey = DateUtilsHelper.ymd(today);
    final todayLogs = logProvider.logsByDate[todayKey] ?? [];
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tasks',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                Text(
                  '${taskProvider.tasks.length} tasks',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),

          // ── Task list ────────────────────────────────────────────────────
          Expanded(
            child: taskProvider.tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('No tasks yet',
                            style:
                                TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => showAddTaskSheet(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add your first task'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: taskProvider.tasks.length,
                    onReorder: taskProvider.reorderTasks,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      final completed = todayLogs.any(
                          (log) =>
                              log.taskId == task.id && log.completed);
                      final streak = ScoreUtils.taskStreak(
                          task.id, today, logProvider.logsByDate);
                      final hasReminder =
                          task.reminderEnabled &&
                              task.reminderTime != null;

                      return _TaskTile(
                        key: ValueKey(task.id),
                        taskId: task.id,
                        taskName: task.name,
                        completed: completed,
                        streak: streak,
                        hasReminder: hasReminder,
                        reminderTime: task.reminderTime,
                        onToggle: () => context
                            .read<LogProvider>()
                            .toggleTask(task.id, today),
                        onDelete: () => _confirmDelete(
                            context, task.id, task.name,
                            hasReminder: hasReminder,
                            reminderTime: task.reminderTime),
                        onReminderTap: () =>
                            ReminderSheet.show(context, task),
                      );
                    },
                  ),
          ),

          // ── Add task button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showAddTaskSheet(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add task'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                      color: cs.outline.withValues(alpha: 0.7)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String id, String name,
      {bool hasReminder = false, String? reminderTime}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "$name"? All logs will be removed.'),
            if (hasReminder && reminderTime != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.alarm_off_outlined,
                      size: 15, color: AppColors.red400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The reminder set for $reminderTime will also be cancelled.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.red400),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.red400))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TaskProvider>().removeTask(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasReminder
                        ? '"$name" deleted — reminder cancelled.'
                        : '"$name" deleted.',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red400,
          ),
        );
      }
    }
  }
}

// ── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  final String taskId;
  final String taskName;
  final bool completed;
  final int streak;
  final bool hasReminder;
  final String? reminderTime;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onReminderTap;

  const _TaskTile({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.completed,
    required this.streak,
    required this.hasReminder,
    required this.reminderTime,
    required this.onToggle,
    required this.onDelete,
    required this.onReminderTap,
  });

  String _fmtTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismissible_$taskId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.red400,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // let _confirmDelete handle the actual removal
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: cs.outline.withValues(alpha: 0.4), width: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 10),
            child: Row(
              children: [
                // ── Animated checkbox ────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.green400
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          completed ? AppColors.green400 : cs.outline,
                      width: 1.5,
                    ),
                  ),
                  child: completed
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: AppSpacing.md),

                // ── Task name + reminder badge ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
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
                      if (hasReminder && reminderTime != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.alarm,
                                size: 11,
                                color: AppColors.blue400),
                            const SizedBox(width: 3),
                            Text(
                              _fmtTime(reminderTime!),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.blue400,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Streak badge ─────────────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: streak >= 14
                            ? AppColors.green400
                            : streak >= 5
                                ? AppColors.amber400
                                : AppColors.red400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: AppSpacing.sm),

                // ── Alarm button ─────────────────────────────────────────
                GestureDetector(
                  onTap: onReminderTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      hasReminder
                          ? Icons.alarm_on_rounded
                          : Icons.alarm_add_outlined,
                      size: 20,
                      color: hasReminder
                          ? AppColors.blue400
                          : cs.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ── Delete button ─────────────────────────────────────────
                // Visible tap target in addition to swipe-to-delete
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.red400.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ── Drag handle ───────────────────────────────────────────
                Icon(Icons.drag_handle,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                    size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
