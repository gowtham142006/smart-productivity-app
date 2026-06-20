import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';
import '../../../core/providers/core_providers.dart';

class TaskAiNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return [];
  }

  Future<void> generateSuggestions() async {
    // Prevent duplicate requests while one is already in-flight
    if (state.isLoading) {
      debugPrint('[TaskAiNotifier] ⚠️ Skipping — request already in-flight');
      return;
    }
    state = const AsyncLoading();
    try {
      final tasks = ref.read(taskListProvider).value ?? [];
      final gemini = ref.read(geminiServiceProvider);

      final pendingTasks = tasks.where((t) => !t.isCompleted).map((t) => t.title).toList();
      
      final String userPrompt;
      if (pendingTasks.isEmpty) {
        userPrompt = 'I have no active tasks currently. Suggest a few general daily productivity tasks to help me start my day.';
      } else {
        userPrompt = 'Here are my current pending tasks:\n${pendingTasks.map((t) => '- $t').join('\n')}\nSuggest 3 to 5 relevant and actionable next tasks to help me progress or manage my workload.';
      }

      const systemInstruction = 
          'You are a personal productivity coach. Your job is to suggest actionable, clear next tasks based on the user\'s current list. '
          'Provide exactly 3 to 5 suggestions. '
          'Respond ONLY with the list of suggestions, one per line. '
          'Do NOT include numbering, bullet points, markdown formatting, introductory text, or explanations. '
          'Each suggested task should be concise (3-7 words) and start with an action verb.';

      final response = await gemini.generateProductivityContent(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
      );

      final suggestions = _parseSuggestions(response);
      state = AsyncData(suggestions);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  List<String> _parseSuggestions(String response) {
    return response
        .split('\n')
        .map((line) {
          // Remove potential leading numbers, dots, dashes, spaces
          var clean = line.trim();
          clean = clean.replaceFirst(RegExp(r'^[\d\-\.\*\•\+\s]+'), '');
          return clean.trim();
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> acceptSuggestion(String suggestion) async {
    await ref.read(taskListProvider.notifier).addTask(
      title: suggestion,
      priority: 'medium',
    );
    // Remove accepted suggestion from the list
    if (state.hasValue) {
      final currentList = state.value ?? [];
      state = AsyncData(currentList.where((s) => s != suggestion).toList());
    }
  }

  void clearSuggestions() {
    state = const AsyncData([]);
  }
}

final taskAiProvider = AsyncNotifierProvider<TaskAiNotifier, List<String>>(
  TaskAiNotifier.new,
);
