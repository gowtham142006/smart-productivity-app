import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/ai_response_models.dart';

// Helper functions for adding tasks to the real database
Future<void> _addSingleTask(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String description = '',
  String priority = 'medium',
  DateTime? dueDate,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  debugPrint('Supabase task insertion triggered (Single): title="$title", description="$description", priority="$priority", dueDate=$dueDate');
  try {
    await ref.read(taskServiceProvider).addTask(
      title: title,
      description: description,
      priority: priority.toLowerCase().trim(),
      dueDate: dueDate,
    );
    debugPrint('Supabase task insertion completed successfully.');
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added task: "$title"'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e, st) {
    debugPrint('Supabase task insertion failed: $e');
    debugPrintStack(stackTrace: st);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to add task: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _addAllTasks(
  BuildContext context,
  WidgetRef ref,
  List<Map<String, dynamic>> tasks,
) async {
  final taskService = ref.read(taskServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  int count = 0;
  
  debugPrint('Supabase task insertion triggered (Batch): totalTasks=${tasks.length}');
  for (var i = 0; i < tasks.length; i++) {
    final t = tasks[i];
    debugPrint('  Task[$i]: title="${t['title']}", priority="${t['priority']}", dueDate=${t['dueDate']}');
  }

  // Show a loading snackbar or indicator
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Importing tasks...'),
      duration: Duration(milliseconds: 500),
      behavior: SnackBarBehavior.floating,
    ),
  );

  try {
    for (var t in tasks) {
      await taskService.addTask(
        title: t['title'] ?? '',
        description: t['description'] ?? '',
        priority: (t['priority'] ?? 'medium').toString().toLowerCase().trim(),
        dueDate: t['dueDate'] as DateTime?,
      );
      count++;
    }
    debugPrint('Supabase task insertion completed successfully. Added $count tasks.');
    messenger.showSnackBar(
      SnackBar(
        content: Text('Successfully imported $count tasks!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e, st) {
    debugPrint('Supabase task insertion failed at index $count: $e');
    debugPrintStack(stackTrace: st);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Imported $count tasks. Error adding remaining: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Widget _buildPriorityBadge(String priority) {
  final cleanPriority = priority.toLowerCase().trim();
  Color bg;
  Color fg;
  switch (cleanPriority) {
    case 'high':
      bg = AppColors.priorityHigh.withOpacity(0.15);
      fg = AppColors.priorityHigh;
      break;
    case 'urgent':
      bg = AppColors.priorityUrgent.withOpacity(0.15);
      fg = AppColors.priorityUrgent;
      break;
    case 'medium':
      bg = AppColors.priorityMedium.withOpacity(0.15);
      fg = AppColors.priorityMedium;
      break;
    case 'low':
    default:
      bg = AppColors.priorityLow.withOpacity(0.15);
      fg = AppColors.priorityLow;
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      priority.toUpperCase(),
      style: TextStyle(
        color: fg,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ----------------------------------------------------
// Main Entry Widget
// ----------------------------------------------------
class StructuredResponseWidget extends ConsumerWidget {
  final dynamic model;
  final VoidCallback onCopyRaw;

  const StructuredResponseWidget({
    super.key,
    required this.model,
    required this.onCopyRaw,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (model is StudyPlanResponse) {
      return StudyPlanWidget(response: model as StudyPlanResponse);
    } else if (model is TaskPlannerResponse) {
      return TaskPlannerWidget(response: model as TaskPlannerResponse);
    } else if (model is TaskGenerationResponse) {
      return TaskGenerationWidget(response: model as TaskGenerationResponse);
    } else if (model is NoteSummarizationResponse) {
      return NoteSummarizationWidget(response: model as NoteSummarizationResponse);
    } else if (model is ConvertNotesToTasksResponse) {
      return ConvertNotesToTasksWidget(response: model as ConvertNotesToTasksResponse);
    } else if (model is ProductivityCoachResponse) {
      return ProductivityCoachWidget(response: model as ProductivityCoachResponse);
    }
    return const SizedBox.shrink();
  }
}

// ----------------------------------------------------
// 1. Study Planner Widget
// ----------------------------------------------------
class StudyPlanWidget extends ConsumerWidget {
  final StudyPlanResponse response;

  const StudyPlanWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'STUDY PLAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    _buildPriorityBadge(response.priority),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  response.goal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                if (response.estimatedTimeHours.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated time: ${response.estimatedTimeHours} hours',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Motivation
                if (response.motivation.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            response.motivation,
                            style: TextStyle(
                              color: textColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Important Topics
                if (response.importantTopics.isNotEmpty) ...[
                  Text(
                    'Key Topics',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: response.importantTopics.map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                        ),
                        child: Text(
                          topic,
                          style: TextStyle(color: textSecondaryColor, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Daily Schedule
                if (response.dailySchedule.isNotEmpty) ...[
                  Text(
                    'Weekly Schedule',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ...response.dailySchedule.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          entry.key,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        leading: Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary.withOpacity(0.8),
                          size: 18,
                        ),
                        dense: true,
                        childrenPadding: const EdgeInsets.only(left: 40, bottom: 8, right: 16),
                        children: entry.value.map((task) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task,
                                    style: TextStyle(color: textSecondaryColor, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_task_rounded, size: 16, color: AppColors.primary),
                                  onPressed: () => _addSingleTask(
                                    context,
                                    ref,
                                    title: task,
                                    description: 'Study Plan Task for ${entry.key}',
                                    priority: response.priority,
                                  ),
                                  tooltip: 'Add to Tasks',
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // Suggested Tasks
                if (response.suggestedTasks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suggested Milestones',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: const Text('Add all to Tasks', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final mappedTasks = response.suggestedTasks.map((t) => {
                            'title': t.title,
                            'description': 'Estimated: ${t.estimatedHours} hrs',
                            'priority': response.priority,
                          }).toList();
                          _addAllTasks(context, ref, mappedTasks);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: response.suggestedTasks.length,
                    itemBuilder: (context, idx) {
                      final task = response.suggestedTasks[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(color: textColor, fontSize: 13.5),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (task.estimatedHours.isNotEmpty)
                              Text(
                                '${task.estimatedHours}h',
                                style: TextStyle(color: textSecondaryColor, fontSize: 12),
                              ),
                            IconButton(
                              icon: const Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
                              onPressed: () => _addSingleTask(
                                context,
                                ref,
                                title: task.title,
                                description: 'Estimated study hours: ${task.estimatedHours}',
                                priority: response.priority,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 2. Task Planner Widget
// ----------------------------------------------------
class TaskPlannerWidget extends ConsumerWidget {
  final TaskPlannerResponse response;

  const TaskPlannerWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'TASK PLANNER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    _buildPriorityBadge(response.priority),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  response.goal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generated Tasks',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.playlist_add_rounded, size: 18),
                      label: const Text('Add all to Tasks', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        final mappedTasks = response.tasks.map((t) {
                          final durationPart = t.estimatedMinutes > 0 ? '\nEstimated: ${t.estimatedMinutes} mins' : '';
                          final deadlinePart = t.suggestedDeadline.isNotEmpty ? '\nDeadline: ${t.suggestedDeadline}' : '';
                          return {
                            'title': t.title,
                            'description': 'From Task Planner.$durationPart$deadlinePart',
                            'priority': t.priority.isNotEmpty ? t.priority : response.priority,
                          };
                        }).toList();
                        _addAllTasks(context, ref, mappedTasks);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: response.tasks.length,
                  itemBuilder: (context, idx) {
                    final task = response.tasks[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 13.5),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildPriorityBadge(task.priority),
                                    if (task.estimatedMinutes > 0) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.timer_outlined, size: 12, color: textSecondaryColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${task.estimatedMinutes}m',
                                        style: TextStyle(color: textSecondaryColor, fontSize: 11),
                                      ),
                                    ],
                                    if (task.suggestedDeadline.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.event_outlined, size: 12, color: textSecondaryColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        task.suggestedDeadline,
                                        style: TextStyle(color: textSecondaryColor, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              final durationPart = task.estimatedMinutes > 0 ? ' (Est: ${task.estimatedMinutes}m)' : '';
                              final deadlinePart = task.suggestedDeadline.isNotEmpty ? ' (Deadline: ${task.suggestedDeadline})' : '';
                              _addSingleTask(
                                context,
                                ref,
                                title: task.title,
                                description: 'From Task Planner$durationPart$deadlinePart',
                                priority: task.priority,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 3. Task Generation Widget
// ----------------------------------------------------
class TaskGenerationWidget extends ConsumerWidget {
  final TaskGenerationResponse response;

  const TaskGenerationWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF10B981), // Emerald/Success color
            child: Row(
              children: [
                const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TASK GENERATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 11,
                        ),
                      ),
                      if (response.source.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Source: ${response.source}',
                          style: const TextStyle(
  color: Colors.white,
  fontSize: 13,
  fontWeight: FontWeight.w500,
),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text('Add all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final mappedTasks = response.tasks.map((t) => {
                      'title': t.title,
                      'description': t.description.isNotEmpty ? t.description : 'From Task Generator',
                      'priority': 'medium',
                    }).toList();
                    _addAllTasks(context, ref, mappedTasks);
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: response.tasks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, idx) {
                final task = response.tasks[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    task.title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(color: textSecondaryColor, fontSize: 12),
                        ),
                      ],
                      if (task.estimatedMinutes > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: textSecondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              '${task.estimatedMinutes} mins',
                              style: TextStyle(color: textSecondaryColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    onPressed: () => _addSingleTask(
                      context,
                      ref,
                      title: task.title,
                      description: task.description,
                      priority: 'medium',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 4. Note Summarization Widget
// ----------------------------------------------------
class NoteSummarizationWidget extends ConsumerWidget {
  final NoteSummarizationResponse response;

  const NoteSummarizationWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF6C63FF).withOpacity(0.85),
            child: Row(
              children: const [
                Icon(Icons.summarize_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'NOTE SUMMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary block
                if (response.summary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.015),
                      border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
                    ),
                    child: Text(
                      response.summary,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Key Points
                if (response.keyPoints.isNotEmpty) ...[
                  Text(
                    'Key Highlights',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...response.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4, right: 8),
                          child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(color: textSecondaryColor, fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],

                // Action Items
                if (response.actionItems.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Action Items',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: const Text('Add all to Tasks', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final mappedTasks = response.actionItems.map((a) => {
                            'title': a.title,
                            'description': a.description.isNotEmpty ? a.description : 'Action Item from Notes',
                            'priority': 'high',
                          }).toList();
                          _addAllTasks(context, ref, mappedTasks);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: response.actionItems.length,
                    itemBuilder: (context, idx) {
                      final item = response.actionItems[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          dense: true,
                          title: Text(
                            item.title,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: item.description.isNotEmpty
                              ? Text(
                                  item.description,
                                  style: TextStyle(color: textSecondaryColor, fontSize: 11.5),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
                            onPressed: () => _addSingleTask(
                              context,
                              ref,
                              title: item.title,
                              description: item.description,
                              priority: 'high',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 5. Convert Notes to Tasks Widget
// ----------------------------------------------------
class ConvertNotesToTasksWidget extends ConsumerWidget {
  final ConvertNotesToTasksResponse response;

  const ConvertNotesToTasksWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF6C63FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.transform_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'CONVERTED TASKS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text('Add all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final mappedTasks = response.tasks.map((t) {
                      return {
                        'title': t.title,
                        'description': t.description.isNotEmpty ? t.description : 'Converted from Notes',
                        'priority': t.priority ?? 'medium',
                      };
                    }).toList();
                    _addAllTasks(context, ref, mappedTasks);
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (response.source.isNotEmpty) ...[
                  Text(
                    'Converted from: ${response.source}',
                    style: TextStyle(color: textSecondaryColor, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                ],
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: response.tasks.length,
                  itemBuilder: (context, idx) {
                    final task = response.tasks[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                  if (task.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description,
                                      style: TextStyle(color: textSecondaryColor, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (task.priority != null) ...[
                                        _buildPriorityBadge(task.priority!),
                                        const SizedBox(width: 8),
                                      ],
                                      if (task.dueDate != null) ...[
                                        Icon(Icons.event_outlined, size: 12, color: textSecondaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.dueDate!,
                                          style: TextStyle(color: textSecondaryColor, fontSize: 11),
                                        ),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_task_rounded, color: AppColors.primary),
                              onPressed: () => _addSingleTask(
                                context,
                                ref,
                                title: task.title,
                                description: task.description,
                                priority: task.priority ?? 'medium',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 6. Productivity Coach Widget
// ----------------------------------------------------
class ProductivityCoachWidget extends StatelessWidget {
  final ProductivityCoachResponse response;

  const ProductivityCoachWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.star_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'PRODUCTIVITY COACH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Focus
                if (response.todaysFocus.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.adjust_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Today's Focus",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...response.todaysFocus.map((focus) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            focus,
                            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],

                // High Priority Tasks
                if (response.highPriority.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.priority_high_rounded, color: AppColors.priorityHigh, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "High Priorities",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...response.highPriority.map((priority) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 26),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 8),
                          child: Icon(Icons.circle, size: 5, color: AppColors.priorityHigh),
                        ),
                        Expanded(
                          child: Text(
                            priority,
                            style: TextStyle(color: textSecondaryColor, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],

                // Time Management
                if (response.timeManagement.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Time Strategy",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...response.timeManagement.map((strategy) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 26),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 8),
                          child: Icon(Icons.circle, size: 5, color: Colors.blue),
                        ),
                        Expanded(
                          child: Text(
                            strategy,
                            style: TextStyle(color: textSecondaryColor, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],

                // Actionable Tips
                if (response.tips.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Coach Tips",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...response.tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 26),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 8),
                          child: Icon(Icons.circle, size: 5, color: Colors.amber),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(color: textSecondaryColor, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
