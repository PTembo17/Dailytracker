import 'package:intl/intl.dart';

class DateUtilsHelper {
  static List<DateTime> monthDays(DateTime month) {
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(totalDays, (index) => DateTime(month.year, month.month, index + 1));
  }

  static int firstDayOffset(DateTime month) {
    return DateTime(month.year, month.month, 1).weekday % 7;
  }

  static String formatMonthYear(DateTime value) {
    return DateFormat.yMMMM().format(value);
  }

  static String monthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String ymd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
