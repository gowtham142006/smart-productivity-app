import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // ─── Conversations ─────────────────────────────────

  Future<List<Map<String, dynamic>>> getConversations() async {
    if (_userId == null) return [];

    return await _client
        .from('chat_conversations')
        .select()
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false);
  }

  Future<Map<String, dynamic>> createConversation({
    String title = 'New Chat',
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('chat_conversations')
        .insert({
          'user_id': _userId,
          'title': title,
        })
        .select()
        .single();

    return response;
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await _client
        .from('chat_conversations')
        .update({
          'title': title,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteConversation(String id) async {
    await _client.from('chat_conversations').delete().eq('id', id);
  }

  // ─── Messages ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    return await _client
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  Future<Map<String, dynamic>> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          'role': role,
          'content': content,
          'user_id': _userId,
        })
        .select()
        .single();

    // Also update conversation's updated_at timestamp
    await _client
        .from('chat_conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return response;
  }
}
