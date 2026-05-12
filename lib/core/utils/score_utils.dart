import '../../data/models/task_log.dart';

class ScoreUtils {
  static double dailyScore(List<TaskLog> logs, int totalTasks) {
    if (totalTasks == 0) return 0;
    final done = logs.where((l) => l.completed).length;
    return done / totalTasks;
  }

  static double monthlyScore(Map<String, List<TaskLog>> logsByDay, int totalTasks) {
    if (logsByDay.isEmpty || totalTasks == 0) return 0;
    final scores = logsByDay.values.map((logs) => dailyScore(logs, totalTasks));
    return scores.reduce((a, b) => a + b) / logsByDay.length;
  }

  static int taskStreak(String taskId, DateTime from, Map<String, List<TaskLog>> logsByDate) {
    int streak = 0;
    var cursor = DateTime(from.year, from.month, from.day);
    while (true) {
      final key = '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      final logs = logsByDate[key];
      if (logs == null) break;
      final log = logs.firstWhere(
        (entry) => entry.taskId == taskId,
        orElse: () => TaskLog.empty(),
      );
      if (!log.completed || log.id.isEmpty) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
