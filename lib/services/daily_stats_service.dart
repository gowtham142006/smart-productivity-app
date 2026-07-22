import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only service for the `daily_stats` VIEW.
///
/// `daily_stats` is a PostgreSQL VIEW that auto-computes its values from:
///   - tasks           → tasks_completed, tasks_created
///   - habit_logs      → habits_completed
///   - pomodoro_sessions → focus_minutes, pomodoro_sessions
///
/// It must NEVER be inserted into or updated.
class DailyStatsService {
  final SupabaseClient _client;
  DailyStatsService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Get daily stats for a date range (read-only).
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

  /// Get stats for today (read-only).
  ///
  /// Returns an empty map if no data exists for today yet.
  /// The VIEW will produce a row automatically once the user has
  /// at least one task, habit log, or pomodoro session for the day.
  Future<Map<String, dynamic>> getTodayStats() async {
    if (_userId == null) return {};

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await _client
        .from('daily_stats')
        .select()
        .eq('user_id', _userId!)
        .eq('date', today)
        .maybeSingle();

    return result ?? {};
  }

  /// Get the last N days of stats (read-only).
  Future<List<Map<String, dynamic>>> getLastNDays(int n) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: n - 1));
    return getStats(from: from, to: to);
  }
}
