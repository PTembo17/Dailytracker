// lib/services/export_service.dart
//
// Exports all task data plus the same per-task statistics that the
// Stats screen shows (completion rate, current streak, perfect-day
// contribution, best month, total completions) to a single-sheet
// Excel workbook (.xlsx).

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/local/database_helper.dart';
import '../data/models/task_log.dart';
import '../core/utils/score_utils.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── Public entry point ───────────────────────────────────────────────────

  /// Builds an Excel workbook and triggers the system share sheet.
  /// Returns the path of the saved file, or throws on error.
  Future<String> exportToExcel() async {
    final db = await DatabaseHelper.instance.database;

    // ── 1. Fetch raw data ──────────────────────────────────────────────────
    final taskRows = await db.query('tasks', orderBy: 'position ASC');
    final logRows  = await db.query('task_logs', orderBy: 'log_date ASC');

    // Build logsByDate map  (same structure used throughout the app)
    final logsByDate = <String, List<TaskLog>>{};
    for (final row in logRows) {
      final log = TaskLog.fromMap(row);
      logsByDate.putIfAbsent(log.logDate, () => []).add(log);
    }

    // All unique date keys
    final allDates = logsByDate.keys.toList()..sort();

    // ── 2. Build workbook ──────────────────────────────────────────────────
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Tasks & Stats');

    _buildSheet(excel['Tasks & Stats'], taskRows, logsByDate, allDates);

    // ── 3. Write to disk ───────────────────────────────────────────────────
    final dir   = await getApplicationDocumentsDirectory();
    final now   = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
    final path  = '${dir.path}/dailytracker_export_$stamp.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding returned null');
    await File(path).writeAsBytes(bytes, flush: true);

    // ── 4. Share ───────────────────────────────────────────────────────────
    await Share.shareXFiles(
      [
        XFile(
          path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      ],
      subject: 'Daily Tracker export $stamp',
    );

    return path;
  }

  // ── Sheet builder ────────────────────────────────────────────────────────

  void _buildSheet(
    Sheet sheet,
    List<Map<String, dynamic>> taskRows,
    Map<String, List<TaskLog>> logsByDate,
    List<String> allDates,
  ) {
    // ── Header ──────────────────────────────────────────────────────────────
    const headers = [
      // Task info
      'Task ID',
      'Task Name',
      'Created At',
      'Reminder Time',
      'Reminder Enabled',
      // Stats (mirror the Stats screen)
      'Total Log Days',
      'Total Completions',
      'All-Time Completion %',
      'Current Streak',
      'Best Month',
      'Best Month Completion %',
    ];

    _writeRow(sheet, 0, headers, bold: true);

    // Column widths
    const widths = [38.0, 28.0, 14.0, 14.0, 16.0,
                    14.0, 16.0, 22.0, 14.0, 12.0, 24.0];
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

    // ── Data rows ───────────────────────────────────────────────────────────
    final today = DateTime.now();

    for (var rowIdx = 0; rowIdx < taskRows.length; rowIdx++) {
      final r      = taskRows[rowIdx];
      final taskId = r['id'] as String;

      // 1. Total log days & completions (all-time)
      int totalLogDays     = 0;
      int totalCompletions = 0;
      for (final date in allDates) {
        final log = _findLog(logsByDate[date] ?? [], taskId);
        if (log != null) {
          totalLogDays++;
          if (log.completed) totalCompletions++;
        }
      }

      // 2. All-time completion %
      final allTimeRate = totalLogDays == 0
          ? 0.0
          : (totalCompletions / totalLogDays) * 100;

      // 3. Current streak — reuses ScoreUtils.taskStreak (same as Stats screen)
      final currentStreak =
          ScoreUtils.taskStreak(taskId, today, logsByDate);

      // 4. Best month: find the YYYY-MM with the highest completion % for
      //    this task — mirrors the per-task bar chart logic in TaskBarChart
      final monthGroups = <String, _MonthAcc>{};
      for (final date in allDates) {
        final mk  = date.substring(0, 7); // "YYYY-MM"
        final log = _findLog(logsByDate[date] ?? [], taskId);
        if (log != null) {
          monthGroups.putIfAbsent(mk, () => _MonthAcc()).add(log.completed);
        }
      }

      String bestMonthKey  = '—';
      double bestMonthRate = 0.0;
      if (monthGroups.isNotEmpty) {
        final sorted = monthGroups.entries.toList()
          ..sort((a, b) => b.value.rate.compareTo(a.value.rate));
        bestMonthKey  = sorted.first.key;
        bestMonthRate = sorted.first.value.rate * 100;
      }

      // ── Write row ────────────────────────────────────────────────────────
      _writeRow(sheet, rowIdx + 1, [
        taskId,
        r['name'],
        r['created_at'],
        r['reminder_time'] ?? '',
        (r['reminder_enabled'] as int? ?? 0) == 1 ? 'Yes' : 'No',
        totalLogDays,
        totalCompletions,
        '${allTimeRate.toStringAsFixed(1)}%',
        currentStreak,
        bestMonthKey,
        '${bestMonthRate.toStringAsFixed(1)}%',
      ]);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TaskLog? _findLog(List<TaskLog> logs, String taskId) {
    try {
      return logs.firstWhere((l) => l.taskId == taskId);
    } catch (_) {
      return null;
    }
  }

  void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values,
      {bool bold = false}) {
    for (var col = 0; col < values.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      final raw = values[col];
      if (raw is int) {
        cell.value = IntCellValue(raw);
      } else if (raw is double) {
        cell.value = DoubleCellValue(raw);
      } else {
        cell.value = TextCellValue(raw?.toString() ?? '');
      }
      if (bold) {
        cell.cellStyle = CellStyle(bold: true);
      }
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

// ── Small accumulator used when computing best-month per task ─────────────────

class _MonthAcc {
  int days        = 0;
  int completions = 0;

  void add(bool completed) {
    days++;
    if (completed) completions++;
  }

  double get rate => days == 0 ? 0 : completions / days;
}
