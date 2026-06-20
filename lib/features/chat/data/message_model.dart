import 'package:google_generative_ai/google_generative_ai.dart' as gemini;

enum MessageRole {
  user('user'),
  assistant('assistant'),
  model('model'); // Legacy: Gemini SDK uses 'model', DB may have old records

  final String value;
  const MessageRole(this.value);

  static MessageRole fromString(String? value) {
    // Normalize: both 'model' and 'assistant' map to assistant for display
    if (value == 'model' || value == 'assistant') {
      return MessageRole.assistant;
    }
    return MessageRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageRole.user,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      role: MessageRole.fromString(json['role']),
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'conversation_id': conversationId,
      'role': role.value,
      'content': content,
    };
  }

  /// Convert to Gemini SDK Content for building chat history
  gemini.Content toGeminiContent() {
    // Gemini SDK expects 'user' or 'model' — never 'assistant'
    final geminiRole = role == MessageRole.assistant ? 'model' : role.value;
    return gemini.Content(geminiRole, [gemini.TextPart(content)]);
  }
}
