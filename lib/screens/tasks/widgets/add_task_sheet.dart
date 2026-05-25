import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/task_provider.dart';

/// Sheet for creating a new task.  Optionally lets the user set a reminder
/// right from creation by expanding a "Set reminder" section.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  TimeOfDay? _reminderTime;
  bool _showReminderPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Reminder time',
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<TaskProvider>();
    await provider.addTask(name);

    // If user also set a reminder, apply it to the newly created task
    if (_reminderTime != null) {
      final newTask = provider.tasks.last;
      await provider.setReminder(newTask.id, _hhmm(_reminderTime!));
    }

    if (mounted) {
      // Show in-app notification before closing the sheet
      final reminderMsg = _reminderTime != null
          ? ' · reminder at ${_fmtTime(_reminderTime!)}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('"$name" added$reminderMsg'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: MediaQuery.of(context).viewInsets +
          const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text('New Task',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),

          // Task name field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'e.g. Morning exercise, Read 20 mins…',
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Optional reminder section ──────────────────────────────────
          InkWell(
            onTap: () {
              setState(
                  () => _showReminderPicker = !_showReminderPicker);
              if (_showReminderPicker && _reminderTime == null) {
                _pickTime();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: _reminderTime != null
                    ? AppColors.blue400.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: _reminderTime != null
                    ? Border.all(
                        color: AppColors.blue400.withValues(alpha: 0.3),
                        width: 0.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _reminderTime != null
                        ? Icons.alarm_on_rounded
                        : Icons.alarm_add_outlined,
                    size: 18,
                    color: _reminderTime != null
                        ? AppColors.blue400
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _reminderTime != null
                        ? 'Reminder at ${_fmtTime(_reminderTime!)}'
                        : 'Add reminder (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _reminderTime != null
                          ? AppColors.blue400
                          : cs.onSurfaceVariant,
                      fontWeight: _reminderTime != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (_reminderTime != null)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _reminderTime = null),
                      child: Icon(Icons.close,
                          size: 16, color: cs.onSurfaceVariant),
                    )
                  else
                    Icon(Icons.chevron_right,
                        size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),

          if (_reminderTime != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '10-min warning + alarm at ${_fmtTime(_reminderTime!)}',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}
