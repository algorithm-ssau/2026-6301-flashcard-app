import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/ai_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';

class AiRepository {
  AiRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AiConfig.baseUrl,
            connectTimeout: AiConfig.softTimeout,
            receiveTimeout: AiConfig.softTimeout,
            headers: {
              'Authorization': 'Bearer ${AiConfig.apiKey}',
              'Content-Type': 'application/json',
              if (AiConfig.httpReferer.isNotEmpty) 'HTTP-Referer': AiConfig.httpReferer,
              if (AiConfig.appName.isNotEmpty) 'X-Title': AiConfig.appName,
            },
          ),
        );

  final Dio _dio;

  bool get isConfigured =>
      AiConfig.baseUrl.isNotEmpty && AiConfig.model.isNotEmpty && AiConfig.apiKey.isNotEmpty;

  Future<List<Map<String, String>>> generateCards({
    required String topic,
    required int count,
    required String language,
    required String difficulty,
  }) async {
    if (!isConfigured) {
      throw ApiException(message: 'AI is not configured');
    }

    final cappedCount = count.clamp(AppConstants.minAiCards, AppConstants.maxAiCards);
    final prompt = '''
Ты — помощник по созданию обучающих флеш-карточек в стиле Anki.
Нужно сгенерировать $cappedCount карточек по теме "$topic" на языке "$language" с уровнем сложности "$difficulty".

Формат ответа — строго JSON-массив без лишнего текста:
[
  {"question": "...", "answer": "..."},
  ...
]
''';

    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': AiConfig.model,
        'max_tokens': AiConfig.maxOutputTokens,
        'temperature': 0.7,
        'messages': [
          {
            'role': 'system',
            'content': 'Ты создаёшь карточки вопрос-ответ для приложения флеш-карточек.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      },
    );

    final data = response.data;
    if (data == null) throw ApiException(message: 'Empty AI response');
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw ApiException(message: 'Invalid AI response');
    }
    final content = choices.first['message']?['content'] as String? ?? '';
    if (content.isEmpty) {
      throw ApiException(message: 'Empty AI content');
    }

    return _parseCardsFromContent(content);
  }
  Future<List<Map<String, String>>> generateFromPdf({
    required File file,
    required int count,
    String language = 'ru',
  }) async {
    if (!isConfigured) {
      throw ApiException(message: 'AI is not configured');
    }

    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final cappedCount = count.clamp(AppConstants.minAiCards, AppConstants.maxAiCards);

    final prompt = '''
	У тебя есть PDF-документ, закодированный в base64.
Сконцентрируйся на ключевых понятиях и фактах и создай $cappedCount обучающих флеш-карточек (вопрос-ответ) на "$language".

Ответь строго JSON-массивом:
[
  {"question": "...", "answer": "..."},
  ...
]

Вот файл в base64:
$base64
''';

    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': AiConfig.model,
        'max_tokens': AiConfig.maxOutputTokens,
        'temperature': 0.4,
        'messages': [
          {
            'role': 'system',
            'content': 'Ты вытаскиваешь главное из документов и превращаешь в карточки.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      },
    );

    final data = response.data;
    if (data == null) throw ApiException(message: 'Empty AI response');
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw ApiException(message: 'Invalid AI response');
    }
    final content = choices.first['message']?['content'] as String? ?? '';
    if (content.isEmpty) {
      throw ApiException(message: 'Empty AI content');
    }

    return _parseCardsFromContent(content);
  }

  List<Map<String, String>> _parseCardsFromContent(String content) {
    try {
      final jsonText = _extractJson(content);
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) {
        throw ApiException(message: 'AI JSON is not a list');
      }
      final result = <Map<String, String>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final question = '${item['question'] ?? ''}'.trim();
          final answer = '${item['answer'] ?? ''}'.trim();
          if (question.isNotEmpty && answer.isNotEmpty) {
            result.add({'question': question, 'answer': answer});
          }
        }
      }
      return result;
    } catch (_) {
      throw ApiException(message: 'Failed to parse AI response');
    }
  }

  String _extractJson(String content) {
    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) {
      return content;
    }
    return content.substring(start, end + 1);
  }
}