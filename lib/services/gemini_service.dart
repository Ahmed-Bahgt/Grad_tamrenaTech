import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/api_config.dart';

class GeminiService {
  late final GenerativeModel _model;

  /// Cache for ingredient extractions to avoid quota waste
  final Map<String, String> _ingredientCache = {};

  GeminiService() {
    _model = GenerativeModel(
      model: ApiConfig.geminiModel,
      apiKey: ApiConfig.geminiApiKey,
    );
  }

  String _generateImageHash(Uint8List imageBytes) {
    return md5.convert(imageBytes).toString();
  }

  Future<String> extractIngredientsFromImage(Uint8List imageBytes) async {
    try {
      final hash = _generateImageHash(imageBytes);
      if (_ingredientCache.containsKey(hash)) {
        debugPrint('[GeminiService] ✓ Using cached ingredients for hash: $hash');
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
      final cleaned = text.replaceAll(
        RegExp(r"""^['"]+|['"]+$"""),
        '',
      ).trim();

      _ingredientCache[hash] = cleaned;
      return cleaned;
    } catch (e) {
      throw Exception('Failed to extract ingredients: $e');
    }
  }

  Future<String> extractIngredientsFromImageFile(File file) async {
    try {
      final imageBytes = await file.readAsBytes();
      final hash = _generateImageHash(imageBytes);
      if (_ingredientCache.containsKey(hash)) {
        debugPrint('[GeminiService] ✓ Using cached ingredients for file: ${file.path}');
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
      final cleaned = text.replaceAll(
        RegExp(r"""^['"]+|['"]+$"""),
        '',
      ).trim();

      _ingredientCache[hash] = cleaned;
      return cleaned;
    } catch (e) {
      throw Exception('Failed to extract ingredients: $e');
    }
  }

  ChatSession startChat(String systemContext) {
    return _model.startChat(history: [Content.text(systemContext)]);
  }

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
      if (errorMsg.contains('429') || errorMsg.contains('RESOURCE_EXHAUSTED')) {
        throw Exception('API quota exceeded: $e');
      }
      rethrow;
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }

  Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
    int attempt = 0;
    const maxRetries = 3;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final errorMsg = e.toString();
        final isQuotaError = errorMsg.contains('429') ||
            errorMsg.contains('RESOURCE_EXHAUSTED') ||
            errorMsg.contains('quota') ||
            errorMsg.contains('quota exceeded for metric');
        if (!isQuotaError || attempt >= maxRetries) {
          rethrow;
        }
        final delaySeconds = 1 << (attempt - 1);
        debugPrint('[GeminiService] ⏳ Quota exceeded. Retrying in ${delaySeconds}s (attempt $attempt/$maxRetries)...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }
}
