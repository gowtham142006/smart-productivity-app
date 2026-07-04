import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/daily_stats_model.dart';
import '../../../core/providers/core_providers.dart';

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
