// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/update_service.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/task_provider.dart';
import '../../services/export_service.dart';
import '../../services/reminder_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindDaily = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _exporting = false;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _remindDaily = prefs.getBool('remind_daily') ?? false;
      _reminderTime = TimeOfDay(
        hour: prefs.getInt('reminder_hour') ?? 20,
        minute: prefs.getInt('reminder_minute') ?? 0,
      );
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remind_daily', _remindDaily);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
        context: context, initialTime: _reminderTime);
    if (time != null) {
      setState(() => _reminderTime = time);
      await _savePreferences();
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await ExportService.instance.exportToExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export ready — use the share sheet to save or send the file.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data'),
        content: const Text(
            'This will permanently delete all tasks, logs and reminders. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset',
                  style: TextStyle(color: AppColors.red400))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final tasks = context.read<TaskProvider>().tasks;
      for (final t in tasks) {
        await ReminderService.instance.cancelReminder(t.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data and reminders have been reset')),
      );
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> _manualCheckUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    try {
      final update = await UpdateService.checkForUpdate();
      if (!mounted) return;
      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest version.')),
        );
        return;
      }
      final apkUrl = update['apk_url'] as String?;
      final releaseNotes =
          update['release_notes'] as String? ?? 'A new version is ready.';
      final newVersion = update['version'] as String? ?? '';
      if (apkUrl == null) return;

      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
              'Update available${newVersion.isNotEmpty ? ' — v$newVersion' : ''}'),
          content: Text(releaseNotes),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                UpdateService.downloadAndInstall(
                  apkUrl,
                  onError: (err) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Update failed: $err')),
                      );
                    }
                  },
                );
              },
              child: const Text('Update now'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final cs = Theme.of(context).colorScheme;

    final reminderTasks = taskProvider.tasks
        .where((t) => t.reminderEnabled && t.reminderTime != null)
        .toList();

    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Text('Settings',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),

          const Divider(height: 1),

          // ── Global daily reminder ────────────────────────────────────────
          _sectionHeader('Global reminder', context),

          SwitchListTile(
            secondary:
                Icon(Icons.notifications_outlined, color: cs.primary),
            title: const Text('Daily reminder'),
            subtitle: const Text('One reminder covering all tasks'),
            value: _remindDaily,
            onChanged: (v) async {
              setState(() => _remindDaily = v);
              await _savePreferences();
            },
          ),

          ListTile(
            leading: Icon(Icons.access_time_outlined,
                color: _remindDaily ? cs.primary : cs.onSurfaceVariant),
            title: const Text('Reminder time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            enabled: _remindDaily,
            onTap: _remindDaily ? _pickTime : null,
          ),

          const Divider(height: 1),

          // ── Per-task reminders summary ───────────────────────────────────
          _sectionHeader('Per-task reminders', context),

          if (reminderTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Text(
                'No per-task reminders set. Open the Tasks tab, tap '
                'the alarm icon on any task to set one.',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
              ),
            )
          else ...[
            ...reminderTasks.map((task) {
              final parts = task.reminderTime!.split(':');
              final h = int.parse(parts[0]);
              final m = parts[1];
              final period = h >= 12 ? 'PM' : 'AM';
              final hour = h % 12 == 0 ? 12 : h % 12;
              final timeLabel = '$hour:$m $period';

              return ListTile(
                leading: const Icon(Icons.alarm_on_rounded,
                    color: AppColors.blue400),
                title: Text(task.name,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                    '🔔 Alarm at $timeLabel · '
                    '⏰ Warning at 10 min before',
                    style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove reminder',
                  onPressed: () =>
                      context.read<TaskProvider>().clearReminder(task.id),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Text(
                '${reminderTasks.length} task reminder'
                '${reminderTasks.length == 1 ? '' : 's'} active',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],

          const Divider(height: 1),

          // ── Data ─────────────────────────────────────────────────────────
          _sectionHeader('Data', context),

          // Export to Excel
          ListTile(
            leading: _exporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.file_download_outlined, color: cs.primary),
            title: Text(
              'Export data to Excel',
              style: TextStyle(color: cs.secondary),
            ),
            subtitle: const Text(
                'Saves tasks & logs as an .xlsx file — two sheets'),
            trailing: Icon(Icons.chevron_right, color: cs.primary),
            onTap: _exporting ? null : _exportData,
          ),

          // Reset all data
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.red400),
            title: const Text('Reset all data',
                style: TextStyle(color: AppColors.red400)),
            subtitle: const Text(
                'Delete all tasks, logs and reminders permanently'),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.red400),
            onTap: _resetData,
          ),

          const Divider(height: 1),

          // ── About ─────────────────────────────────────────────────────────
          _sectionHeader('About', context),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Daily Task Tracker'),
            subtitle: Text('Version 1.0.0'),
          ),

          // Check for updates
          ListTile(
            leading: _checkingUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_outlined),
            title: const Text('Check for updates'),
            subtitle: const Text('Download and install the latest APK'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _checkingUpdate ? null : _manualCheckUpdate,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
