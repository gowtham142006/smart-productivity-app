import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/habit_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../services/notification_service.dart';

class HabitListNotifier extends AsyncNotifier<List<HabitModel>> {
  @override
  Future<List<HabitModel>> build() async {
    final service = ref.watch(habitServiceProvider);
    final data = await service.getHabits();

    final habits = <HabitModel>[];
    for (final json in data) {
      final completed = await service.isCompletedToday(json['id']);
      habits.add(HabitModel.fromJson(json, completedToday: completed));
    }

    return habits;
  }

  Future<void> addHabit({
    required String title,
    String? description,
    String frequency = 'daily',
    String? reminderTime,
    String color = '#6C63FF',
    int targetDays = 30,
  }) async {
    final service = ref.read(habitServiceProvider);
    await service.addHabit(
      title: title,
      description: description,
      frequency: frequency,
      reminderTime: reminderTime,
      color: color,
      targetDays: targetDays,
    );
    ref.invalidateSelf();

    // Schedule reminder if configured (Decision #8)
    if (reminderTime != null && reminderTime.isNotEmpty) {
      await _scheduleReminder(title, reminderTime);
    }
  }

  Future<void> toggleCompletion(String habitId) async {
    final service = ref.read(habitServiceProvider);
    final habits = state.value ?? [];
    final habit = habits.firstWhere((h) => h.id == habitId);

    if (habit.isCompletedToday) {
      await service.uncompleteHabit(habitId);
    } else {
      await service.completeHabit(habitId);

      // Update daily stats (Decision #9)
      final statsService = ref.read(dailyStatsServiceProvider);
      await statsService.incrementStat('habits_completed');
    }
    ref.invalidateSelf();
  }

  Future<void> deleteHabit(String habitId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((h) => h.id != habitId).toList());

    try {
      final service = ref.read(habitServiceProvider);
      await service.deleteHabit(habitId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateHabit({
    required String habitId,
    String? title,
    String? description,
    String? frequency,
    String? reminderTime,
    String? color,
    int? targetDays,
    bool? isActive,
    bool clearReminder = false,
  }) async {
    final service = ref.read(habitServiceProvider);
    await service.updateHabit(
      habitId: habitId,
      title: title,
      description: description,
      frequency: frequency,
      reminderTime: reminderTime,
      color: color,
      targetDays: targetDays,
      isActive: isActive,
      clearReminder: clearReminder,
    );
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Schedule a daily reminder notification (Decision #8).
  Future<void> _scheduleReminder(String title, String time) async {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var scheduledTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final notifService = NotificationService();
      await notifService.scheduleNotification(
        id: title.hashCode,
        title: 'Habit Reminder 🔔',
        body: 'Time to work on: $title',
        scheduledTime: scheduledTime,
        payload: 'habit:$title',
      );
    } catch (e) {
      debugPrint('[HabitProvider] Error scheduling reminder: $e');
    }
  }
}

final habitListProvider =
    AsyncNotifierProvider<HabitListNotifier, List<HabitModel>>(
  HabitListNotifier.new,
);

// Derived providers
final activeHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  return habits.where((h) => h.isActive).toList();
});

final completedTodayCountProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  return habits.where((h) => h.isCompletedToday).length;
});

final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  final habits = ref.watch(habitListProvider).value ?? [];
  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  return habit?.currentStreak ?? 0;
});
