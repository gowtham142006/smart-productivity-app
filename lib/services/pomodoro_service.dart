import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for persisting Pomodoro sessions to the
/// `pomodoro_sessions` table.
///
/// The `daily_stats` VIEW auto-computes `focus_minutes` and
/// `pomodoro_sessions` from this table — no manual stat updates needed.
class PomodoroService {
  final SupabaseClient _client;
  PomodoroService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Insert a completed Pomodoro session into `pomodoro_sessions`.
  ///
  /// This is the ONLY write path for focus data. Once the row exists,
  /// the `daily_stats` VIEW will automatically reflect it in
  /// `focus_minutes` and `pomodoro_sessions`.
  Future<void> saveCompletedSession({
    required int durationMinutes,
    required DateTime startedAt,
    required DateTime endedAt,
    int interruptions = 0,
    String? taskId,
  }) async {
    if (_userId == null) return;

    await _client.from('pomodoro_sessions').insert({
      'user_id': _userId,
      'task_id': taskId,
      'duration': durationMinutes,
      'completed': true,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'interruptions': interruptions,
    });
  }

  /// Count today's completed sessions directly from `pomodoro_sessions`.
  Future<int> getTodaySessionCount() async {
    if (_userId == null) return 0;

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await _client
        .from('pomodoro_sessions')
        .select('id')
        .eq('user_id', _userId!)
        .eq('completed', true)
        .gte('ended_at', '${today}T00:00:00')
        .lte('ended_at', '${today}T23:59:59');

    return (result as List).length;
  }

  /// Fetch session history for a date range (for future use).
  Future<List<Map<String, dynamic>>> getSessionHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_userId == null) return [];

    return await _client
        .from('pomodoro_sessions')
        .select()
        .eq('user_id', _userId!)
        .gte('ended_at', from.toIso8601String())
        .lte('ended_at', to.toIso8601String())
        .order('ended_at', ascending: false);
  }
}
