import 'package:supabase_flutter/supabase_flutter.dart';

class NoteService {
  final supabase = Supabase.instance.client;

  Future<void> addNote({required String title, required String content}) async {
    final user = supabase.auth.currentUser;

    await supabase.from('notes').insert({
      'title': title,

      'content': content,

      'user_id': user!.id,
    });
  }

  Future<List<dynamic>> getNotes() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('notes')
        .select()
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> deleteNote(String noteId) async {
    await supabase.from('notes').delete().eq('id', noteId);
  }

  Future<void> updateNote({
    required String noteId,

    required String title,

    required String content,
  }) async {
    await supabase
        .from('notes')
        .update({'title': title, 'content': content})
        .eq('id', noteId);
  }
}
