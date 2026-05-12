import 'package:flutter/material.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime get selectedMonth => _selectedMonth;
  DateTime get selectedDay => _selectedDay;

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  void selectDay(DateTime date) {
    _selectedDay = date;
    notifyListeners();
  }
}
