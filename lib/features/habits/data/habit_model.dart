import 'package:flutter/material.dart';

class HabitModel {
  final String id;
  final String title;
  final String description;
  final String frequency; // daily, weekly
  final String? reminderTime; // HH:mm format
  final String color;
  final int targetDays;
  final int currentStreak;
  final int bestStreak;
  final bool isActive;
  final bool isCompletedToday;
  final DateTime createdAt;

  HabitModel({
    required this.id,
    required this.title,
    this.description = '',
    this.frequency = 'daily',
    this.reminderTime,
    this.color = '#6C63FF',
    this.targetDays = 30,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isActive = true,
    this.isCompletedToday = false,
    required this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json,
      {bool completedToday = false}) {
    return HabitModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? 'daily',
      reminderTime: json['reminder_time'],
      color: json['color'] ?? '#6C63FF',
      targetDays: (json['target_days'] as num?)?.toInt() ?? 30,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] ?? true,
      isCompletedToday: completedToday,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  String? get formattedReminderTime {
    if (reminderTime == null || reminderTime!.isEmpty) return null;
    try {
      final parts = reminderTime!.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour -= 12;
        }
        
        final minuteStr = minute.toString().padLeft(2, '0');
        return '$hour:$minuteStr $period';
      }
    } catch (_) {}
    return reminderTime;
  }

  HabitModel copyWith({
    String? title,
    String? description,
    String? frequency,
    String? reminderTime,
    String? color,
    int? targetDays,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    bool? isCompletedToday,
    bool clearReminder = false,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      color: color ?? this.color,
      targetDays: targetDays ?? this.targetDays,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isActive: isActive ?? this.isActive,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      createdAt: createdAt,
    );
  }
}
