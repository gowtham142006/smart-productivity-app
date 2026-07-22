import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/daily_stats_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../tasks/providers/task_provider.dart';
import '../../habits/providers/habit_provider.dart';

/// Aggregated analytics data from all sources.
class FullAnalyticsData {
  // Task metrics
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int todayCompletedTasks;

  // Habit metrics
  final int totalActiveHabits;
  final int habitsCompletedToday;
  final double habitCompletionRate; // 0.0 - 1.0
  final int currentBestStreak;
  final int longestStreak;

  // Focus metrics
  final int totalPomodoroSessions;
  final int totalFocusMinutes;
  final int todayPomodoroSessions;
  final int todayFocusMinutes;

  // Productivity
  final int weeklyProductivityScore;
  final int monthlyProductivityScore;
  final List<DailyStatsModel> weeklyStats;
  final List<DailyStatsModel> monthlyStats;

  const FullAnalyticsData({
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.todayCompletedTasks = 0,
    this.totalActiveHabits = 0,
    this.habitsCompletedToday = 0,
    this.habitCompletionRate = 0.0,
    this.currentBestStreak = 0,
    this.longestStreak = 0,
    this.totalPomodoroSessions = 0,
    this.totalFocusMinutes = 0,
    this.todayPomodoroSessions = 0,
    this.todayFocusMinutes = 0,
    this.weeklyProductivityScore = 0,
    this.monthlyProductivityScore = 0,
    this.weeklyStats = const [],
    this.monthlyStats = const [],
  });

  String get totalFocusFormatted {
    final hours = totalFocusMinutes ~/ 60;
    final mins = totalFocusMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get todayFocusFormatted {
    final hours = todayFocusMinutes ~/ 60;
    final mins = todayFocusMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}

/// Analytics provider using daily_stats as the primary source (Decision #5).
class AnalyticsNotifier extends AsyncNotifier<List<DailyStatsModel>> {
  @override
  Future<List<DailyStatsModel>> build() async {
    return _fetchStats();
  }

  Future<List<DailyStatsModel>> _fetchStats() async {
    final service = ref.read(dailyStatsServiceProvider);
    final data = await service.getLastNDays(7);
    return data.map((e) => DailyStatsModel.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, List<DailyStatsModel>>(
  AnalyticsNotifier.new,
);

/// Full analytics provider aggregating data from tasks, habits, and stats.
final fullAnalyticsProvider = FutureProvider<FullAnalyticsData>((ref) async {
  try {
    final statsService = ref.read(dailyStatsServiceProvider);

    // Fetch weekly and monthly stats in parallel
    final results = await Future.wait([
      statsService.getLastNDays(7),
      statsService.getLastNDays(30),
    ]);

    final weeklyData =
        (results[0] as List).map((e) => DailyStatsModel.fromJson(e)).toList();
    final monthlyData =
        (results[1] as List).map((e) => DailyStatsModel.fromJson(e)).toList();

    // Get task data from providers
    final allTasks = ref.read(allTasksProvider).value ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final pendingTasks = allTasks.where((t) => !t.isCompleted).length;
    final overdueTasks = allTasks
        .where((t) =>
            t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted)
        .length;

    // Today's completed tasks
    final todayCompletedTasks = allTasks.where((t) {
      if (!t.isCompleted) return false;
      // Use updatedAt to determine when it was completed
      final taskDate = t.updatedAt;
      return taskDate.year == today.year &&
          taskDate.month == today.month &&
          taskDate.day == today.day;
    }).length;

    // Habit data from providers
    final habits = ref.read(habitListProvider).value ?? [];
    final activeHabits = habits.where((h) => h.isActive).toList();
    final habitsCompletedToday =
        habits.where((h) => h.isCompletedToday).length;
    final habitCompletionRate = activeHabits.isNotEmpty
        ? habitsCompletedToday / activeHabits.length
        : 0.0;

    // Streak data
    final currentBestStreak = habits.isNotEmpty
        ? habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b)
        : 0;
    final longestStreak = habits.isNotEmpty
        ? habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b)
        : 0;

    // Pomodoro totals from monthly stats
    final totalPomodoroSessions =
        monthlyData.fold<int>(0, (sum, s) => sum + s.pomodoroSessions);
    final totalFocusMinutes =
        monthlyData.fold<int>(0, (sum, s) => sum + s.focusMinutes);

    // Today's pomodoro
    final todayStats = weeklyData.where((s) {
      return s.date.year == today.year &&
          s.date.month == today.month &&
          s.date.day == today.day;
    });
    final todayPomodoroSessions =
        todayStats.isNotEmpty ? todayStats.first.pomodoroSessions : 0;
    final todayFocusMinutes =
        todayStats.isNotEmpty ? todayStats.first.focusMinutes : 0;

    // Productivity scores
    final weeklyScore = weeklyData.isNotEmpty
        ? (weeklyData.fold<int>(
                    0, (sum, s) => sum + s.productivityScore) /
                weeklyData.length)
            .round()
        : 0;
    final monthlyScore = monthlyData.isNotEmpty
        ? (monthlyData.fold<int>(
                    0, (sum, s) => sum + s.productivityScore) /
                monthlyData.length)
            .round()
        : 0;

    return FullAnalyticsData(
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      overdueTasks: overdueTasks,
      todayCompletedTasks: todayCompletedTasks,
      totalActiveHabits: activeHabits.length,
      habitsCompletedToday: habitsCompletedToday,
      habitCompletionRate: habitCompletionRate,
      currentBestStreak: currentBestStreak,
      longestStreak: longestStreak,
      totalPomodoroSessions: totalPomodoroSessions,
      totalFocusMinutes: totalFocusMinutes,
      todayPomodoroSessions: todayPomodoroSessions,
      todayFocusMinutes: todayFocusMinutes,
      weeklyProductivityScore: weeklyScore,
      monthlyProductivityScore: monthlyScore,
      weeklyStats: weeklyData,
      monthlyStats: monthlyData,
    );
  } catch (e, st) {
    debugPrint('[Analytics] Error building full analytics: $e');
    debugPrint('[Analytics] Stack: $st');
    return const FullAnalyticsData();
  }
});

/// Today's stats as a convenience provider.
final todayStatsProvider = FutureProvider<DailyStatsModel?>((ref) async {
  final service = ref.watch(dailyStatsServiceProvider);
  final data = await service.getTodayStats();
  if (data.isEmpty) return null;
  return DailyStatsModel.fromJson(data);
});

/// Weekly productivity score.
final weeklyProductivityProvider = Provider<int>((ref) {
  final stats = ref.watch(analyticsProvider).value ?? [];
  if (stats.isEmpty) return 0;
  final total = stats.fold<int>(0, (sum, s) => sum + s.productivityScore);
  return (total / stats.length).round();
});

/// AI Insight — only refresh on demand or once per day (Decision #6).
class AiInsightNotifier extends AsyncNotifier<String> {
  static const _boxName = 'settings';
  static const _insightKey = 'last_ai_insight';
  static const _insightDateKey = 'last_ai_insight_date';

  @override
  Future<String> build() async {
    return _getCachedOrGenerate(forceRefresh: false);
  }

  Future<String> _getCachedOrGenerate({required bool forceRefresh}) async {
    final box = Hive.box(_boxName);
    final lastDate = box.get(_insightDateKey, defaultValue: '');
    final today = DateTime.now().toIso8601String().split('T').first;

    // Return cached insight if same day and not forcing refresh
    if (!forceRefresh && lastDate == today) {
      final cached = box.get(_insightKey, defaultValue: '');
      if (cached.isNotEmpty) return cached;
    }

    // Generate new insight
    try {
      final stats = ref.read(analyticsProvider).value ?? [];
      if (stats.isEmpty) {
        return 'Start tracking your activities to get AI-powered insights!';
      }

      final gemini = ref.read(geminiServiceProvider);
      final statsStr = stats
          .map((s) =>
              '${s.date.toIso8601String().split('T').first}: '
              'tasks=${s.tasksCompleted}, pomodoro=${s.pomodoroSessions}, '
              'habits=${s.habitsCompleted}, score=${s.productivityScore}')
          .join('\n');

      final prompt = '''Based on this week's productivity data:
$statsStr

Give a brief, encouraging 2-3 sentence insight about the user's productivity patterns and one actionable tip. Be specific and reference the data.''';

      final insight = await gemini.generateContent(prompt);
      
      // Cache the insight
      await box.put(_insightKey, insight);
      await box.put(_insightDateKey, today);

      return insight;
    } catch (e) {
      debugPrint('[AnalyticsProvider] Error generating AI insight: $e');
      return 'Keep up the great work! Check back later for personalized insights.';
    }
  }

  /// Force a refresh of AI insights (Decision #6).
  Future<void> refreshInsight() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _getCachedOrGenerate(forceRefresh: true));
  }
}

final aiInsightProvider = AsyncNotifierProvider<AiInsightNotifier, String>(
  AiInsightNotifier.new,
);

