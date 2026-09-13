import 'package:flutter/material.dart';

class AppUtils {
  AppUtils._();

  static final headerColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  );

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String monthName(DateTime date) => _months[date.month - 1];

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${_months[date.month - 1].substring(0, 3)}-${date.year}';
}
