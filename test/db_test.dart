import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/features/chat/domain/chat_repository.dart';

void main() {
  test('Verify ChatRepository Message Insertion and Retrieval', () async {
    // Load .env
    await dotenv.load(fileName: ".env");
    final url = dotenv.get('SUPABASE_URL');
    final key = dotenv.get('SUPABASE_ANON_KEY');
    
    // Initialize Supabase
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
    
    final client = Supabase.instance.client;
    print('Supabase initialized.');

    final sessionJson = '{"access_token":"eyJhbGciOiJFUzI1NiIsImtpZCI6ImQ3YjUxNjUxLTQyYjgtNDllOS1iZmY2LWJhNjk0MzAxY2ExZSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3J0cm1zdWVkenZybXNpdmdzeGJjLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJhOGIxYTc4Ni03Y2M0LTRmMzAtYTBhMC1jM2U0MDIxNjI2N2EiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzgyMDQxOTY1LCJpYXQiOjE3ODIwMzgzNjUsImVtYWlsIjoiZ293dGhhbTIwMDZhQGdtYWlsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWwiOiJnb3d0aGFtMjAwNmFAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBob25lX3ZlcmlmaWVkIjpmYWxzZSwic3ViIjoiYThiMWE3ODYtN2NjNC00ZjMwLWEwYTAtYzNlNDAyMTYyNjdhIn0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3ODE4NzY0NTV9XSwic2Vzc2lvbl9pZCI6IjJjMTY0OGJmLWQ5YWUtNDM5Yy1hZjA3LWI5OGFiZWY2YmViOCIsImlzX2Fub255bW91cyI6ZmFsc2V9.KS4K6108zbFiSDPOAcQl-yBdt-XuFepPvJwqYAU5AzlW9GhP8H9hK60rPtm77hXJ9UJyntl2CChsuOp5PNtN3w","expires_in":3600,"expires_at":1782041965,"refresh_token":"riiewq3qzmqe","token_type":"bearer","user":{"id":"a8b1a786-7cc4-4f30-a0a0-c3e40216267a","email":"gowtham2006a@gmail.com","role":"authenticated"}}';

    try {
      print('Recovering session...');
      final response = await client.auth.recoverSession(sessionJson);
      final userId = response.user?.id;
      print('Authenticated successfully as: ${response.user?.email} (ID: $userId)');

      final repo = ChatRepository(client);

      // Create conversation
      print('Creating conversation...');
      final convo = await repo.createConversation(title: 'Repo Test Convo');
      final convoId = convo['id'];
      print('Conversation created: $convoId');

      // Add user message
      print('Adding user message...');
      final userMsg = await repo.addMessage(
        conversationId: convoId,
        role: 'user',
        content: 'Hi, I am a user.',
      );
      print('✅ User message saved: ${userMsg['id']}');

      // Add assistant message
      print('Adding assistant message...');
      final assistantMsg = await repo.addMessage(
        conversationId: convoId,
        role: 'assistant',
        content: 'Hello, I am the assistant response.',
      );
      print('✅ Assistant message saved: ${assistantMsg['id']}');

      // Query messages
      print('Querying messages...');
      final messages = await repo.getMessages(convoId);
      print('Retrieved ${messages.length} messages:');
      for (final m in messages) {
        print('  - [${m['role']}]: ${m['content']}');
      }

      // Assertions
      expect(messages.length, equals(2));
      expect(messages[0]['role'], equals('user'));
      expect(messages[1]['role'], equals('assistant'));

      // Cleanup
      print('Cleaning up...');
      await repo.deleteConversation(convoId);
      print('Cleanup complete.');

    } catch (e, st) {
      print('Test failed: $e');
      print('Stack: $st');
      fail('Expected successful repository message handling');
    }
  });
}



