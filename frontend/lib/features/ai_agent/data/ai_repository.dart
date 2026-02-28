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
}