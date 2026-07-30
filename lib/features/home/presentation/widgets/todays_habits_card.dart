import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../habits/providers/habit_provider.dart';
import '../../../habits/data/habit_model.dart';

/// Today's Habits section for the Home dashboard.
/// Shows active habits with completion toggles and a progress bar.
class TodaysHabitsCard extends ConsumerWidget {
  const TodaysHabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return habitsAsync.when(
      data: (habits) {
        final activeHabits = habits.where((h) => h.isActive).toList();
        if (activeHabits.isEmpty) return const SizedBox.shrink();

        final completedCount =
            activeHabits.where((h) => h.isCompletedToday).length;
        final progress = activeHabits.isNotEmpty
            ? completedCount / activeHabits.length
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Habits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push('/habits'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completedCount/${activeHabits.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Habit list (max 5)
            ...activeHabits.take(5).map(
                  (habit) => _HabitTile(habit: habit),
                ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final HabitModel habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(habitListProvider.notifier).toggleCompletion(habit.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: habit.isCompletedToday
                ? AppColors.success.withValues(alpha: 0.06)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habit.isCompletedToday
                  ? AppColors.success.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: habit.colorValue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  habit.isCompletedToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: habit.isCompletedToday
                      ? AppColors.success
                      : habit.colorValue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: habit.isCompletedToday
                        ? TextDecoration.lineThrough
                        : null,
                    color: habit.isCompletedToday
                        ? AppColors.textTertiary
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (habit.currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥 ${habit.currentStreak}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
