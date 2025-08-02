import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService extends GetxService {
  Future<String> getApiUrl() async {
    try {
      await dotenv.load(fileName: '.env');
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      print('Using API URL: $apiUrl');
      return apiUrl;
    } catch (e) {
      print('Error loading .env file: $e');
      return 'http://localhost:8080';
    }
  }
}