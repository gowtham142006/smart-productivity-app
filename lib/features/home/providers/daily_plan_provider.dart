import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/providers/task_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../../core/providers/core_providers.dart';

class DailyPlanNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return '';
  }

  Future<void> generateDailyPlan() async {
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

      state = AsyncData(response.trim());
    } catch (e, st) {
      state = AsyncError(e, st);
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

  void clearPlan() {
    state = const AsyncData('');
  }
}

final dailyPlanProvider = AsyncNotifierProvider<DailyPlanNotifier, String>(
  DailyPlanNotifier.new,
);
