import 'package:flutter/material.dart';
import 'app/app.dart';
import 'data/local/database_helper.dart';
import 'services/reminder_service.dart';

export 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialise local notification / alarm system
  await ReminderService.instance.init();

  // 2. Warm up SQLite (runs migrations if needed)
  await DatabaseHelper.instance.database;

  runApp(const DailyTrackerApp());
}
