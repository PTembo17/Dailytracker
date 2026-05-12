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
