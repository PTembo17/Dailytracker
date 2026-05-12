import 'package:flutter/material.dart';
import '../core/utils/score_utils.dart';
import '../data/models/task.dart';
import '../data/models/task_log.dart';
import '../data/models/month_stats.dart';

class StatsProvider extends ChangeNotifier {
  late List<Task> _tasks;
  late Map<String, List<TaskLog>> _logsByDate;
  MonthStats? _currentMonthStats;

  StatsProvider(List<Task> tasks, Map<String, List<TaskLog>> logsByDate) {
    _tasks = tasks;
    _logsByDate = Map.unmodifiable(logsByDate);
  }

  MonthStats? get monthStats => _currentMonthStats;

  void update(List<Task> tasks, Map<String, List<TaskLog>> logsByDate) {
    _tasks = tasks;
    _logsByDate = logsByDate;
    notifyListeners();
  }

  double completionRateForMonth(DateTime month) {
    final key = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final logs = _logsByDate.entries
        .where((entry) => entry.key.startsWith(key))
        .map((entry) => entry.value)
        .toList();
    final logsByDay = {for (var entry in logsByDayMap(logs).entries) entry.key: entry.value};
    return ScoreUtils.monthlyScore(logsByDay, _tasks.length) * 100;
  }

  Map<String, List<TaskLog>> logsByDayMap(List<List<TaskLog>> pockets) {
    final map = <String, List<TaskLog>>{};
    for (final bucket in pockets) {
      for (final log in bucket) {
        map.putIfAbsent(log.logDate, () => []).add(log);
      }
    }
    return map;
  }

  String bestTaskByStreak(DateTime month) {
    if (_tasks.isEmpty) return 'None';
    final streaks = <String, int>{};
    final monthStr = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final days = _logsByDate.entries.where((entry) => entry.key.startsWith(monthStr)).map((e) => e.key);
    for (var task in _tasks) {
      int streak = 0;
      for (var day in days) {
        final logs = _logsByDate[day] ?? [];
        final log = logs.firstWhere((entry) => entry.taskId == task.id, orElse: () => TaskLog.empty());
        if (log.completed) {
          streak++;
        }
      }
      streaks[task.name] = streak;
    }
    final sorted = streaks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty ? 'None' : sorted.first.key;
  }

  int perfectDaysCount(DateTime month) {
    final key = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final days = _logsByDate.keys.where((date) => date.startsWith(key));
    int count = 0;
    for (var day in days) {
      final logs = _logsByDate[day]!;
      if (logs.every((log) => log.completed) && logs.length == _tasks.length && _tasks.isNotEmpty) {
        count++;
      }
    }
    return count;
  }
}
