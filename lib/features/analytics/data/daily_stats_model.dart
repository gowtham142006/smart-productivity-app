/// Model matching the `daily_stats` PostgreSQL VIEW.
///
/// View columns:
///   user_id, date, tasks_completed, tasks_created,
///   habits_completed, focus_minutes, pomodoro_sessions
class DailyStatsModel {
  final DateTime date;
  final int tasksCompleted;
  final int tasksCreated;
  final int habitsCompleted;
  final int focusMinutes;
  final int pomodoroSessions;

  DailyStatsModel({
    required this.date,
    this.tasksCompleted = 0,
    this.tasksCreated = 0,
    this.habitsCompleted = 0,
    this.focusMinutes = 0,
    this.pomodoroSessions = 0,
  });

  factory DailyStatsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatsModel(
      date: DateTime.parse(json['date']),
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      tasksCreated: (json['tasks_created'] as num?)?.toInt() ?? 0,
      habitsCompleted: (json['habits_completed'] as num?)?.toInt() ?? 0,
      focusMinutes: (json['focus_minutes'] as num?)?.toInt() ?? 0,
      pomodoroSessions: (json['pomodoro_sessions'] as num?)?.toInt() ?? 0,
    );
  }

  /// Compute a productivity score (0-100) from stats.
  int get productivityScore {
    int score = 0;
    score += (tasksCompleted * 10).clamp(0, 30);
    score += (pomodoroSessions * 8).clamp(0, 30);
    score += (habitsCompleted * 10).clamp(0, 25);
    score += (focusMinutes ~/ 10).clamp(0, 15);
    return score.clamp(0, 100);
  }
}
