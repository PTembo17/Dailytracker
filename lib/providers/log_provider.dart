import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/task_log.dart';
import '../data/repositories/log_repository.dart';
import '../core/utils/date_utils.dart';

class LogProvider extends ChangeNotifier {
  final LogRepository _repository;
  final Map<String, List<TaskLog>> _logsByDate = {};

  LogProvider(this._repository) {
    loadLogs();
  }

  Map<String, List<TaskLog>> get logsByDate => Map.unmodifiable(_logsByDate);

  Future<void> loadLogs() async {
    _logsByDate.clear();
    final logs = await _repository.getAllLogs();
    for (final log in logs) {
      _logsByDate.putIfAbsent(log.logDate, () => []).add(log);
    }
    notifyListeners();
  }

  /// Remove all in-memory log entries for [taskId] after it has been deleted.
  /// The DB rows are already removed by SQLite's ON DELETE CASCADE; this
  /// keeps the in-memory map in sync so the UI rebuilds correctly.
  void removeLogsForTask(String taskId) {
    for (final key in _logsByDate.keys.toList()) {
      _logsByDate[key]?.removeWhere((log) => log.taskId == taskId);
      if (_logsByDate[key]?.isEmpty == true) {
        _logsByDate.remove(key);
      }
    }
    notifyListeners();
  }

  Future<void> toggleTask(String taskId, DateTime date) async {
    final key = DateUtilsHelper.ymd(date);
    final logs = _logsByDate[key] ?? [];
    final existing = logs.firstWhere(
      (entry) => entry.taskId == taskId,
      orElse: () => TaskLog.empty(),
    );
    final next = TaskLog(
      id: existing.id.isNotEmpty ? existing.id : const Uuid().v4(),
      taskId: taskId,
      logDate: key,
      completed: !existing.completed,
    );
    await _repository.upsertLog(next);
    final updated = logs.where((entry) => entry.taskId != taskId).toList();
    updated.add(next);
    _logsByDate[key] = updated;
    notifyListeners();
  }
}
