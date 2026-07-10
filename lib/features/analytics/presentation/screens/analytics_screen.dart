import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/daily_stats_model.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(fullAnalyticsProvider);
    final insightAsync = ref.watch(aiInsightProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(fullAnalyticsProvider);
              ref.read(aiInsightProvider.notifier).refreshInsight();
            },
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ Productivity Score Cards ═══
              Row(
                children: [
                  Expanded(
                    child: _ScoreCard(
                      label: 'Weekly',
                      score: data.weeklyProductivityScore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreCard(
                      label: 'Monthly',
                      score: data.monthlyProductivityScore,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ═══ Task Overview ═══
              _SectionTitle(
                  title: 'Task Overview', icon: Icons.task_alt_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Completed',
                      value: '${data.completedTasks}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Pending',
                      value: '${data.pendingTasks}',
                      icon: Icons.pending_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Overdue',
                      value: '${data.overdueTasks}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MiniStatCard(
                label: 'Completed Today',
                value: '${data.todayCompletedTasks}',
                icon: Icons.today_rounded,
                color: AppColors.primary,
                isWide: true,
              ),

              const SizedBox(height: 24),

              // ═══ Weekly Tasks Chart ═══
              _SectionTitle(
                  title: 'Tasks This Week', icon: Icons.bar_chart_rounded),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: data.weeklyStats.isEmpty
                    ? _EmptyChartState(message: 'No task data this week')
                    : _TasksBarChart(stats: data.weeklyStats, isDark: isDark),
              ),

              const SizedBox(height: 24),

              // ═══ Habit Stats ═══
              _SectionTitle(
                  title: 'Habit Stats', icon: Icons.repeat_rounded),
              const SizedBox(height: 12),
              _HabitStatsCard(
                activeHabits: data.totalActiveHabits,
                completedToday: data.habitsCompletedToday,
                completionRate: data.habitCompletionRate,
                currentStreak: data.currentBestStreak,
                longestStreak: data.longestStreak,
              ),

              const SizedBox(height: 24),

              // ═══ Focus Stats ═══
              _SectionTitle(
                  title: 'Focus Stats', icon: Icons.timer_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Sessions Today',
                      value: '${data.todayPomodoroSessions}',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Today Focus',
                      value: data.todayFocusFormatted,
                      icon: Icons.access_time_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total Sessions',
                      value: '${data.totalPomodoroSessions}',
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total Focus',
                      value: data.totalFocusFormatted,
                      icon: Icons.hourglass_bottom_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ═══ Focus Sessions Chart ═══
              _SectionTitle(
                  title: 'Focus This Week', icon: Icons.insights_rounded),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: data.weeklyStats.isEmpty
                    ? _EmptyChartState(message: 'No focus data this week')
                    : _PomodoroBarChart(
                        stats: data.weeklyStats, isDark: isDark),
              ),

              const SizedBox(height: 24),

              // ═══ AI Insight ═══
              _SectionTitle(
                  title: 'AI Insight', icon: Icons.auto_awesome_rounded),
              const SizedBox(height: 8),
              insightAsync.when(
                data: (insight) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Generating insight...'),
                      ],
                    ),
                  ),
                ),
                error: (error, stack) => const SizedBox(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreCard({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor(score),
            _scoreColor(score).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _scoreColor(score).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _scoreLabel(score),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.primary;
    if (score >= 25) return AppColors.warning;
    return AppColors.error;
  }

  static String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent! 🔥';
    if (score >= 50) return 'Good Progress 💪';
    if (score >= 25) return 'Building Up 🌱';
    return 'Getting Started 🚀';
  }
}

class _HabitStatsCard extends StatelessWidget {
  final int activeHabits;
  final int completedToday;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;

  const _HabitStatsCard({
    required this.activeHabits,
    required this.completedToday,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    if (activeHabits == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.repeat_rounded,
                    size: 36, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text(
                  'No active habits yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create habits to see your stats here',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pctText = '${(completionRate * 100).round()}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Completion progress
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: completionRate,
                          strokeWidth: 6,
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.success),
                        ),
                      ),
                      Center(
                        child: Text(
                          pctText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedToday of $activeHabits done today',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily completion rate',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Streaks
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currentStreak days',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Current Best',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$longestStreak days',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Longest Streak',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final String message;

  const _EmptyChartState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _TasksBarChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  final bool isDark;

  const _TasksBarChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _maxY(stats.map((s) => s.tasksCompleted.toDouble())),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= stats.length) return const SizedBox();
                    final date = stats[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat.E().format(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: stats.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.tasksCompleted.toDouble(),
                    color: AppColors.success,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _maxY(Iterable<double> values) {
    if (values.isEmpty) return 5;
    final m = values.reduce((a, b) => a > b ? a : b);
    return m < 5 ? 5 : m + 2;
  }
}

class _PomodoroBarChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  final bool isDark;

  const _PomodoroBarChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _maxY(
                stats.map((s) => s.pomodoroSessions.toDouble())),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= stats.length) return const SizedBox();
                    final date = stats[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat.E().format(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: stats.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.pomodoroSessions.toDouble(),
                    color: AppColors.primary,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _maxY(Iterable<double> values) {
    if (values.isEmpty) return 5;
    final m = values.reduce((a, b) => a > b ? a : b);
    return m < 5 ? 5 : m + 2;
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isWide ? 14 : 16),
        child: isWide
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
