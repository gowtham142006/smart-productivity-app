import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/pomodoro_provider.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Status label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(pomodoro.isBreak),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: pomodoro.isBreak
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pomodoro.isBreak ? '☕ Break Time' : '🍅 Focus Time',
                    style: TextStyle(
                      color: pomodoro.isBreak
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Timer circle
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (pomodoro.status == PomodoroStatus.running)
                            BoxShadow(
                              color: (pomodoro.isBreak
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                    ),

                    // Progress ring
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _TimerPainter(
                        progress: pomodoro.progress,
                        color: pomodoro.isBreak
                            ? AppColors.success
                            : AppColors.primary,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.12),
                      ),
                    ),

                    // Time display
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pomodoro.timeDisplay,
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusLabel(pomodoro.status),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset button
                  if (pomodoro.status != PomodoroStatus.idle)
                    _ControlButton(
                      icon: Icons.stop_rounded,
                      label: 'Stop',
                      onTap: () =>
                          ref.read(pomodoroProvider.notifier).stop(),
                      color: AppColors.error,
                      isSmall: true,
                    ),

                  if (pomodoro.status != PomodoroStatus.idle)
                    const SizedBox(width: 24),

                  // Main play/pause button
                  _ControlButton(
                    icon: _getMainIcon(pomodoro.status),
                    label: _getMainLabel(pomodoro.status),
                    onTap: () => _handleMainAction(ref, pomodoro.status),
                    color: pomodoro.isBreak
                        ? AppColors.success
                        : AppColors.primary,
                    isSmall: false,
                  ),

                  if (pomodoro.status != PomodoroStatus.idle)
                    const SizedBox(width: 24),

                  // Reset button
                  if (pomodoro.status != PomodoroStatus.idle)
                    _ControlButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      onTap: () =>
                          ref.read(pomodoroProvider.notifier).reset(),
                      color: AppColors.warning,
                      isSmall: true,
                    ),
                ],
              ),

              const Spacer(),

              // Session counter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${pomodoro.sessionsCompleted} sessions completed today',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(PomodoroStatus status) {
    switch (status) {
      case PomodoroStatus.idle:
        return 'Ready to focus';
      case PomodoroStatus.running:
        return 'Stay focused...';
      case PomodoroStatus.paused:
        return 'Paused';
      case PomodoroStatus.breakTime:
        return 'Relax & recharge';
    }
  }

  IconData _getMainIcon(PomodoroStatus status) {
    switch (status) {
      case PomodoroStatus.idle:
        return Icons.play_arrow_rounded;
      case PomodoroStatus.running:
      case PomodoroStatus.breakTime:
        return Icons.pause_rounded;
      case PomodoroStatus.paused:
        return Icons.play_arrow_rounded;
    }
  }

  String _getMainLabel(PomodoroStatus status) {
    switch (status) {
      case PomodoroStatus.idle:
        return 'Start';
      case PomodoroStatus.running:
      case PomodoroStatus.breakTime:
        return 'Pause';
      case PomodoroStatus.paused:
        return 'Resume';
    }
  }

  void _handleMainAction(WidgetRef ref, PomodoroStatus status) {
    final notifier = ref.read(pomodoroProvider.notifier);
    switch (status) {
      case PomodoroStatus.idle:
        notifier.start();
      case PomodoroStatus.running:
      case PomodoroStatus.breakTime:
        notifier.pause();
      case PomodoroStatus.paused:
        notifier.resume();
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isSmall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 52.0 : 72.0;
    final iconSize = isSmall ? 24.0 : 36.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSmall
                  ? color.withValues(alpha: 0.1)
                  : color,
              shape: BoxShape.circle,
              boxShadow: isSmall
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isSmall ? color : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the circular timer progress ring.
class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
