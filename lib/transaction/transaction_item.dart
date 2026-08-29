import 'package:flutter/material.dart';

class TransactionItem {
  const TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
  });

  final String title;
  final DateTime date;
  final double amount;
  final IconData icon;
}
