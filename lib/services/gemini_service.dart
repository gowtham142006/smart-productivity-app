import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String _apiKey;
  final GenerativeModel _model;

  GeminiService({required String apiKey})
      : _apiKey = apiKey,
        _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );

  /// Single prompt → response
  Future<String> generateContent(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API error: $e');
      throw Exception(_mapError(e));
    } catch (e) {
      debugPrint('Gemini error: $e');
      rethrow;
    }
  }

  /// Multi-turn chat with history
  Future<String> sendChatMessage(
    String message,
    List<Content> history,
  ) async {
    try {
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(message));
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini chat error: $e');
      throw Exception(_mapError(e));
    } catch (e) {
      debugPrint('Gemini chat error: $e');
      rethrow;
    }
  }

  /// Structured productivity prompt with system instruction
  Future<String> generateProductivityContent({
    required String systemInstruction,
    required String userPrompt,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(systemInstruction),
      );
      final response =
          await model.generateContent([Content.text(userPrompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini productivity error: $e');
      throw Exception(_mapError(e));
    } catch (e) {
      debugPrint('Gemini productivity error: $e');
      rethrow;
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
    return 'AI service error: ${e.message}';
  }
}
