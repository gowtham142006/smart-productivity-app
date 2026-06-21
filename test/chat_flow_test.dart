import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:ai_productivity_app/features/chat/providers/chat_provider.dart';
import 'package:ai_productivity_app/core/providers/core_providers.dart';
import 'package:ai_productivity_app/features/chat/domain/chat_repository.dart';
import 'package:ai_productivity_app/services/gemini_service.dart';

// Simple Mocks
class MockChatRepository implements ChatRepository {
  final List<Map<String, dynamic>> messages = [];
  bool failAssistantInsert = false;
  bool failModelInsert = false;

  @override
  supabase.SupabaseClient get _client => throw UnimplementedError();

  @override
  String? get _userId => 'test_user_id';

  @override
  Future<List<Map<String, dynamic>>> getConversations() async => [];

  @override
  Future<Map<String, dynamic>> createConversation({String title = 'New Chat'}) async {
    return {'id': 'test_convo_id', 'title': title};
  }

  @override
  Future<void> updateConversationTitle(String id, String title) async {}

  @override
  Future<void> deleteConversation(String id) async {}

  @override
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    return messages;
  }

  @override
  Future<Map<String, dynamic>> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    if (role == 'assistant' && failAssistantInsert) {
      throw Exception('Database constraint check_role failed for assistant');
    }
    if (role == 'model' && failModelInsert) {
      throw Exception('Database constraint check_role failed for model');
    }

    final msg = {
      'id': 'msg_${messages.length + 1}',
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
    messages.add(msg);
    return msg;
  }
}

class MockGeminiService implements GeminiService {
  @override
  String get _apiKey => 'test_api_key';

  @override
  gemini.GenerativeModel get _model => throw UnimplementedError();

  @override
  DateTime get _lastRequestTime => throw UnimplementedError();

  @override
  set _lastRequestTime(DateTime val) => throw UnimplementedError();

  @override
  Set<int> get _inFlightRequests => throw UnimplementedError();

  @override
  bool _acquireSlot(int requestHash) => true;

  @override
  void _releaseSlot(int requestHash) {}

  @override
  Future<String> generateContent(String prompt) async => 'Gemini Title';

  @override
  Future<String> generateProductivityContent({
    required String systemInstruction,
    required String userPrompt,
  }) async => 'Productivity content';

  @override
  Future<String> sendChatMessage(String message, List<gemini.Content> history) async {
    return 'Hello, I am Gemini AI.';
  }
}

void main() {
  testWidgets('sendChatMessage flow - Scenario 1: Both DB inserts succeed', (tester) async {
    final mockRepo = MockChatRepository();
    final mockGemini = MockGeminiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          geminiServiceProvider.overrideWithValue(mockGemini),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () async {
                    await sendChatMessage(
                      ref: ref,
                      conversationId: 'test_convo_id',
                      content: 'Hello AI',
                    );
                  },
                  child: const Text('Send'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap the button to trigger flow
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Check final list of messages in mock repo
    print('Scenario 1 - Messages in DB:');
    for (final m in mockRepo.messages) {
      print('  Role: ${m['role']}, Content: ${m['content']}');
    }

    expect(mockRepo.messages.length, 2);
    expect(mockRepo.messages[0]['role'], 'user');
    expect(mockRepo.messages[1]['role'], 'assistant');
    expect(mockRepo.messages[1]['content'], 'Hello, I am Gemini AI.');
  });

  testWidgets('sendChatMessage flow - Scenario 2: Assistant fails, fallback model succeeds', (tester) async {
    final mockRepo = MockChatRepository();
    mockRepo.failAssistantInsert = true;
    final mockGemini = MockGeminiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          geminiServiceProvider.overrideWithValue(mockGemini),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () async {
                    await sendChatMessage(
                      ref: ref,
                      conversationId: 'test_convo_id',
                      content: 'Hello AI',
                    );
                  },
                  child: const Text('Send'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap the button to trigger flow
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Check final list of messages in mock repo
    print('Scenario 2 - Messages in DB:');
    for (final m in mockRepo.messages) {
      print('  Role: ${m['role']}, Content: ${m['content']}');
    }

    expect(mockRepo.messages.length, 2);
    expect(mockRepo.messages[0]['role'], 'user');
    expect(mockRepo.messages[1]['role'], 'model'); // Saved as fallback
    expect(mockRepo.messages[1]['content'], 'Hello, I am Gemini AI.');
  });

  testWidgets('sendChatMessage flow - Scenario 3: Both inserts fail', (tester) async {
    final mockRepo = MockChatRepository();
    mockRepo.failAssistantInsert = true;
    mockRepo.failModelInsert = true;
    final mockGemini = MockGeminiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          geminiServiceProvider.overrideWithValue(mockGemini),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () async {
                    await sendChatMessage(
                      ref: ref,
                      conversationId: 'test_convo_id',
                      content: 'Hello AI',
                    );
                  },
                  child: const Text('Send'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap the button to trigger flow
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Check final list of messages in mock repo
    print('Scenario 3 - Messages in DB:');
    for (final m in mockRepo.messages) {
      print('  Role: ${m['role']}, Content: ${m['content']}');
    }

    expect(mockRepo.messages.length, 1); // Only user message was saved!
    expect(mockRepo.messages[0]['role'], 'user');
  });
}
