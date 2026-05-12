import '../local/database_helper.dart';
import '../models/task.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper;

  TaskRepository(this._dbHelper);

  Future<List<Task>> getAllTasks() async {
    final db = await _dbHelper.database;
    final rows = await db.query('tasks', orderBy: 'position ASC');
    return rows.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> addTask(Task task) async {
    final db = await _dbHelper.database;
    await db.insert('tasks', task.toMap());
  }

  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTask(Task task) async {
    final db = await _dbHelper.database;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  /// Persist only the reminder columns (time + enabled flag).
  Future<void> updateReminder(
      String taskId, String? reminderTime, bool enabled) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'reminder_time': reminderTime,
        'reminder_enabled': enabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
