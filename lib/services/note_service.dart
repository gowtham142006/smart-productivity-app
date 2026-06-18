import 'package:supabase_flutter/supabase_flutter.dart';

class NoteService {
  final SupabaseClient _client;
  NoteService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getNotes() async {
    if (_userId == null) return [];

    return await _client
        .from('notes')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
  }

  Future<void> addNote({required String title, required String content}) async {
    if (_userId == null) return;

    await _client.from('notes').insert({
      'title': title,
      'content': content,
      'user_id': _userId,
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    await _client
        .from('notes')
        .update({'title': title, 'content': content})
        .eq('id', noteId);
  }
}
