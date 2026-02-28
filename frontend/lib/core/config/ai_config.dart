import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  AiConfig._();

  static String get baseUrl => dotenv.env['AI_BASE_URL']?.trim() ?? '';
  static String get model => dotenv.env['AI_MODEL']?.trim() ?? '';
  static String get apiKey => dotenv.env['AI_API_KEY']?.trim() ?? '';
  
  static Duration get softTimeout {
    final ms = int.tryParse(dotenv.env['AI_SOFT_TIMEOUT_MS']?.trim() ?? '');
    return Duration(milliseconds: (ms != null && ms > 0) ? ms : 15000);
  }

  
}
