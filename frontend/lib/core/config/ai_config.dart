import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  AiConfig._();

  static String get baseUrl => dotenv.env['AI_BASE_URL']?.trim() ?? '';
  static String get model => dotenv.env['AI_MODEL']?.trim() ?? '';
  static String get apiKey => dotenv.env['AI_API_KEY']?.trim() ?? '';
  static String get httpReferer => dotenv.env['AI_HTTP_REFERER']?.trim() ?? '';
  static String get appName => dotenv.env['AI_APP_NAME']?.trim() ?? 'FlashGenius';
  
  static Duration get softTimeout {
    final ms = int.tryParse(dotenv.env['AI_SOFT_TIMEOUT_MS']?.trim() ?? '');
    return Duration(milliseconds: (ms != null && ms > 0) ? ms : 15000);
  }

  static int get maxOutputTokens {
    final v = int.tryParse(dotenv.env['AI_MAX_OUTPUT_TOKENS']?.trim() ?? '');
    return (v != null && v > 0) ? v : 2000;
  }
}
