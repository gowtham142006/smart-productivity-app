import 'package:flutter/material.dart';

enum TaskPriority {
  low('low', 'Low', Colors.grey, Icons.arrow_downward),
  medium('medium', 'Medium', Colors.blue, Icons.remove),
  high('high', 'High', Colors.orange, Icons.arrow_upward),
  urgent('urgent', 'Urgent', Colors.red, Icons.priority_high);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const TaskPriority(this.value, this.label, this.color, this.icon);

  static TaskPriority fromString(String? value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}
