class TaskLog {
  final String id;
  final String taskId;
  final String logDate;
  final bool completed;

  TaskLog({
    required this.id,
    required this.taskId,
    required this.logDate,
    required this.completed,
  });

  factory TaskLog.fromMap(Map<String, dynamic> map) {
    return TaskLog(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      logDate: map['log_date'] as String,
      completed: (map['completed'] as int) == 1,
    );
  }

  factory TaskLog.empty() {
    return TaskLog(id: '', taskId: '', logDate: '', completed: false);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'log_date': logDate,
      'completed': completed ? 1 : 0,
    };
  }
}
