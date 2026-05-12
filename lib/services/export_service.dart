// lib/services/export_service.dart
//
// Queries every task and every task_log from SQLite and writes them
// to a two-sheet Excel workbook (.xlsx).  The finished file is saved
// to the app's Documents directory and then shared via share_plus so
// the user can send it to Files, Drive, email, etc.

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/local/database_helper.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── Public entry point ───────────────────────────────────────────────────

  /// Exports all data to an Excel file and triggers the system share sheet.
  /// Returns the path of the written file, or throws on error.
  Future<String> exportToExcel() async {
    final db = await DatabaseHelper.instance.database;

    // ── 1. Fetch raw data ──────────────────────────────────────────────────
    final taskRows = await db.query('tasks', orderBy: 'position ASC');
    final logRows  = await db.query('task_logs', orderBy: 'log_date ASC, task_id ASC');

    // Build a quick id→name lookup for the Logs sheet
    final taskNames = <String, String>{
      for (final r in taskRows) r['id'] as String: r['name'] as String,
    };

    // ── 2. Build workbook ──────────────────────────────────────────────────
    final excel = Excel.createExcel();

    // Excel.createExcel() always creates a default "Sheet1" — rename it.
    excel.rename('Sheet1', 'Tasks');

    _buildTasksSheet(excel['Tasks'], taskRows);
    _buildLogsSheet(excel['Logs'], logRows, taskNames);

    // ── 3. Write to disk ───────────────────────────────────────────────────
    final dir  = await getApplicationDocumentsDirectory();
    final now  = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
    final path = '${dir.path}/dailytracker_export_$stamp.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding returned null');
    await File(path).writeAsBytes(bytes, flush: true);

    // ── 4. Share ───────────────────────────────────────────────────────────
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Daily Tracker export $stamp',
    );

    return path;
  }

  // ── Sheet builders ───────────────────────────────────────────────────────

  void _buildTasksSheet(Sheet sheet, List<Map<String, dynamic>> rows) {
    // Header row
    _writeRow(sheet, 0, [
      'ID',
      'Name',
      'Position',
      'Created At',
      'Reminder Time',
      'Reminder Enabled',
    ], bold: true);

    // Data rows
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      _writeRow(sheet, i + 1, [
        r['id'],
        r['name'],
        r['position'],
        r['created_at'],
        r['reminder_time'] ?? '',
        (r['reminder_enabled'] as int? ?? 0) == 1 ? 'Yes' : 'No',
      ]);
    }

    // Column widths (approximate character counts)
    sheet.setColumnWidth(0, 38); // ID (UUID)
    sheet.setColumnWidth(1, 28); // Name
    sheet.setColumnWidth(2, 10); // Position
    sheet.setColumnWidth(3, 14); // Created At
    sheet.setColumnWidth(4, 14); // Reminder Time
    sheet.setColumnWidth(5, 16); // Reminder Enabled
  }

  void _buildLogsSheet(
    Sheet sheet,
    List<Map<String, dynamic>> rows,
    Map<String, String> taskNames,
  ) {
    _writeRow(sheet, 0, [
      'Log ID',
      'Task ID',
      'Task Name',
      'Date',
      'Completed',
    ], bold: true);

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final taskId = r['task_id'] as String;
      _writeRow(sheet, i + 1, [
        r['id'],
        taskId,
        taskNames[taskId] ?? '(deleted)',
        r['log_date'],
        (r['completed'] as int? ?? 0) == 1 ? 'Yes' : 'No',
      ]);
    }

    sheet.setColumnWidth(0, 38);
    sheet.setColumnWidth(1, 38);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 10);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values,
      {bool bold = false}) {
    for (var col = 0; col < values.length; col++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(values[col]?.toString() ?? '');
      if (bold) {
        cell.cellStyle = CellStyle(bold: true);
      }
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
