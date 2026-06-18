import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/note_model.dart';
import '../../../core/providers/core_providers.dart';

class NoteListNotifier extends AsyncNotifier<List<NoteModel>> {
  @override
  Future<List<NoteModel>> build() async {
    final service = ref.watch(noteServiceProvider);
    final data = await service.getNotes();
    return data.map((e) => NoteModel.fromJson(e)).toList();
  }

  Future<void> addNote({
    required String title,
    required String content,
  }) async {
    final service = ref.read(noteServiceProvider);
    await service.addNote(title: title, content: content);
    ref.invalidateSelf();
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final service = ref.read(noteServiceProvider);
    await service.updateNote(noteId: noteId, title: title, content: content);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String noteId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((n) => n.id != noteId).toList());

    try {
      final service = ref.read(noteServiceProvider);
      await service.deleteNote(noteId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final noteListProvider =
    AsyncNotifierProvider<NoteListNotifier, List<NoteModel>>(
  NoteListNotifier.new,
);

final notesCountProvider = Provider<int>((ref) {
  return ref.watch(noteListProvider).value?.length ?? 0;
});
