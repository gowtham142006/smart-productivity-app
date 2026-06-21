import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/note_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../core/providers/core_providers.dart';

class NoteAiNotifier extends Notifier<AsyncValue<String>> {
  @override
  AsyncValue<String> build() {
    return const AsyncData('');
  }

  Future<void> summarizeNote(NoteModel note) async {
    // Prevent duplicate requests while one is already in-flight
    if (state.isLoading) {
      debugPrint('[NoteAiNotifier] ⚠️ Skipping summarizeNote — request already in-flight');
      return;
    }
    state = const AsyncLoading();
    try {
      final gemini = ref.read(geminiServiceProvider);
      const systemInstruction = 
          'You are an expert notes summarization assistant. '
          'Summarize the note content provided by the user in a concise, structured bulleted list. '
          'Highlight key takeaways, action items, or decisions. '
          'Use clean Markdown formatting. Keep the tone professional, helpful, and direct.';
      
      final userPrompt = 'Note Title: ${note.title}\nNote Content:\n${note.content}';
      
      final response = await gemini.generateProductivityContent(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
      );

      state = AsyncData(response.trim());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> summarizeAllNotes(List<NoteModel> notes) async {
    // Prevent duplicate requests while one is already in-flight
    if (state.isLoading) {
      debugPrint('[NoteAiNotifier] ⚠️ Skipping summarizeAllNotes — request already in-flight');
      return;
    }
    state = const AsyncLoading();
    try {
      if (notes.isEmpty) {
        state = const AsyncData('No notes available to summarize.');
        return;
      }

      final gemini = ref.read(geminiServiceProvider);
      const systemInstruction = 
          'You are an expert information analyst. You will be given a collection of notes. '
          'Analyze them and summarize their main themes, recurring topics, and key action points. '
          'Format the response beautifully in Markdown using clear headings, bullet points, and bold text. '
          'Group related insights together.';

      final userPrompt = notes.map((n) {
        return '--- Note: ${n.title} ---\nContent: ${n.content}';
      }).join('\n\n');

      final response = await gemini.generateProductivityContent(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
      );

      state = AsyncData(response.trim());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Extracts actionable tasks from note content and adds them directly to the Task list.
  /// Returns the list of tasks that were added.
  Future<List<String>> convertNoteToTasks(NoteModel note) async {
    // Prevent duplicate requests while one is already in-flight
    if (state.isLoading) {
      debugPrint('[NoteAiNotifier] ⚠️ Skipping convertNoteToTasks — request already in-flight');
      return [];
    }
    state = const AsyncLoading();
    try {
      final taskListNotifier = ref.read(allTasksProvider.notifier);
      await taskListNotifier.addTask(
        title: note.title,
        description: note.content,
        priority: 'medium',
      );

      final taskTitles = [note.title];
      state = AsyncData('Successfully converted note into a task and added it to your Tasks tab.');
      return taskTitles;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void clearState() {
    state = const AsyncData('');
  }
}

final noteAiProvider = NotifierProvider<NoteAiNotifier, AsyncValue<String>>(
  NoteAiNotifier.new,
);
