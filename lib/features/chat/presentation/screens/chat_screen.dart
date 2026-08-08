import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../data/conversation_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/empty_chat_state.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ensureConversation() async {
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId != null) return;

    final conversation = await ref
        .read(conversationListProvider.notifier)
        .createConversation();
    ref.read(activeConversationIdProvider.notifier).set(conversation.id);
  }

  void _sendMessage(String content) async {
    await _ensureConversation();
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId == null) return;

    await sendChatMessage(
      ref: ref,
      conversationId: activeId,
      content: content,
    );
    _scrollToBottom();
  }

  void _startNewChat() {
    ref.read(activeConversationIdProvider.notifier).set(null);
  }

  void _loadConversation(ConversationModel conversation) {
    ref.read(activeConversationIdProvider.notifier).set(conversation.id);
    Navigator.of(context).pop(); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating = ref.watch(isGeneratingProvider);
    final conversationsAsync = ref.watch(conversationListProvider);
    final activeConversationId = ref.watch(activeConversationIdProvider);

    // Watch messages if we have an active conversation
    final messagesAsync = activeConversationId != null
        ? ref.watch(chatMessagesProvider(activeConversationId))
        : null;

    // Auto-scroll when messages change
    if (messagesAsync != null && activeConversationId != null) {
      ref.listen(chatMessagesProvider(activeConversationId), (_, next) {
        _scrollToBottom();
      });
    }

    // Also scroll when isGenerating changes
    ref.listen(isGeneratingProvider, (_, next) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeConversationId != null
              ? _getTitle(conversationsAsync, activeConversationId)
              : 'AI Chat',
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Chat History',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      drawer: _buildHistoryDrawer(conversationsAsync, activeConversationId),
      body: Column(
        children: [
          // Messages area
          // Messages area
          Expanded(
            child: activeConversationId == null || messagesAsync == null
                ? EmptyChatState(onSuggestionTap: _sendMessage)
                : messagesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 40, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 12),
                          const Text('Failed to load messages'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(
                                chatMessagesProvider(activeConversationId)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return EmptyChatState(
                            onSuggestionTap: _sendMessage);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length + (isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && isGenerating) {
                            return const TypingIndicator();
                          }
                          return ChatBubble(message: messages[index]);
                        },
                      );
                    },
                  ),
          ),

          // Input bar
          ChatInputBar(
            isGenerating: isGenerating,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _getTitle(
      AsyncValue<List<ConversationModel>> conversationsAsync, String activeId) {
    final conversations = conversationsAsync.value ?? [];
    final current = conversations
        .where((c) => c.id == activeId)
        .firstOrNull;
    return current?.title ?? 'AI Chat';
  }

  Widget _buildHistoryDrawer(
      AsyncValue<List<ConversationModel>> conversationsAsync,
      String? activeConversationId) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Chat History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // New chat button
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.add, color: AppColors.primary, size: 20),
              ),
              title: const Text('New Chat'),
              onTap: () {
                _startNewChat();
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            // Conversation list
            Expanded(
              child: conversationsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Text(
                        'No conversations yet',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final convo = conversations[index];
                      final isActive = convo.id == activeConversationId;

                      return Dismissible(
                        key: ValueKey(convo.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.error.withValues(alpha: 0.1),
                          child: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: const Text(
                                  'Are you sure you want to delete this conversation?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref
                              .read(conversationListProvider.notifier)
                              .deleteConversation(convo.id);
                          if (isActive) _startNewChat();
                        },
                        child: ListTile(
                          selected: isActive,
                          selectedTileColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          leading: Icon(
                            Icons.chat_outlined,
                            size: 20,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            convo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _loadConversation(convo),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
