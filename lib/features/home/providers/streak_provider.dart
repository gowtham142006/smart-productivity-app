import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../habits/providers/habit_provider.dart';

/// Derived provider: the highest current streak among all active habits.
/// Returns 0 if no habits exist or all streaks are 0.
final currentMaxStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  final activeHabits = habits.where((h) => h.isActive).toList();
  if (activeHabits.isEmpty) return 0;
  return activeHabits
      .map((h) => h.currentStreak)
      .reduce((a, b) => a > b ? a : b);
});

/// Derived provider: the highest best streak among all habits.
final bestOverallStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  if (habits.isEmpty) return 0;
  return habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
});
