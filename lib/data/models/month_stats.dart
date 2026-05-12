class MonthStats {
  final String monthKey;
  final double completionRate;
  final int totalDays;
  final int perfectDays;
  final double bestDayScore;
  final String topStreakTask;

  MonthStats({
    required this.monthKey,
    required this.completionRate,
    required this.totalDays,
    required this.perfectDays,
    required this.bestDayScore,
    required this.topStreakTask,
  });
}
