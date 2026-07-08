import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../tasks/providers/task_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../../core/providers/core_providers.dart';

class DailyPlanNotifier extends AsyncNotifier<String> {
  static const _boxName = 'settings';
  static const _planTextKey = 'daily_plan_text';
  static const _planDateKey = 'daily_plan_date';

  @override
  Future<String> build() async {
    // Restore cached plan if it's from today
    return _loadCachedPlan();
  }

  /// Load the cached plan from Hive. Returns empty if no plan for today.
  String _loadCachedPlan() {
    try {
      final box = Hive.box(_boxName);
      final cachedDate = box.get(_planDateKey, defaultValue: '');
      final today = DateTime.now().toIso8601String().split('T').first;

      if (cachedDate == today) {
        final cachedText = box.get(_planTextKey, defaultValue: '');
        if (cachedText.isNotEmpty) {
          debugPrint('[DailyPlan] Restored cached plan for $today');
          return cachedText;
        }
      }
    } catch (e) {
      debugPrint('[DailyPlan] Error loading cached plan: $e');
    }
    return '';
  }

  Future<void> generateDailyPlan() async {
    // Prevent duplicate requests while one is already in-flight
    if (state.isLoading) {
      debugPrint('[DailyPlanNotifier] ⚠️ Skipping — request already in-flight');
      return;
    }
    state = const AsyncLoading();
    try {
      final tasks = ref.read(taskListProvider).value ?? [];
      final notes = ref.read(noteListProvider).value ?? [];
      final gemini = ref.read(geminiServiceProvider);

      final now = DateTime.now();
      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
      final overdueTasks = tasks
          .where((t) => t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted)
          .toList();
      final recentNotes = notes.take(5).toList();

      final String userPrompt = _buildDailyPlanPrompt(
        pendingTasks: pendingTasks,
        overdueTasks: overdueTasks,
        recentNotes: recentNotes,
        currentTime: now,
      );

      const systemInstruction = 
          'You are a high-performance productivity coach and daily planning assistant. '
          'Your job is to generate a structured, encouraging daily plan based on the user\'s tasks and notes. '
          'Format the plan using clean Markdown. Use emojis, clear headers, and time-block sections (e.g. 🌅 Morning, ☀️ Afternoon, 🌆 Evening). '
          'Highlight top priorities and overdue tasks first. '
          'If there are no tasks, encourage them to create some or write a few inspirational ideas for today. '
          'Make it clean, readable, and highly actionable without unnecessary preamble.';

      final response = await gemini.generateProductivityContent(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
      );

      final planText = response.trim();

      // Persist to Hive
      await _savePlan(planText);

      state = AsyncData(planText);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Save plan text and today's date to Hive.
  Future<void> _savePlan(String text) async {
    try {
      final box = Hive.box(_boxName);
      final today = DateTime.now().toIso8601String().split('T').first;
      await box.put(_planTextKey, text);
      await box.put(_planDateKey, today);
      debugPrint('[DailyPlan] ✅ Plan saved to Hive for $today');
    } catch (e) {
      debugPrint('[DailyPlan] Error saving plan: $e');
    }
  }

  String _buildDailyPlanPrompt({
    required List<dynamic> pendingTasks,
    required List<dynamic> overdueTasks,
    required List<dynamic> recentNotes,
    required DateTime currentTime,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Current Date/Time: ${currentTime.toLocal().toString().split('.').first}');
    
    if (overdueTasks.isNotEmpty) {
      buffer.writeln('\n⚠️ OVERDUE TASKS (Must prioritize today):');
      for (final t in overdueTasks) {
        buffer.writeln('- ${t.title} (Priority: ${t.priority})');
      }
    }

    if (pendingTasks.isNotEmpty) {
      buffer.writeln('\n📋 PENDING TASKS:');
      for (final t in pendingTasks) {
        final dueStr = t.dueDate != null ? 'Due: ${t.dueDate.toString().split(' ').first}' : 'No due date';
        buffer.writeln('- ${t.title} (Priority: ${t.priority}, $dueStr)');
      }
    } else {
      buffer.writeln('\nNo active tasks listed currently.');
    }

    if (recentNotes.isNotEmpty) {
      buffer.writeln('\n📝 RECENT NOTES & IDEAS:');
      for (final n in recentNotes) {
        buffer.writeln('- ${n.title}');
      }
    }

    buffer.writeln('\nPlease construct a structured daily schedule, highlight the 3 key focus points for today, and divide the plan into clear time blocks.');
    return buffer.toString();
  }

  /// Clear the plan from state and Hive.
  void clearPlan() {
    try {
      final box = Hive.box(_boxName);
      box.delete(_planTextKey);
      box.delete(_planDateKey);
      debugPrint('[DailyPlan] Plan cleared from Hive');
    } catch (e) {
      debugPrint('[DailyPlan] Error clearing plan: $e');
    }
    state = const AsyncData('');
  }
}

final dailyPlanProvider = AsyncNotifierProvider<DailyPlanNotifier, String>(
  DailyPlanNotifier.new,
);

