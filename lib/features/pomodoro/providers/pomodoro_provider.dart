import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../services/notification_service.dart';

/// Pomodoro timer states.
enum PomodoroStatus { idle, running, paused, breakTime }

/// User-configurable Pomodoro settings.
class PomodoroSettings {
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }
}

/// Manages Pomodoro settings with Hive persistence.
class PomodoroSettingsNotifier extends Notifier<PomodoroSettings> {
  static const _boxName = 'settings';

  @override
  PomodoroSettings build() {
    return _loadFromHive();
  }

  PomodoroSettings _loadFromHive() {
    try {
      final box = Hive.box(_boxName);
      return PomodoroSettings(
        focusMinutes: box.get('pomodoro_focus', defaultValue: 25),
        shortBreakMinutes: box.get('pomodoro_short_break', defaultValue: 5),
        longBreakMinutes: box.get('pomodoro_long_break', defaultValue: 15),
        sessionsBeforeLongBreak:
            box.get('pomodoro_sessions_before_long', defaultValue: 4),
      );
    } catch (e) {
      debugPrint('[PomodoroSettings] Error loading from Hive: $e');
      return const PomodoroSettings();
    }
  }

  Future<void> updateSettings({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) async {
    final updated = state.copyWith(
      focusMinutes: focusMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak,
    );

    try {
      final box = Hive.box(_boxName);
      await box.put('pomodoro_focus', updated.focusMinutes);
      await box.put('pomodoro_short_break', updated.shortBreakMinutes);
      await box.put('pomodoro_long_break', updated.longBreakMinutes);
      await box.put('pomodoro_sessions_before_long', updated.sessionsBeforeLongBreak);
    } catch (e) {
      debugPrint('[PomodoroSettings] Error saving to Hive: $e');
    }

    state = updated;
  }
}

final pomodoroSettingsProvider =
    NotifierProvider<PomodoroSettingsNotifier, PomodoroSettings>(
  PomodoroSettingsNotifier.new,
);

/// Pomodoro session state.
class PomodoroState {
  final PomodoroStatus status;
  final int remainingSeconds;
  final int totalSeconds;
  final int sessionsCompleted;
  final bool isBreak;

  const PomodoroState({
    this.status = PomodoroStatus.idle,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.sessionsCompleted = 0,
    this.isBreak = false,
  });

  double get progress => 1 - (remainingSeconds / totalSeconds);

  String get timeDisplay {
    final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  PomodoroState copyWith({
    PomodoroStatus? status,
    int? remainingSeconds,
    int? totalSeconds,
    int? sessionsCompleted,
    bool? isBreak,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      isBreak: isBreak ?? this.isBreak,
    );
  }
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());

    // Listen to settings changes to update the timer state immediately.
    ref.listen<PomodoroSettings>(pomodoroSettingsProvider, (previous, next) {
      if (previous != null) {
        _onSettingsChanged(previous, next);
      }
    });

    // Read initial settings for initial state
    final settings = ref.read(pomodoroSettingsProvider);

    // Load today's completed sessions count from the daily stats database.
    Future.microtask(() => loadTodaySessions());

    return PomodoroState(
      remainingSeconds: settings.focusMinutes * 60,
      totalSeconds: settings.focusMinutes * 60,
    );
  }

  /// Load today's completed sessions count asynchronously.
  Future<void> loadTodaySessions() async {
    try {
      final statsService = ref.read(dailyStatsServiceProvider);
      final stats = await statsService.getTodayStats();
      final sessions = (stats['pomodoro_sessions'] as num?)?.toInt() ?? 0;
      state = state.copyWith(sessionsCompleted: sessions);
    } catch (e) {
      debugPrint('[Pomodoro] Error loading today sessions: $e');
    }
  }

  void _onSettingsChanged(PomodoroSettings oldSettings, PomodoroSettings newSettings) {
    if (!state.isBreak) {
      // Focus mode
      if (oldSettings.focusMinutes != newSettings.focusMinutes) {
        final newTotal = newSettings.focusMinutes * 60;
        if (state.status == PomodoroStatus.idle) {
          state = state.copyWith(
            remainingSeconds: newTotal,
            totalSeconds: newTotal,
          );
        } else {
          final elapsed = state.totalSeconds - state.remainingSeconds;
          if (elapsed >= newTotal) {
            state = state.copyWith(
              remainingSeconds: 0,
              totalSeconds: newTotal,
            );
            if (state.status == PomodoroStatus.running) {
              _timer?.cancel();
              _onTimerComplete();
            }
          } else {
            state = state.copyWith(
              remainingSeconds: newTotal - elapsed,
              totalSeconds: newTotal,
            );
          }
        }
      }
    } else {
      // Break mode
      final wasLongBreak = state.sessionsCompleted > 0 &&
          (state.sessionsCompleted % oldSettings.sessionsBeforeLongBreak == 0);
      final isLongBreakNow = state.sessionsCompleted > 0 &&
          (state.sessionsCompleted % newSettings.sessionsBeforeLongBreak == 0);

      final oldBreakMin = wasLongBreak ? oldSettings.longBreakMinutes : oldSettings.shortBreakMinutes;
      final newBreakMin = isLongBreakNow ? newSettings.longBreakMinutes : newSettings.shortBreakMinutes;

      if (oldBreakMin != newBreakMin || oldSettings.sessionsBeforeLongBreak != newSettings.sessionsBeforeLongBreak) {
        final newTotal = newBreakMin * 60;
        final elapsed = state.totalSeconds - state.remainingSeconds;
        if (elapsed >= newTotal) {
          state = state.copyWith(
            remainingSeconds: 0,
            totalSeconds: newTotal,
          );
          if (state.status == PomodoroStatus.running) {
            _timer?.cancel();
            _onTimerComplete();
          }
        } else {
          state = state.copyWith(
            remainingSeconds: newTotal - elapsed,
            totalSeconds: newTotal,
          );
        }
      }
    }
  }

  void start() {
    if (state.status == PomodoroStatus.running) return;

    // If idle, reset to current settings duration
    if (state.status == PomodoroStatus.idle) {
      final settings = ref.read(pomodoroSettingsProvider);
      final seconds = settings.focusMinutes * 60;
      state = state.copyWith(
        status: PomodoroStatus.running,
        remainingSeconds: seconds,
        totalSeconds: seconds,
      );
    } else {
      state = state.copyWith(status: PomodoroStatus.running);
    }
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void resume() {
    state = state.copyWith(status: PomodoroStatus.running);
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    final settings = ref.read(pomodoroSettingsProvider);
    final duration = state.isBreak
        ? ((state.sessionsCompleted > 0 &&
                state.sessionsCompleted % settings.sessionsBeforeLongBreak == 0)
            ? settings.longBreakMinutes
            : settings.shortBreakMinutes)
        : settings.focusMinutes;

    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: duration * 60,
      totalSeconds: duration * 60,
    );
  }

  void stop() {
    _timer?.cancel();
    final settings = ref.read(pomodoroSettingsProvider);
    state = PomodoroState(
      remainingSeconds: settings.focusMinutes * 60,
      totalSeconds: settings.focusMinutes * 60,
      sessionsCompleted: state.sessionsCompleted,
      isBreak: false,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        _onTimerComplete();
      } else {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
      }
    });
  }

  /// Called when timer finishes — auto-save sessions (Decision #9).
  Future<void> _onTimerComplete() async {
    final settings = ref.read(pomodoroSettingsProvider);

    if (!state.isBreak) {
      // Work session completed
      final newSessions = state.sessionsCompleted + 1;

      // Auto-save to daily stats (Decision #9)
      try {
        final statsService = ref.read(dailyStatsServiceProvider);
        await statsService.incrementStat('pomodoro_sessions');
        await statsService.incrementStat('pomodoro_minutes',
            amount: settings.focusMinutes);
        debugPrint(
            '[Pomodoro] Session $newSessions saved (${settings.focusMinutes} min)');
      } catch (e) {
        debugPrint('[Pomodoro] Error saving to daily_stats: $e');
      }

      // Show completion notification
      try {
        final notifService = NotificationService();
        await notifService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Pomodoro Complete! 🍅',
          body: 'Great work! Take a break.',
        );
      } catch (e) {
        debugPrint('[Pomodoro] Error showing notification: $e');
      }

      // Decide break length
      final isLongBreak =
          newSessions % settings.sessionsBeforeLongBreak == 0;
      final breakMinutes =
          isLongBreak ? settings.longBreakMinutes : settings.shortBreakMinutes;

      state = PomodoroState(
        status: PomodoroStatus.breakTime,
        remainingSeconds: breakMinutes * 60,
        totalSeconds: breakMinutes * 60,
        sessionsCompleted: newSessions,
        isBreak: true,
      );

      // Auto-start break
      _startTimer();
    } else {
      // Break completed
      try {
        final notifService = NotificationService();
        await notifService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Break Over! ⏰',
          body: 'Ready for another focused session?',
        );
      } catch (e) {
        debugPrint('[Pomodoro] Error showing notification: $e');
      }

      // Reset to work mode and automatically start the new focus session
      state = PomodoroState(
        status: PomodoroStatus.running,
        sessionsCompleted: state.sessionsCompleted,
        remainingSeconds: settings.focusMinutes * 60,
        totalSeconds: settings.focusMinutes * 60,
        isBreak: false,
      );
      _startTimer();
    }
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);

