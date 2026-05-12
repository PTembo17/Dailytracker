import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final path = join(await getDatabasesPath(), fileName);
    return await openDatabase(
      path,
      version: 2,           // bumped from 1 → 2 for reminder columns
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── Fresh install ──────────────────────────────────────────────────────────
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id               TEXT PRIMARY KEY,
        name             TEXT NOT NULL,
        position         INTEGER NOT NULL DEFAULT 0,
        created_at       TEXT NOT NULL,
        reminder_time    TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_logs (
        id          TEXT PRIMARY KEY,
        task_id     TEXT NOT NULL,
        log_date    TEXT NOT NULL,
        completed   INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
        UNIQUE (task_id, log_date)
      )
    ''');
  }

  // ── Migrate existing v1 database ───────────────────────────────────────────
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reminder columns to existing tasks table
      await db.execute(
          'ALTER TABLE tasks ADD COLUMN reminder_time TEXT');
      await db.execute(
          'ALTER TABLE tasks ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 0');
    }
  }

  /// Wipe all user data (Settings → Reset).
  Future<void> clearAllData() async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.delete('task_logs');
    await db.delete('tasks');
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
