import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/habit_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../services/notification_service.dart';
import '../../analytics/providers/analytics_provider.dart';

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
      final created = await service.addHabit(
        title: title,
        description: description,
        frequency: frequency,
        reminderTime: reminderTime,
        color: color,
        targetDays: targetDays,
      );

      final habitId = created?['id'] as String?;

      // Schedule reminder if configured (Decision #8)
      if (reminderTime != null && reminderTime.isNotEmpty && habitId != null) {
        await _scheduleReminder(habitId, title, reminderTime);
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
    final previousList = state.value;
    if (previousList == null) return;

    final index = previousList.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final oldHabit = previousList[index];
    final isCompleting = !oldHabit.isCompletedToday;

    final newCurrentStreak = isCompleting
        ? oldHabit.currentStreak + 1
        : (oldHabit.currentStreak > 0 ? oldHabit.currentStreak - 1 : 0);

    final newBestStreak = isCompleting
        ? (newCurrentStreak > oldHabit.bestStreak
            ? newCurrentStreak
            : oldHabit.bestStreak)
        : oldHabit.bestStreak;

    final updatedHabit = oldHabit.copyWith(
      isCompletedToday: isCompleting,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
    );

    // 1. Optimistic update: Update local state immediately
    final newList = List<HabitModel>.from(previousList);
    newList[index] = updatedHabit;
    state = AsyncData(newList);

    // 2. Perform DB request in the background
    try {
      final service = ref.read(habitServiceProvider);
      if (isCompleting) {
        await service.completeHabit(habitId);
      } else {
        await service.uncompleteHabit(habitId);
      }

      // Invalidate analytics so stats stay synchronized
      ref.invalidate(analyticsProvider);
      ref.invalidate(fullAnalyticsProvider);
    } catch (e, st) {
      // 3. Revert state on failure
      state = AsyncData(previousList);
      debugPrint('[HabitProvider] ❌ Error toggling habit completion: $e');
      debugPrint('[HabitProvider] Stack: $st');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((h) => h.id != habitId).toList());

    // Cancel both notifications (pre-reminder + due-time) on delete
    await _cancelReminder(habitId.hashCode);

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

      final currentHabit = state.value?.firstWhere(
        (h) => h.id == habitId,
        orElse: () => HabitModel(
          id: habitId,
          title: title ?? 'Habit',
          frequency: 'daily',
          color: '#6C63FF',
          targetDays: 30,
          currentStreak: 0,
          bestStreak: 0,
          isActive: true,
          isCompletedToday: false,
          createdAt: DateTime.now(),
        ),
      );
      final updatedTitle = title ?? currentHabit?.title ?? 'Habit';

      if (clearReminder) {
        await _cancelReminder(habitId.hashCode);
      } else if (reminderTime != null && reminderTime.isNotEmpty) {
        // Cancel old notifications before scheduling updated ones
        await _cancelReminder(habitId.hashCode);
        await _scheduleReminder(habitId, updatedTitle, reminderTime);
      } else if (currentHabit?.reminderTime != null &&
          currentHabit!.reminderTime!.isNotEmpty) {
        // If title changed but reminder time stayed the same, reschedule with updated title
        await _cancelReminder(habitId.hashCode);
        await _scheduleReminder(
            habitId, updatedTitle, currentHabit.reminderTime!);
      }

      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[HabitProvider] Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Schedule daily reminder notifications (Decision #8).
  /// Schedules two notifications:
  ///   - [habitId.hashCode + 1]: 5 minutes BEFORE the reminder time (pre-reminder)
  ///   - [habitId.hashCode]    : at the reminder time (due-time)
  Future<void> _scheduleReminder(String habitId, String title, String time) async {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var dueTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (dueTime.isBefore(now)) {
        dueTime = dueTime.add(const Duration(days: 1));
      }

      final dueNotifId = habitId.hashCode;
      final preNotifId = habitId.hashCode + 1;
      final notifService = NotificationService();

      // --- 5-minute pre-reminder ---
      final preReminderTime = dueTime.subtract(const Duration(minutes: 5));
      debugPrint(
          '[HabitProvider] Scheduling habit pre-reminder: habitId=$habitId, title="$title" -> preReminderTime=$preReminderTime (Notif ID=$preNotifId)');
      if (preReminderTime.isAfter(now)) {
        await notifService.scheduleNotification(
          id: preNotifId,
          title: 'Habit Starting Soon ⏰',
          body: '$title — starts in 5 minutes!',
          scheduledTime: preReminderTime,
          payload: 'habit_pre:$habitId',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        debugPrint(
            '[HabitProvider] Skipping pre-reminder for "$title" (preReminderTime $preReminderTime already passed)');
      }

      // --- Due-time reminder ---
      debugPrint(
          '[HabitProvider] Scheduling habit due-time reminder: habitId=$habitId, title="$title" -> dueTime=$dueTime (Notif ID=$dueNotifId)');
      await notifService.scheduleNotification(
        id: dueNotifId,
        title: 'Habit Reminder 🔔',
        body: 'Time to work on: $title',
        scheduledTime: dueTime,
        payload: 'habit:$habitId',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[HabitProvider] Error scheduling reminder for habit $habitId: $e');
    }
  }

  /// Cancels both the due-time notification (notifId) and the
  /// 5-minute pre-reminder (notifId + 1).
  Future<void> _cancelReminder(int notifId) async {
    try {
      final notifService = NotificationService();
      await notifService.cancelNotification(notifId);     // due-time
      await notifService.cancelNotification(notifId + 1); // pre-reminder
      debugPrint('[HabitProvider] Cancelled habit notification IDs: $notifId and ${notifId + 1}');
    } catch (e) {
      debugPrint('[HabitProvider] Error cancelling habit reminder ID $notifId: $e');
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

