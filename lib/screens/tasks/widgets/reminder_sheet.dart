import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/task.dart';
import '../../../providers/task_provider.dart';

/// Bottom sheet for setting, toggling or clearing a reminder on a single task.
///
/// Shows:
///   • Current status pill (active / off)
///   • Time picker row
///   • 10-min warning explanation
///   • Enable / disable toggle
///   • Clear button
class ReminderSheet extends StatefulWidget {
  final Task task;

  const ReminderSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReminderSheet(task: task),
    );
  }

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late TimeOfDay _selectedTime;
  late bool _enabled;
  bool _hasTime = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.task.reminderEnabled;
    _hasTime = widget.task.reminderTime != null;

    if (widget.task.reminderTime != null) {
      final parts = widget.task.reminderTime!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      // Default to 8:00 AM as a sensible starting point
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Set reminder time',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasTime = true;
        _enabled = true;
      });
    }
  }

  Future<void> _save() async {
    final provider = context.read<TaskProvider>();
    if (_hasTime && _enabled) {
      await provider.setReminder(widget.task.id, _hhmm(_selectedTime));
    } else if (_hasTime && !_enabled) {
      await provider.toggleReminder(widget.task.id, false);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    await context.read<TaskProvider>().clearReminder(widget.task.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ─────────────────────────────────────────────────
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

          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.alarm_outlined, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.task.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (_hasTime && _enabled)
                      ? AppColors.green50
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_hasTime && _enabled) ? 'Active' : 'Off',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: (_hasTime && _enabled)
                        ? AppColors.green800
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Time picker row ────────────────────────────────────────────
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: cs.primary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder time',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasTime ? _fmt(_selectedTime) : 'Tap to set',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _hasTime ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── 10-min info banner ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blue400.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.blue400.withValues(alpha: 0.25),
                  width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.blue400),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You\'ll receive a notification 10 minutes before '
                    'the set time, then a full alarm sound when the '
                    'time arrives.',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.75),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Enable toggle (only visible when a time is set) ────────────
          if (_hasTime)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enable reminder',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      'Fires every day at ${_fmt(_selectedTime)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),

          if (_hasTime) const SizedBox(height: AppSpacing.lg),

          // ── Action buttons ─────────────────────────────────────────────
          Row(
            children: [
              if (_hasTime || widget.task.reminderTime != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red400,
                      side: const BorderSide(color: AppColors.red400),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (_hasTime || widget.task.reminderTime != null)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _hasTime ? _save : _pickTime,
                  icon: Icon(
                      _hasTime ? Icons.check : Icons.add_alarm_outlined,
                      size: 16),
                  label: Text(_hasTime ? 'Save reminder' : 'Set time first'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
