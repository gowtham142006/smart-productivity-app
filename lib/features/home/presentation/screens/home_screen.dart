import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../../notes/providers/note_provider.dart';
import '../../../notifications/providers/notification_history_provider.dart';
import '../widgets/current_streak_card.dart';
import '../widgets/upcoming_deadlines_card.dart';
import '../widgets/recent_notes_card.dart';
import '../widgets/productivity_summary_card.dart';
import '../widgets/daily_plan_card.dart';
import '../../../tasks/presentation/widgets/ai_task_suggestions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Profile name sync: use profileProvider instead of email splitting
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'User';

    // Fallback: email-based username if profile hasn't loaded yet
    final profileName = profileAsync.value?.name;
    final avatarUrl = profileAsync.value?.avatarUrl;
    final username = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : email.split('@').first;

    final pendingCount = ref.watch(pendingTasksCountProvider);
    final completedCount = ref.watch(completedTasksCountProvider);
    final overdueCount = ref.watch(overdueTasksCountProvider);
    final notesCount = ref.watch(notesCountProvider);
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 1. ─── Greeting + Avatar ───
                Row(
                  children: [
                    // Avatar
                    _buildAvatar(username, avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $username 👋',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGreetingSubtitle(),
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. ─── Today's Progress (Stats Grid) ───
                Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Pending',
                        count: pendingCount,
                        icon: Icons.pending_actions,
                        color: AppColors.info,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).setShowCompleted(false);
                          context.go('/tasks');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Completed',
                        count: completedCount,
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).setShowCompleted(true);
                          context.go('/tasks');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Overdue',
                        count: overdueCount,
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).setShowOverdue(true);
                          context.go('/tasks');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Notes',
                        count: notesCount,
                        icon: Icons.note_outlined,
                        color: AppColors.warning,
                        onTap: () => context.go('/notes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. ─── Current Streak ───
                const CurrentStreakCard(),
                const SizedBox(height: 24),

                // 4. ─── AI Planner ───
                const DailyPlanCard(),
                const AiTaskSuggestions(),
                const SizedBox(height: 24),

                // 5. ─── Upcoming Deadlines ───
                const UpcomingDeadlinesCard(),
                const SizedBox(height: 24),

                // 6. ─── Quick Actions ───
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardTile(
                        title: 'Calendar',
                        icon: Icons.calendar_month_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/calendar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardTile(
                        title: 'Habits',
                        icon: Icons.repeat_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/habits'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardTile(
                        title: 'Pomodoro',
                        icon: Icons.timer_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/pomodoro'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardTile(
                        title: 'Analytics',
                        icon: Icons.insights_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/analytics'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. ─── Recent Notes ───
                const RecentNotesCard(),
                const SizedBox(height: 24),

                // 8. ─── Productivity Summary ───
                const ProductivitySummaryCard(),
                const SizedBox(height: 32),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String username, String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 24,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(username),
      );
    }
    return _buildInitialsAvatar(username);
  }

  Widget _buildInitialsAvatar(String username) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! Stay productive today ☀️';
    if (hour < 17) return 'Good afternoon! Keep up the momentum 🚀';
    return 'Good evening! Wind down with focus 🌙';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard tile for feature access.
class _DashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
