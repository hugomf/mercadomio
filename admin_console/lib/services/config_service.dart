import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:8080/api');

  static String get appEnv =>
      dotenv.get('APP_ENV', fallback: 'development');

  static bool get enableAnalytics =>
      dotenv.get('ENABLE_ANALYTICS', fallback: 'false').toLowerCase() == 'true';

  static bool get enableDebugLogging =>
      dotenv.get('ENABLE_DEBUG_LOGGING', fallback: 'true').toLowerCase() == 'true';

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';

  // Helper method to get any environment variable with fallback
  static String get(String key, {String fallback = ''}) {
    return dotenv.get(key, fallback: fallback);
  }

  // Helper method to check if a feature flag is enabled
  static bool isFeatureEnabled(String featureKey) {
    return dotenv.get(featureKey, fallback: 'false').toLowerCase() == 'true';
  }
}