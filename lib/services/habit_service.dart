import 'package:supabase_flutter/supabase_flutter.dart';

class HabitService {
  final SupabaseClient _client;
  HabitService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Get all habits for the current user.
  Future<List<Map<String, dynamic>>> getHabits() async {
    if (_userId == null) return [];

    return await _client
        .from('habits')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
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
    if (_userId == null) return;

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
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId);

    if (from != null) {
      query = query.gte(
          'completed_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte(
          'completed_date', to.toIso8601String().split('T').first);
    }

    return await query.order('completed_date', ascending: false);
  }

  /// Mark a habit as completed for today.
  Future<void> completeHabit(String habitId) async {
    if (_userId == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;

    // Check if already completed today
    final existing = await _client
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_date', today)
        .maybeSingle();

    if (existing != null) return; // Already completed

    await _client.from('habit_completions').insert({
      'habit_id': habitId,
      'completed_date': today,
    });

    // Update streak
    await _updateStreak(habitId);
  }

  /// Uncomplete a habit for today.
  Future<void> uncompleteHabit(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    await _client
        .from('habit_completions')
        .delete()
        .eq('habit_id', habitId)
        .eq('completed_date', today);
  }

  /// Check if a habit is completed today.
  Future<bool> isCompletedToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await _client
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_date', today)
        .maybeSingle();

    return result != null;
  }

  /// Update streak counts for a habit.
  Future<void> _updateStreak(String habitId) async {
    // Get recent completions to calculate streak
    final completions = await _client
        .from('habit_completions')
        .select('completed_date')
        .eq('habit_id', habitId)
        .order('completed_date', ascending: false)
        .limit(365);

    if (completions.isEmpty) return;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dateStr = checkDate.toIso8601String().split('T').first;
      final found = completions.any((c) => c['completed_date'] == dateStr);

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
