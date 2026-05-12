import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dailytracker/core/constants/app_colors.dart';
import 'package:dailytracker/core/utils/score_utils.dart';
import 'package:dailytracker/core/utils/date_utils.dart';
import 'package:dailytracker/data/models/task_log.dart';
import 'package:dailytracker/shared/widgets/score_pill.dart';
import 'package:dailytracker/shared/widgets/streak_badge.dart';
import 'package:dailytracker/providers/theme_provider.dart';
import 'package:dailytracker/core/theme/app_theme.dart';

/// Helper that wraps a widget in the minimum context needed (Material + Providers).
Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // ── Unit tests ──────────────────────────────────────────────────────────

  group('ScoreUtils', () {
    test('dailyScore returns 0 when totalTasks is 0', () {
      expect(ScoreUtils.dailyScore([], 0), 0.0);
    });

    test('dailyScore returns correct fraction', () {
      final logs = [
        TaskLog(id: '1', taskId: 'a', logDate: '2026-05-01', completed: true),
        TaskLog(id: '2', taskId: 'b', logDate: '2026-05-01', completed: false),
        TaskLog(id: '3', taskId: 'c', logDate: '2026-05-01', completed: true),
      ];
      expect(ScoreUtils.dailyScore(logs, 3), closeTo(2 / 3, 0.001));
    });

    test('monthlyScore returns 0 when no logs', () {
      expect(ScoreUtils.monthlyScore({}, 5), 0.0);
    });

    test('taskStreak returns 0 when no log entry', () {
      final streak = ScoreUtils.taskStreak('task-1', DateTime(2026, 5, 10), {});
      expect(streak, 0);
    });

    test('taskStreak counts consecutive completed days', () {
      final logs = <String, List<TaskLog>>{
        '2026-05-08': [TaskLog(id: '1', taskId: 't1', logDate: '2026-05-08', completed: true)],
        '2026-05-09': [TaskLog(id: '2', taskId: 't1', logDate: '2026-05-09', completed: true)],
        '2026-05-10': [TaskLog(id: '3', taskId: 't1', logDate: '2026-05-10', completed: true)],
      };
      final streak = ScoreUtils.taskStreak('t1', DateTime(2026, 5, 10), logs);
      expect(streak, 3);
    });

    test('taskStreak stops at missed day', () {
      final logs = <String, List<TaskLog>>{
        '2026-05-08': [TaskLog(id: '1', taskId: 't1', logDate: '2026-05-08', completed: false)],
        '2026-05-09': [TaskLog(id: '2', taskId: 't1', logDate: '2026-05-09', completed: true)],
        '2026-05-10': [TaskLog(id: '3', taskId: 't1', logDate: '2026-05-10', completed: true)],
      };
      final streak = ScoreUtils.taskStreak('t1', DateTime(2026, 5, 10), logs);
      expect(streak, 2);
    });
  });

  group('DateUtilsHelper', () {
    test('monthDays returns correct count for May', () {
      final days = DateUtilsHelper.monthDays(DateTime(2026, 5, 1));
      expect(days.length, 31);
    });

    test('monthDays returns 28 for Feb in non-leap year', () {
      final days = DateUtilsHelper.monthDays(DateTime(2025, 2, 1));
      expect(days.length, 28);
    });

    test('monthDays returns 29 for Feb in leap year', () {
      final days = DateUtilsHelper.monthDays(DateTime(2024, 2, 1));
      expect(days.length, 29);
    });

    test('ymd formats correctly', () {
      expect(DateUtilsHelper.ymd(DateTime(2026, 5, 9)), '2026-05-09');
    });

    test('monthKey formats correctly', () {
      expect(DateUtilsHelper.monthKey(DateTime(2026, 5, 1)), '2026-05');
    });

    test('firstDayOffset for May 2026 (Friday)', () {
      // May 1 2026 is Friday = weekday 5, offset = 5 (Sun=0 grid)
      expect(DateUtilsHelper.firstDayOffset(DateTime(2026, 5, 1)), 5);
    });
  });

  group('AppColors', () {
    test('scoreColor returns green for rate >= 0.8', () {
      expect(AppColors.scoreColor(0.8), AppColors.green400);
      expect(AppColors.scoreColor(1.0), AppColors.green400);
    });

    test('scoreColor returns amber for 0.5 <= rate < 0.8', () {
      expect(AppColors.scoreColor(0.5), AppColors.amber400);
      expect(AppColors.scoreColor(0.79), AppColors.amber400);
    });

    test('scoreColor returns red for rate < 0.5', () {
      expect(AppColors.scoreColor(0.0), AppColors.red400);
      expect(AppColors.scoreColor(0.49), AppColors.red400);
    });
  });

  // ── Widget tests ─────────────────────────────────────────────────────────

  group('ScorePill widget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScorePill(label: '74%', value: '', rate: 0.74),
      ));
      expect(find.text('74%'), findsOneWidget);
    });

    testWidgets('renders label and value when both provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScorePill(label: 'Score', value: '80%', rate: 0.8),
      ));
      expect(find.text('Score 80%'), findsOneWidget);
    });
  });

  group('StreakBadge widget', () {
    testWidgets('renders streak count with fire emoji', (tester) async {
      await tester.pumpWidget(_wrap(const StreakBadge(streak: 12)));
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders zero streak', (tester) async {
      await tester.pumpWidget(_wrap(const StreakBadge(streak: 0)));
      expect(find.text('0'), findsOneWidget);
    });
  });
}
