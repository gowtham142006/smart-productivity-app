import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStatsService {
  final SupabaseClient _client;
  DailyStatsService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Get daily stats for a date range.
  Future<List<Map<String, dynamic>>> getStats({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_userId == null) return [];

    return await _client
        .from('daily_stats')
        .select()
        .eq('user_id', _userId!)
        .gte('date', from.toIso8601String().split('T').first)
        .lte('date', to.toIso8601String().split('T').first)
        .order('date', ascending: true);
  }

  /// Get stats for today, creating a row if needed.
  Future<Map<String, dynamic>> getTodayStats() async {
    if (_userId == null) return {};

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await _client
        .from('daily_stats')
        .select()
        .eq('user_id', _userId!)
        .eq('date', today)
        .maybeSingle();

    if (result != null) return result;

    // Create today's entry
    final newRow = {
      'user_id': _userId,
      'date': today,
      'tasks_completed': 0,
      'tasks_created': 0,
      'pomodoro_sessions': 0,
      'pomodoro_minutes': 0,
      'habits_completed': 0,
      'focus_score': 0,
    };

    final inserted = await _client
        .from('daily_stats')
        .insert(newRow)
        .select()
        .single();

    return inserted;
  }

  /// Increment a stat for today.
  Future<void> incrementStat(String field, {int amount = 1}) async {
    if (_userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    // Ensure today's row exists
    final stats = await getTodayStats();
    final currentVal = (stats[field] as num?)?.toInt() ?? 0;

    await _client
        .from('daily_stats')
        .update({field: currentVal + amount})
        .eq('user_id', _userId!)
        .eq('date', today);
  }

  /// Update a specific field for today.
  Future<void> updateTodayStat(String field, dynamic value) async {
    if (_userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;
    await getTodayStats(); // Ensure row exists

    await _client
        .from('daily_stats')
        .update({field: value})
        .eq('user_id', _userId!)
        .eq('date', today);
  }

  /// Get the last N days of stats.
  Future<List<Map<String, dynamic>>> getLastNDays(int n) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: n - 1));
    return getStats(from: from, to: to);
  }
}
