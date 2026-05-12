import 'package:sqflite/sqflite.dart';
import '../local/database_helper.dart';
import '../models/task_log.dart';

class LogRepository {
  final DatabaseHelper _dbHelper;

  LogRepository(this._dbHelper);

  Future<List<TaskLog>> getAllLogs() async {
    final db = await _dbHelper.database;
    final rows = await db.query('task_logs');
    return rows.map((map) => TaskLog.fromMap(map)).toList();
  }

  Future<List<TaskLog>> getLogsForDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query('task_logs', where: 'log_date = ?', whereArgs: [date]);
    return rows.map((map) => TaskLog.fromMap(map)).toList();
  }

  Future<List<TaskLog>> getLogsForMonth(String yearMonth) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'task_logs',
      where: 'log_date LIKE ?',
      whereArgs: ['$yearMonth-%'],
    );
    return rows.map((map) => TaskLog.fromMap(map)).toList();
  }

  Future<void> upsertLog(TaskLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      'task_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLogsForTask(String taskId) async {
    final db = await _dbHelper.database;
    await db.delete('task_logs', where: 'task_id = ?', whereArgs: [taskId]);
  }
}
