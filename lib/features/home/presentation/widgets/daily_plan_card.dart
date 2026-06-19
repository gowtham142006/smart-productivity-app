import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../providers/daily_plan_provider.dart';

class DailyPlanCard extends ConsumerWidget {
  const DailyPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dailyPlanProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkCard]
                : [Colors.white, AppColors.surfaceVariant.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: planAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 16),
                  Text(
                    'Crafting your daily schedule...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Failed to generate plan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(dailyPlanProvider.notifier).generateDailyPlan(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
          data: (planText) {
            if (planText.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Daily Planner',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Generate a custom schedule for today',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(dailyPlanProvider.notifier).generateDailyPlan(),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Generate My Day'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'My AI Daily Plan',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                        onPressed: () => ref.read(dailyPlanProvider.notifier).generateDailyPlan(),
                        tooltip: 'Regenerate plan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () => ref.read(dailyPlanProvider.notifier).clearPlan(),
                        tooltip: 'Clear plan',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Display parsed schedule
                  ..._parseMarkdownToWidgets(planText, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _parseMarkdownToWidgets(String markdown, bool isDark) {
    final List<Widget> widgets = [];
    final lines = markdown.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Headers (e.g. #, ##, ###)
      if (trimmed.startsWith('#')) {
        final level = trimmed.indexOf(RegExp(r'[^#]'));
        final text = trimmed.substring(level).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: level == 1 ? 20 : level == 2 ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: level <= 2 ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
        );
      }
      // List items starting with -, *, or emoji
      else if (trimmed.startsWith('-') || trimmed.startsWith('*') || trimmed.startsWith('•')) {
        final text = trimmed.replaceFirst(RegExp(r'^[\-\*\•]\s*'), '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, right: 8.0),
                  child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineBold(text, isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Task Block with specific headers like 🌅 Morning, ☀️ Afternoon
      else if (trimmed.startsWith('🌅') || trimmed.startsWith('☀️') || trimmed.startsWith('🌆') || trimmed.startsWith('⏰') || trimmed.startsWith('📅') || trimmed.startsWith('📋') || trimmed.startsWith('⚠️')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }
      // Regular paragraphs
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                children: _parseInlineBold(trimmed, isDark),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<TextSpan> _parseInlineBold(String text, bool isDark) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(color: color, fontSize: 14, height: 1.4),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(color: color, fontSize: 14, height: 1.4),
        ),
      );
    }

    return spans;
  }
}
