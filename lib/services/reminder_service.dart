import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/task.dart';

/// ReminderService wires two behaviours per task reminder:
///
///   1. NOTIFICATION  — fired 10 minutes before the reminder time via the
///      Android system notification channel (high importance, heads-up).
///
///   2. ALARM         — fired exactly at the reminder time via a full-screen
///      intent / alarm-style notification that behaves like a phone alarm
///      (plays the default alarm sound, wakes the screen, shows even when the
///      phone is locked).
///
/// Notification IDs are derived from the task UUID so they are stable across
/// app restarts:
///
///   notificationId  = (taskId hashCode).abs() % 100000         (10-min alert)
///   alarmId         = (taskId hashCode).abs() % 100000 + 100000 (alarm)
///
/// The service is a singleton — initialise once in main() and inject via
/// Provider or pass directly.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Notification channel IDs ────────────────────────────────────────────
  static const _channelIdAlert = 'task_reminder_alert';
  static const _channelIdAlarm = 'task_reminder_alarm';

  // ── Initialisation ──────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialised) return;

    // Load timezone database (needed for exact scheduling)
    tz_data.initializeTimeZones();
    // Use the device's local timezone
    final localTz = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();

    // Request exact-alarm permission (Android 12+) and notification permission
    if (Platform.isAndroid) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    _initialised = true;
  }

  // ── Channel setup ───────────────────────────────────────────────────────
  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // High-importance channel for the 10-minute warning
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdAlert,
        'Task Reminders',
        description: 'Notifies you 10 minutes before a task reminder fires',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Max-importance channel for the alarm-style notification
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdAlarm,
        'Task Alarms',
        description: 'Full alarm that fires exactly at the reminder time',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // Uses the system default alarm sound
        sound: RawResourceAndroidNotificationSound('default_alarm'),
      ),
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Schedule (or reschedule) both a 10-min warning and an alarm notification
  /// for [task]. Does nothing if [task.reminderTime] is null or
  /// [task.reminderEnabled] is false.
  Future<void> scheduleReminder(Task task) async {
    await _ensureInit();
    // Cancel any existing reminders for this task first
    await cancelReminder(task.id);

    if (!task.reminderEnabled || task.reminderTime == null) return;

    final parts = task.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final now = tz.TZDateTime.now(tz.local);

    // Build the target datetime for today; if already past, schedule tomorrow
    tz.TZDateTime alarmTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alertTime = alarmTime.subtract(const Duration(minutes: 10));
    final alertId = _notificationId(task.id);
    final alarmId = _alarmId(task.id);

    // 10-minute warning (only if still in the future)
    if (alertTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        alertId,
        '⏰ Coming up: ${task.name}',
        'Reminder fires in 10 minutes',
        alertTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelIdAlert,
            'Task Reminders',
            channelDescription: '10-minute advance warning',
            importance: Importance.high,
            priority: Priority.high,
            ticker: task.name,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Alarm at the exact time
    await _plugin.zonedSchedule(
      alarmId,
      '🔔 ${task.name}',
      "It's time! Tap to mark this task done.",
      alarmTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdAlarm,
          'Task Alarms',
          channelDescription: 'Alarm at reminder time',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,   // wakes screen like an alarm
          category: AndroidNotificationCategory.alarm,
          ticker: task.name,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock, // uses AlarmManager
      matchDateTimeComponents: DateTimeComponents.time,     // repeat daily
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
        '[ReminderService] Scheduled "${task.name}" alert=$alertId '
        'alarm=$alarmId at $alarmTime');
  }

  /// Cancel both the warning and alarm notifications for the given [taskId].
  Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(_notificationId(taskId));
    await _plugin.cancel(_alarmId(taskId));
    debugPrint('[ReminderService] Cancelled reminders for taskId=$taskId');
  }

  /// Re-schedule all tasks that have an active reminder.
  /// Call this on app startup after loading tasks so reminders survive reboots.
  Future<void> rescheduleAll(List<Task> tasks) async {
    await _ensureInit();
    for (final task in tasks) {
      if (task.reminderEnabled && task.reminderTime != null) {
        await scheduleReminder(task);
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Future<void> _ensureInit() async {
    if (!_initialised) await init();
  }

  int _notificationId(String taskId) =>
      taskId.hashCode.abs() % 100000;

  int _alarmId(String taskId) =>
      taskId.hashCode.abs() % 100000 + 100000;

  void _onNotificationTap(NotificationResponse response) {
    // The app is brought to foreground; deep-link logic can go here later.
    debugPrint('[ReminderService] Notification tapped: ${response.payload}');
  }
}
