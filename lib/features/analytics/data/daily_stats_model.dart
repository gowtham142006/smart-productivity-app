class DailyStatsModel {
  final String id;
  final DateTime date;
  final int tasksCompleted;
  final int tasksCreated;
  final int pomodoroSessions;
  final int pomodoroMinutes;
  final int habitsCompleted;
  final int focusScore;

  DailyStatsModel({
    required this.id,
    required this.date,
    this.tasksCompleted = 0,
    this.tasksCreated = 0,
    this.pomodoroSessions = 0,
    this.pomodoroMinutes = 0,
    this.habitsCompleted = 0,
    this.focusScore = 0,
  });

  factory DailyStatsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatsModel(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      tasksCreated: (json['tasks_created'] as num?)?.toInt() ?? 0,
      pomodoroSessions: (json['pomodoro_sessions'] as num?)?.toInt() ?? 0,
      pomodoroMinutes: (json['pomodoro_minutes'] as num?)?.toInt() ?? 0,
      habitsCompleted: (json['habits_completed'] as num?)?.toInt() ?? 0,
      focusScore: (json['focus_score'] as num?)?.toInt() ?? 0,
    );
  }

  /// Compute a productivity score (0-100) from stats.
  int get productivityScore {
    int score = 0;
    score += (tasksCompleted * 10).clamp(0, 30);
    score += (pomodoroSessions * 8).clamp(0, 30);
    score += (habitsCompleted * 10).clamp(0, 25);
    score += focusScore.clamp(0, 15);
    return score.clamp(0, 100);
  }
}
