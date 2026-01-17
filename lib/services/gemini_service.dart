import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBubcGb7E8yRO4_hp9uzR8FwPRB_A0pUf4';
  late final GenerativeModel _model;

  // Cache for ingredient extractions to avoid quota waste
  final Map<String, String> _ingredientCache = {};

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Generate cache key from image bytes
  String _generateImageHash(Uint8List imageBytes) {
    return md5.convert(imageBytes).toString();
  }

  /// Extract ingredients from food image using Gemini Vision
  /// Returns: comma-separated list with quantities (e.g., "1 cup rice, 100g chicken breast")
  /// Uses caching to avoid quota waste on identical images
  Future<String> extractIngredientsFromImage(Uint8List imageBytes) async {
    try {
      // Check cache first
      final hash = _generateImageHash(imageBytes);
      if (_ingredientCache.containsKey(hash)) {
        debugPrint(
            '[GeminiService] ✓ Using cached ingredients for hash: $hash');
        return _ingredientCache[hash]!;
      }

      const prompt =
          '''You are a precise food-analysis assistant. Inspect the image and return a single-line, 
comma-separated list of ingredients **with approximate quantities suitable for Edamam Nutrition API**. 
Example output: '1 cup rice, 100g chicken breast, 1 tbsp olive oil'. 
Return ONLY the ingredient list.''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _retryWithBackoff(() async {
        return await _model.generateContent([content]);
      });

      final text = response.text?.trim() ?? '';
      final cleaned = text.replaceAll(RegExp("^[\"']+|[\"']+\$"), '').trim();

      // Cache the result
      _ingredientCache[hash] = cleaned;

      return cleaned;
    } catch (e) {
      throw Exception('Failed to extract ingredients: $e');
    }
  }

  /// Extract ingredients from image File with MIME detection
  /// Uses caching to avoid quota waste on identical images
  Future<String> extractIngredientsFromImageFile(File file) async {
    try {
      final imageBytes = await file.readAsBytes();

      // Check cache first
      final hash = _generateImageHash(imageBytes);
      if (_ingredientCache.containsKey(hash)) {
        debugPrint(
            '[GeminiService] ✓ Using cached ingredients for file: ${file.path}');
        return _ingredientCache[hash]!;
      }

      final path = file.path.toLowerCase();
      final mime = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      const prompt =
          '''You are a precise food-analysis assistant. Inspect the image and return a single-line, 
comma-separated list of ingredients **with approximate quantities suitable for Edamam Nutrition API**. 
Example output: '1 cup rice, 100g chicken breast, 1 tbsp olive oil'. 
Return ONLY the ingredient list.''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart(mime, imageBytes),
      ]);

      final response = await _retryWithBackoff(() async {
        return await _model.generateContent([content]);
      });

      final text = response.text?.trim() ?? '';
      final cleaned = text.replaceAll(RegExp("^[\"']+|[\"']+\$"), '').trim();

      // Cache the result
      _ingredientCache[hash] = cleaned;

      return cleaned;
    } catch (e) {
      throw Exception('Failed to extract ingredients: $e');
    }
  }

  /// Start a chat session with context
  ChatSession startChat(String systemContext) {
    return _model.startChat(
      history: [
        Content.text(systemContext),
      ],
    );
  }

  /// Send a message in an existing chat session
  Future<String> sendChatMessage(ChatSession chat, String message) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await chat.sendMessage(Content.text(message));
      });

      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return text;
    } on Exception catch (e) {
      final errorMsg = e.toString();
      // Re-throw with more context
      if (errorMsg.contains('429') || errorMsg.contains('RESOURCE_EXHAUSTED')) {
        throw Exception('API quota exceeded: $e');
      }
      rethrow;
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }

  /// Retry logic with exponential backoff for rate-limited requests
  /// Max 3 retries: waits 1s, 2s, 4s between attempts
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
    int attempt = 0;
    const maxRetries = 3;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final errorMsg = e.toString();

        // Check if it's a quota/rate limit error
        final isQuotaError = errorMsg.contains('429') ||
            errorMsg.contains('RESOURCE_EXHAUSTED') ||
            errorMsg.contains('quota') ||
            errorMsg.contains('quota exceeded for metric');

        if (!isQuotaError || attempt >= maxRetries) {
          rethrow; // Not a quota error or max retries exceeded
        }

        // Exponential backoff: 1s, 2s, 4s
        final delaySeconds = 1 << (attempt - 1); // 2^(attempt-1)
        debugPrint(
            '[GeminiService] ⏳ Quota exceeded. Retrying in ${delaySeconds}s (attempt $attempt/$maxRetries)...');

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }
}
