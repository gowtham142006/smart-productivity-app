import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Model name constant — single source of truth
const String _kModelName = 'gemini-2.5-flash';

class GeminiService {
  final String _apiKey;
  final GenerativeModel _model;

  /// Throttle: minimum gap between requests
  static const Duration _minRequestGap = Duration(seconds: 2);
  DateTime _lastRequestTime = DateTime(2000);

  /// Dedup: track in-flight requests by prompt hash
  final Set<int> _inFlightRequests = {};

  GeminiService({required String apiKey})
      : _apiKey = apiKey,
        _model = GenerativeModel(
          model: _kModelName,
          apiKey: apiKey,
        ) {
    debugPrint('[GeminiService] Initialized with model: $_kModelName');
    debugPrint('[GeminiService] API key loaded: ${apiKey.isNotEmpty ? "YES (${apiKey.length} chars)" : "MISSING"}');
  }

  /// Returns true if the request should proceed (throttle + dedup check)
  bool _acquireSlot(int requestHash) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);

    if (elapsed < _minRequestGap) {
      debugPrint('[GeminiService] ⚠️ THROTTLED — only ${elapsed.inMilliseconds}ms since last request (min: ${_minRequestGap.inMilliseconds}ms)');
      return false;
    }

    if (_inFlightRequests.contains(requestHash)) {
      debugPrint('[GeminiService] ⚠️ DUPLICATE REQUEST blocked (hash: $requestHash)');
      return false;
    }

    _lastRequestTime = now;
    _inFlightRequests.add(requestHash);
    return true;
  }

  void _releaseSlot(int requestHash) {
    _inFlightRequests.remove(requestHash);
  }

  /// Single prompt → response
  Future<String> generateContent(String prompt) async {
    final requestHash = 'generateContent:$prompt'.hashCode;

    if (!_acquireSlot(requestHash)) {
      throw Exception('Request throttled. Please wait a moment before trying again.');
    }

    try {
      debugPrint('[GeminiService] 📤 generateContent() — model: $_kModelName');
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      debugPrint('[GeminiService] ✅ Response received (${text?.length ?? 0} chars)');
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e, st) {
      debugPrint('[GeminiService] ❌ GenerativeAIException in generateContent()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Message: ${e.message}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      throw Exception(_mapError(e));
    } catch (e, st) {
      debugPrint('[GeminiService] ❌ Unexpected error in generateContent()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Error type: ${e.runtimeType}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      rethrow;
    } finally {
      _releaseSlot(requestHash);
    }
  }

  /// Multi-turn chat with history
  Future<String> sendChatMessage(
    String message,
    List<Content> history,
  ) async {
    final requestHash = 'sendChatMessage:$message'.hashCode;

    if (!_acquireSlot(requestHash)) {
      throw Exception('Request throttled. Please wait a moment before trying again.');
    }

    try {
      debugPrint('[GeminiService] 📤 sendChatMessage() — model: $_kModelName, history: ${history.length} messages');
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(message));
      final text = response.text;
      debugPrint('[GeminiService] ✅ Chat response received (${text?.length ?? 0} chars)');
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e, st) {
      debugPrint('[GeminiService] ❌ GenerativeAIException in sendChatMessage()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Message: ${e.message}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      throw Exception(_mapError(e));
    } catch (e, st) {
      debugPrint('[GeminiService] ❌ Unexpected error in sendChatMessage()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Error type: ${e.runtimeType}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      rethrow;
    } finally {
      _releaseSlot(requestHash);
    }
  }

  /// Structured productivity prompt with system instruction
  Future<String> generateProductivityContent({
    required String systemInstruction,
    required String userPrompt,
  }) async {
    final requestHash = 'productivity:$userPrompt'.hashCode;

    if (!_acquireSlot(requestHash)) {
      throw Exception('Request throttled. Please wait a moment before trying again.');
    }

    try {
      debugPrint('[GeminiService] 📤 generateProductivityContent() — model: $_kModelName');
      final model = GenerativeModel(
        model: _kModelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(systemInstruction),
      );
      final response =
          await model.generateContent([Content.text(userPrompt)]);
      final text = response.text;
      debugPrint('[GeminiService] ✅ Productivity response received (${text?.length ?? 0} chars)');
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e, st) {
      debugPrint('[GeminiService] ❌ GenerativeAIException in generateProductivityContent()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Message: ${e.message}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      throw Exception(_mapError(e));
    } catch (e, st) {
      debugPrint('[GeminiService] ❌ Unexpected error in generateProductivityContent()');
      debugPrint('[GeminiService]    Model: $_kModelName');
      debugPrint('[GeminiService]    Error type: ${e.runtimeType}');
      debugPrint('[GeminiService]    Full exception: $e');
      debugPrint('[GeminiService]    Stack trace: $st');
      rethrow;
    } finally {
      _releaseSlot(requestHash);
    }
  }

  /// Map API errors to user-friendly messages
  String _mapError(GenerativeAIException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('api key') || msg.contains('api_key')) {
      return 'Invalid API key. Please check your Gemini API key in .env';
    }
    if (msg.contains('quota') || msg.contains('rate')) {
      return 'API rate limit reached. Please try again in a moment.';
    }
    if (msg.contains('safety')) {
      return 'The response was blocked by safety filters. Try rephrasing.';
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return 'Model "$_kModelName" not found. Check the model name.';
    }
    return 'AI service error: ${e.message}';
  }
}
