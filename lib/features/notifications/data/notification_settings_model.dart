/// Notification settings model mapping to the `notification_settings` Supabase table.
class NotificationSettingsModel {
  final String id;
  final String userId;
  final bool taskReminder;
  final bool habitReminder;
  final bool pomodoroReminder;
  final bool dailyDigest;
  final String reminderTime;
  final String timezone;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    this.taskReminder = true,
    this.habitReminder = true,
    this.pomodoroReminder = true,
    this.dailyDigest = true,
    this.reminderTime = '08:00:00',
    this.timezone = 'Asia/Kolkata',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskReminder: json['task_reminder'] as bool? ?? true,
      habitReminder: json['habit_reminder'] as bool? ?? true,
      pomodoroReminder: json['pomodoro_reminder'] as bool? ?? true,
      dailyDigest: json['daily_digest'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? '08:00:00',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'task_reminder': taskReminder,
      'habit_reminder': habitReminder,
      'pomodoro_reminder': pomodoroReminder,
      'daily_digest': dailyDigest,
      'reminder_time': reminderTime,
      'timezone': timezone,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
    };
  }

  NotificationSettingsModel copyWith({
    bool? taskReminder,
    bool? habitReminder,
    bool? pomodoroReminder,
    bool? dailyDigest,
    String? reminderTime,
    String? timezone,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettingsModel(
      id: id,
      userId: userId,
      taskReminder: taskReminder ?? this.taskReminder,
      habitReminder: habitReminder ?? this.habitReminder,
      pomodoroReminder: pomodoroReminder ?? this.pomodoroReminder,
      dailyDigest: dailyDigest ?? this.dailyDigest,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
