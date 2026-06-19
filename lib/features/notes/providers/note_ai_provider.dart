import 'dart:async';
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
    state = const AsyncLoading();
    try {
      final gemini = ref.read(geminiServiceProvider);
      const systemInstruction = 
          'You are a productivity expert. Extract actionable, clear checklist tasks from the note below. '
          'Each task should start with an action verb and be 3 to 7 words long. '
          'Respond ONLY with the list of extracted tasks, one per line. '
          'Do NOT include numbering, bullet points, markdown formatting, or introductory explanation. '
          'If the note contains no actionable items, write 2 realistic follow-up tasks relevant to the note\'s title.';

      final userPrompt = 'Note Title: ${note.title}\nNote Content:\n${note.content}';

      final response = await gemini.generateProductivityContent(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
      );

      final taskTitles = response
          .split('\n')
          .map((line) {
            var clean = line.trim();
            clean = clean.replaceFirst(RegExp(r'^[\d\-\.\*\•\+\s]+'), '');
            return clean.trim();
          })
          .where((line) => line.isNotEmpty)
          .toList();

      final taskListNotifier = ref.read(taskListProvider.notifier);
      for (final title in taskTitles) {
        await taskListNotifier.addTask(
          title: title,
          description: 'Created from note: "${note.title}"',
          priority: 'medium',
        );
      }

      state = AsyncData('Successfully converted note into ${taskTitles.length} tasks and added them to your Tasks tab.');
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
