import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService extends GetxService {
  Future<String> getApiUrl() async {
    try {
      await dotenv.load(fileName: '.env');
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      return apiUrl;
    } catch (e) {
      return 'http://localhost:8080';
    }
  }
}