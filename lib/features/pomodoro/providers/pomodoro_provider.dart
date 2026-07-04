import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../services/notification_service.dart';

/// Pomodoro timer states.
enum PomodoroStatus { idle, running, paused, breakTime }

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
  static const int _workMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;
  static const int _sessionsBeforeLongBreak = 4;

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PomodoroState();
  }

  void start() {
    if (state.status == PomodoroStatus.running) return;

    state = state.copyWith(status: PomodoroStatus.running);
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
    state = PomodoroState(
      sessionsCompleted: state.sessionsCompleted,
    );
  }

  void stop() {
    _timer?.cancel();
    state = const PomodoroState();
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
    if (!state.isBreak) {
      // Work session completed
      final newSessions = state.sessionsCompleted + 1;

      // Auto-save to daily stats (Decision #9)
      try {
        final statsService = ref.read(dailyStatsServiceProvider);
        await statsService.incrementStat('pomodoro_sessions');
        await statsService.incrementStat('pomodoro_minutes',
            amount: _workMinutes);
        debugPrint(
            '[Pomodoro] Session $newSessions saved to daily_stats');
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
          newSessions % _sessionsBeforeLongBreak == 0;
      final breakMinutes =
          isLongBreak ? _longBreakMinutes : _shortBreakMinutes;

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

      // Reset to work mode
      state = PomodoroState(
        status: PomodoroStatus.idle,
        sessionsCompleted: state.sessionsCompleted,
      );
    }
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);
