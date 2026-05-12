import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../data/local/database_helper.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/task_repository.dart';
import '../providers/calendar_provider.dart';
import '../providers/log_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/home/home_screen.dart';

class DailyTrackerApp extends StatelessWidget {
  const DailyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;
    final taskRepository = TaskRepository(dbHelper);
    final logRepository = LogRepository(dbHelper);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(taskRepository),
        ),
        ChangeNotifierProvider<LogProvider>(
          create: (_) => LogProvider(logRepository),
        ),
        ChangeNotifierProvider<CalendarProvider>(
          create: (_) => CalendarProvider(),
        ),
        ChangeNotifierProxyProvider2<TaskProvider, LogProvider, StatsProvider>(
          create: (_) => StatsProvider(const [], const {}),
          update: (_, taskProvider, logProvider, statsProvider) =>
              statsProvider!..update(taskProvider.tasks, logProvider.logsByDate),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Daily Task Tracker',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
