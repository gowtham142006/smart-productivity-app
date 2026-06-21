import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import '../data/conversation_model.dart';
import '../data/message_model.dart';
import '../../../core/providers/core_providers.dart';

// ─── Conversation List ─────────────────────────────

class ConversationListNotifier
    extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final data = await repo.getConversations();
    return data.map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<ConversationModel> createConversation() async {
    final repo = ref.read(chatRepositoryProvider);
    final data = await repo.createConversation();
    final conversation = ConversationModel.fromJson(data);
    debugPrint('[ChatProvider] ✅ Created conversation: ${conversation.id}');
    ref.invalidateSelf();
    return conversation;
  }

  Future<void> deleteConversation(String id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((c) => c.id != id).toList());

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.deleteConversation(id);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateTitle(String id, String title) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.updateConversationTitle(id, title);
    ref.invalidateSelf();
  }
}

final conversationListProvider = AsyncNotifierProvider<
    ConversationListNotifier, List<ConversationModel>>(
  ConversationListNotifier.new,
);

// ─── UI State ──────────────────────────────────────

class ActiveConversationIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final activeConversationIdProvider =
    NotifierProvider<ActiveConversationIdNotifier, String?>(
  ActiveConversationIdNotifier.new,
);

final isGeneratingProvider = NotifierProvider<IsGeneratingNotifier, bool>(
  IsGeneratingNotifier.new,
);

class IsGeneratingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

// ─── Chat Messages (per conversation) ──────────────

/// Provides the message list for a conversation (read-only from Supabase)
final chatMessagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, conversationId) async {
  final repo = ref.watch(chatRepositoryProvider);
  final data = await repo.getMessages(conversationId);
  debugPrint('[ChatProvider] 📨 Loaded ${data.length} messages for conversation: $conversationId');

  final messages = data.map((e) {
    debugPrint('[ChatProvider]    → role="${e['role']}", content="${(e['content'] as String?)?.substring(0, (e['content'] as String?)?.length.clamp(0, 60) ?? 0)}..."');
    return MessageModel.fromJson(e);
  }).toList();

  return messages;
});

/// Sends a message and refreshes the message list
Future<void> sendChatMessage({
  required WidgetRef ref,
  required String conversationId,
  required String content,
}) async {
  final repo = ref.read(chatRepositoryProvider);
  final geminiService = ref.read(geminiServiceProvider);

  debugPrint('[ChatProvider] ═══════════════════════════════════════');
  debugPrint('[ChatProvider] 📤 sendChatMessage() START');
  debugPrint('[ChatProvider]    conversationId: $conversationId');
  debugPrint('[ChatProvider]    content: "${content.substring(0, content.length.clamp(0, 80))}..."');

  // 1. Save user message to Supabase
  try {
    final userInsertResult = await repo.addMessage(
      conversationId: conversationId,
      role: 'user',
      content: content,
    );
    debugPrint('[ChatProvider] ✅ Step 1: User message inserted (id: ${userInsertResult['id']})');
  } catch (e, st) {
    debugPrint('[ChatProvider] ❌ Step 1 FAILED: Could not insert user message');
    debugPrint('[ChatProvider]    Error: $e');
    debugPrint('[ChatProvider]    Stack: $st');
    return; // Abort if we can't even save the user message
  }

  // Refresh to show user message immediately
  ref.invalidate(chatMessagesProvider(conversationId));

  // 2. Set generating flag
  ref.read(isGeneratingProvider.notifier).set(true);
  debugPrint('[ChatProvider] ✅ Step 2: isGenerating = true');

  try {
    // 3. Build Gemini history from saved messages
    final messagesData = await repo.getMessages(conversationId);
    final messages =
        messagesData.map((e) => MessageModel.fromJson(e)).toList();
    debugPrint('[ChatProvider] ✅ Step 3: Loaded ${messages.length} messages for history');

    // Build history (all messages except the last user message)
    // Map DB roles to Gemini SDK roles:
    //   DB 'user' → Gemini 'user'
    //   DB 'assistant' → Gemini 'model' (Gemini SDK expects 'model', not 'assistant')
    final history = messages
        .take(messages.length > 1 ? messages.length - 1 : 0)
        .map((m) {
          // Gemini SDK requires role to be 'user' or 'model'
          final geminiRole = m.role == MessageRole.assistant ? 'model' : m.role.value;
          return gemini.Content(geminiRole, [gemini.TextPart(m.content)]);
        })
        .toList();

    debugPrint('[ChatProvider]    History entries: ${history.length}');

    // 4. Call Gemini
    debugPrint('[ChatProvider] 📤 Step 4: Calling Gemini sendChatMessage()...');
    final response = await geminiService.sendChatMessage(content, history);
    debugPrint('[ChatProvider] ✅ Step 4: Gemini responded (${response.length} chars)');
    debugPrint('[ChatProvider]    Response preview: "${response.substring(0, response.length.clamp(0, 100))}..."');

    // 5. Save AI response to Supabase with role='assistant' (matches DB schema)
    try {
      final aiInsertResult = await repo.addMessage(
        conversationId: conversationId,
        role: 'assistant',
        content: response,
      );
      debugPrint('[ChatProvider] ✅ Step 5: Assistant message inserted (id: ${aiInsertResult['id']})');
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Step 5 FAILED: Could not insert assistant message');
      debugPrint('[ChatProvider]    Error: $e');
      debugPrint('[ChatProvider]    Stack: $st');
      // Try the old 'model' role as fallback
      debugPrint('[ChatProvider]    Retrying with role="model"...');
      try {
        await repo.addMessage(
          conversationId: conversationId,
          role: 'model',
          content: response,
        );
        debugPrint('[ChatProvider]    ✅ Fallback insert with role="model" succeeded');
      } catch (e2) {
        debugPrint('[ChatProvider]    ❌ Fallback also failed: $e2');
      }
    }

    // 6. Auto-title from first user message
    if (messages.length <= 1) {
      debugPrint('[ChatProvider] 📤 Step 6: Auto-titling conversation...');
      _autoTitleConversation(ref, conversationId, content);
    }
  } catch (e, st) {
    debugPrint('[ChatProvider] ❌ Chat error at Gemini/save step');
    debugPrint('[ChatProvider]    Error type: ${e.runtimeType}');
    debugPrint('[ChatProvider]    Error: $e');
    debugPrint('[ChatProvider]    Stack: $st');

    // Save error message so user sees feedback — try 'assistant' first, then 'model'
    try {
      await repo.addMessage(
        conversationId: conversationId,
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      );
    } catch (_) {
      try {
        await repo.addMessage(
          conversationId: conversationId,
          role: 'model',
          content: 'Sorry, I encountered an error. Please try again.',
        );
      } catch (e2) {
        debugPrint('[ChatProvider]    ❌ Could not save error message either: $e2');
      }
    }
  } finally {
    ref.read(isGeneratingProvider.notifier).set(false);
    debugPrint('[ChatProvider] ✅ isGenerating = false');
    // Refresh messages to show AI response
    ref.invalidate(chatMessagesProvider(conversationId));
    debugPrint('[ChatProvider] ✅ Messages invalidated — UI should refresh');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }
}

Future<void> _autoTitleConversation(
    WidgetRef ref, String conversationId, String firstMessage) async {
  try {
    final geminiService = ref.read(geminiServiceProvider);
    final title = await geminiService.generateContent(
      'Generate a short title (max 5 words) for a chat that starts with: '
      '"$firstMessage". Return ONLY the title, no quotes, no punctuation at the end.',
    );

    final cleanTitle = title.trim().replaceAll('"', '').replaceAll("'", '');
    if (cleanTitle.isNotEmpty && cleanTitle.length < 60) {
      await ref
          .read(conversationListProvider.notifier)
          .updateTitle(conversationId, cleanTitle);
      debugPrint('[ChatProvider] ✅ Auto-titled: "$cleanTitle"');
    }
  } catch (e) {
    debugPrint('[ChatProvider] ⚠️ Auto-title error (non-fatal): $e');
  }
}
