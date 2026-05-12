extension DateExtensions on DateTime {
  String get ymd {
    final yr = year.toString().padLeft(4, '0');
    final mon = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$yr-$mon-$d';
  }
}
