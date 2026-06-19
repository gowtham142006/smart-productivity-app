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

final isGeneratingProvider = NotifierProvider<IsGeneratingNotifier, bool>(
  IsGeneratingNotifier.new,
);

class IsGeneratingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

// ─── Chat Messages (per conversation) ──────────────
// Using .family with a simple FutureProvider + a separate notifier approach
// since FamilyAsyncNotifier is not available in Riverpod 3.2

/// Provides the message list for a conversation (read-only from Supabase)
final chatMessagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, conversationId) async {
  final repo = ref.watch(chatRepositoryProvider);
  final data = await repo.getMessages(conversationId);
  return data.map((e) => MessageModel.fromJson(e)).toList();
});

/// Sends a message and refreshes the message list
Future<void> sendChatMessage({
  required WidgetRef ref,
  required String conversationId,
  required String content,
}) async {
  final repo = ref.read(chatRepositoryProvider);
  final geminiService = ref.read(geminiServiceProvider);

  // 1. Save user message to Supabase
  await repo.addMessage(
    conversationId: conversationId,
    role: 'user',
    content: content,
  );

  // Refresh to show user message immediately
  ref.invalidate(chatMessagesProvider(conversationId));

  // 2. Set generating flag
  ref.read(isGeneratingProvider.notifier).set(true);

  try {
    // 3. Build Gemini history from saved messages
    final messagesData = await repo.getMessages(conversationId);
    final messages =
        messagesData.map((e) => MessageModel.fromJson(e)).toList();

    // Build history (all messages except the last user message)
    final history = messages
        .take(messages.length > 1 ? messages.length - 1 : 0)
        .map((m) => gemini.Content(m.role.value, [gemini.TextPart(m.content)]))
        .toList();

    // 4. Call Gemini
    final response = await geminiService.sendChatMessage(content, history);

    // 5. Save AI response to Supabase
    await repo.addMessage(
      conversationId: conversationId,
      role: 'model',
      content: response,
    );

    // 6. Auto-title from first user message
    if (messages.length <= 1) {
      _autoTitleConversation(ref, conversationId, content);
    }
  } catch (e) {
    debugPrint('Chat error: $e');

    // Save error message so user sees feedback
    await repo.addMessage(
      conversationId: conversationId,
      role: 'model',
      content: 'Sorry, I encountered an error. Please try again.',
    );
  } finally {
    ref.read(isGeneratingProvider.notifier).set(false);
    // Refresh messages to show AI response
    ref.invalidate(chatMessagesProvider(conversationId));
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
    }
  } catch (e) {
    debugPrint('Auto-title error: $e');
  }
}
