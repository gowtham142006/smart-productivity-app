import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/habit_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../services/notification_service.dart';

class HabitListNotifier extends AsyncNotifier<List<HabitModel>> {
  @override
  Future<List<HabitModel>> build() async {
    try {
      final service = ref.watch(habitServiceProvider);

      // Batch: fetch habits + today's completions in parallel
      final results = await Future.wait([
        service.getHabits(),
        service.getTodayCompletions(),
      ]);

      final data = results[0] as List<Map<String, dynamic>>;
      final completedIds = results[1] as Set<String>;

      return data.map((json) {
        final isCompleted = completedIds.contains(json['id']);
        return HabitModel.fromJson(json, completedToday: isCompleted);
      }).toList();
    } catch (e, st) {
      debugPrint('[HabitProvider] ❌ Error building habit list: $e');
      debugPrint('[HabitProvider] Stack: $st');
      rethrow;
    }
  }

  Future<void> addHabit({
    required String title,
    String? description,
    String frequency = 'daily',
    String? reminderTime,
    String color = '#6C63FF',
    int targetDays = 30,
  }) async {
    try {
      final service = ref.read(habitServiceProvider);
      await service.addHabit(
        title: title,
        description: description,
        frequency: frequency,
        reminderTime: reminderTime,
        color: color,
        targetDays: targetDays,
      );

      // Schedule reminder if configured (Decision #8)
      if (reminderTime != null && reminderTime.isNotEmpty) {
        await _scheduleReminder(title, reminderTime);
      }

      ref.invalidateSelf();
      await future; // Wait for rebuild to complete
      debugPrint('[HabitProvider] ✅ Habit added and list refreshed');
    } catch (e, st) {
      debugPrint('[HabitProvider] ❌ Error adding habit: $e');
      debugPrint('[HabitProvider] Stack: $st');
      rethrow;
    }
  }

  Future<void> toggleCompletion(String habitId) async {
    try {
      final service = ref.read(habitServiceProvider);
      final habits = state.value ?? [];
      final habit = habits.firstWhere((h) => h.id == habitId);

      if (habit.isCompletedToday) {
        await service.uncompleteHabit(habitId);
      } else {
        await service.completeHabit(habitId);
        // Note: daily_stats VIEW auto-computes habits_completed from habit_logs.
      }
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[HabitProvider] Error toggling completion: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((h) => h.id != habitId).toList());

    try {
      final service = ref.read(habitServiceProvider);
      await service.deleteHabit(habitId);
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[HabitProvider] Error deleting habit: $e');
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
    try {
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
    } catch (e) {
      debugPrint('[HabitProvider] Error updating habit: $e');
      rethrow;
    }
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

