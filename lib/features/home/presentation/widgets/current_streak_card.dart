import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/streak_provider.dart';

/// Current Streak card showing 🔥 and motivational message.
class CurrentStreakCard extends ConsumerWidget {
  const CurrentStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(currentMaxStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streak > 0
              ? [const Color(0xFFFF6B35), const Color(0xFFFF8C42)]
              : [
                  isDark ? AppColors.darkCard : Colors.grey.shade100,
                  isDark ? AppColors.darkCard : Colors.grey.shade50,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: streak > 0
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Flame icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: streak > 0
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '🔥',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0 ? '$streak Day Streak' : 'No Active Streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: streak > 0
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalMessage(streak),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: streak > 0
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(int streak) {
    if (streak == 0) return 'Start your streak today!';
    if (streak < 3) return 'Great start! Keep it going! 💪';
    if (streak < 7) return 'You\'re building momentum! 🚀';
    if (streak < 14) return 'One week strong! Incredible! ⭐';
    if (streak < 30) return 'Unstoppable! You\'re on fire! 🔥';
    return 'Legendary streak! You\'re amazing! 🏆';
  }
}
