import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitService {
  final SupabaseClient _client;
  HabitService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Get all habits for the current user.
  Future<List<Map<String, dynamic>>> getHabits() async {
    if (_userId == null) return [];

    try {
      return await _client
          .from('habits')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('[HabitService] Error fetching habits: $e');
      rethrow;
    }
  }

  /// Get all habit IDs that are completed today — SINGLE query.
  /// Returns a Set of habit IDs for O(1) lookup.
  Future<Set<String>> getTodayCompletions() async {
    if (_userId == null) return {};

    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final results = await _client
          .from('habit_logs')
          .select('habit_id')
.eq('completed_at', today)
.eq('status', 'completed');

      return results.map<String>((r) => r['habit_id'] as String).toSet();
    } catch (e) {
      debugPrint('[HabitService] Error fetching today completions: $e');
      return {};
    }
  }

  /// Create a new habit.
  Future<void> addHabit({
    required String title,
    String? description,
    String frequency = 'daily',
    String? reminderTime,
    String color = '#6C63FF',
    int targetDays = 30,
  }) async {
    if (_userId == null) {
      debugPrint('[HabitService] addHabit failed: no userId');
      return;
    }

    try {
      await _client.from('habits').insert({
        'user_id': _userId,
        'title': title,
        'description': description ?? '',
        'frequency': frequency,
        'reminder_time': reminderTime,
        'color': color,
        'target_days': targetDays,
        'current_streak': 0,
        'best_streak': 0,
        'is_active': true,
      });
      debugPrint('[HabitService] ✅ Habit "$title" created successfully');
    } catch (e) {
      debugPrint('[HabitService] ❌ Error creating habit "$title": $e');
      rethrow;
    }
  }

  /// Update a habit.
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
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (frequency != null) updates['frequency'] = frequency;
    if (color != null) updates['color'] = color;
    if (targetDays != null) updates['target_days'] = targetDays;
    if (isActive != null) updates['is_active'] = isActive;

    if (clearReminder) {
      updates['reminder_time'] = null;
    } else if (reminderTime != null) {
      updates['reminder_time'] = reminderTime;
    }

    if (updates.isNotEmpty) {
      await _client.from('habits').update(updates).eq('id', habitId);
    }
  }

  /// Delete a habit.
  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  /// Get habit completions for a date range.
  Future<List<Map<String, dynamic>>> getCompletions({
    required String habitId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
    .from('habit_logs')
    .select()
    .eq('habit_id', habitId)
    .eq('status', 'completed');

    if (from != null) {
      query = query.gte(
          'completed_at', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte(
          'completed_at', to.toIso8601String().split('T').first);
    }

    return await query.order('completed_at', ascending: false);
  }

  /// Mark a habit as completed for today.
  Future<void> completeHabit(String habitId) async {
    if (_userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    // Check if already completed today
    final existing = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_at', today)
.eq('status', 'completed')
        .maybeSingle();

    if (existing != null) return; // Already completed

    await _client.from('habit_logs').insert({
  'user_id': _userId,
  'habit_id': habitId,
  'completed_at': today,
  'status': 'completed',
});

    // Update streak
    await _updateStreak(habitId);
  }

  /// Uncomplete a habit for today.
  Future<void> uncompleteHabit(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    await _client
    .from('habit_logs')
    .delete()
    .eq('habit_id', habitId)
    .eq('completed_at', today)
    .eq('status', 'completed');
  }

  /// Check if a habit is completed today.
  Future<bool> isCompletedToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_at', today)
.eq('status', 'completed')
        .maybeSingle();

    return result != null;
  }

  /// Update streak counts for a habit.
  Future<void> _updateStreak(String habitId) async {
    // Get recent completions to calculate streak
    final completions = await _client
    .from('habit_logs')
    .select('completed_at')
    .eq('habit_id', habitId)
    .eq('status', 'completed')
    .order('completed_at', ascending: false)
    .limit(365);

    if (completions.isEmpty) return;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dateStr = checkDate.toIso8601String().split('T').first;
      final found = completions.any(
  (c) => (c['completed_at'] as String?) == dateStr,
);

      if (found) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // Today not yet completed is ok, check yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    // Get current best streak
    final habit = await _client
        .from('habits')
        .select('best_streak')
        .eq('id', habitId)
        .single();

    final bestStreak = (habit['best_streak'] as num?)?.toInt() ?? 0;

    await _client.from('habits').update({
      'current_streak': streak,
      'best_streak': streak > bestStreak ? streak : bestStreak,
    }).eq('id', habitId);
  }
}
