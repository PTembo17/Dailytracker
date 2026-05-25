import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';
import '../core/utils/date_utils.dart';
import '../services/reminder_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  final List<Task> _tasks = [];

  TaskProvider(this._repository) {
    loadTasks();
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<void> loadTasks() async {
    _tasks.clear();
    _tasks.addAll(await _repository.getAllTasks());
    notifyListeners();
    // Reschedule all active reminders on every load (covers app restarts)
    await ReminderService.instance.rescheduleAll(_tasks);
  }

  // ── Add ──────────────────────────────────────────────────────────────────
  Future<void> addTask(String name) async {
    final task = Task(
      id: const Uuid().v4(),
      name: name,
      position: _tasks.length,
      createdAt: DateUtilsHelper.ymd(DateTime.now()),
    );
    await _repository.addTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  // ── Remove ───────────────────────────────────────────────────────────────
  Future<void> removeTask(String id, {void Function(String)? onRemoved}) async {
    // Cancel any live reminder before deleting
    await ReminderService.instance.cancelReminder(id);
    await _repository.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    // Notify other providers (e.g. LogProvider) to purge in-memory data
    onRemoved?.call(id);
  }

  // ── Reorder ──────────────────────────────────────────────────────────────
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    for (var i = 0; i < _tasks.length; i++) {
      _tasks[i] = _tasks[i].copyWith(position: i);
      await _repository.updateTask(_tasks[i]);
    }
    notifyListeners();
  }

  // ── Reminder: set time + enabled ─────────────────────────────────────────
  /// Set [reminderTime] (e.g. "07:30") and enable the reminder for [taskId].
  Future<void> setReminder(String taskId, String reminderTime) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final updated =
        _tasks[idx].copyWith(reminderTime: reminderTime, reminderEnabled: true);
    _tasks[idx] = updated;
    await _repository.updateReminder(taskId, reminderTime, true);
    await ReminderService.instance.scheduleReminder(updated);
    notifyListeners();
  }

  // ── Reminder: toggle enabled/disabled ────────────────────────────────────
  Future<void> toggleReminder(String taskId, bool enabled) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final updated = _tasks[idx].copyWith(reminderEnabled: enabled);
    _tasks[idx] = updated;
    await _repository.updateReminder(
        taskId, updated.reminderTime, enabled);

    if (enabled) {
      await ReminderService.instance.scheduleReminder(updated);
    } else {
      await ReminderService.instance.cancelReminder(taskId);
    }
    notifyListeners();
  }

  // ── Reminder: clear ──────────────────────────────────────────────────────
  Future<void> clearReminder(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final updated =
        _tasks[idx].copyWith(clearReminderTime: true, reminderEnabled: false);
    _tasks[idx] = updated;
    await _repository.updateReminder(taskId, null, false);
    await ReminderService.instance.cancelReminder(taskId);
    notifyListeners();
  }
}
