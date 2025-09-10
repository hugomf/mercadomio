import 'dart:convert';
import 'dart:io';

String readEnvFile(String fileName) {
  final file = File(fileName);
  if (!file.existsSync()) {
    return 'http://192.168.1.218:8080/api';
  }
  
  final lines = file.readAsLinesSync();
  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2 && parts[0].trim() == 'BACKEND_URL') {
      return parts[1].trim();
    }
  }
  
  return 'http://192.168.1.218:8080/api';
}

void main() async {
  final baseUrl = readEnvFile('.env');
  
  print('Testing API connection to: $baseUrl');
  
  try {
    // Test products endpoint
    final productsResponse = await HttpClient().getUrl(Uri.parse('$baseUrl/products'));
    final productsResult = await productsResponse.close();
    final productsBody = await utf8.decodeStream(productsResult);
    print('Products endpoint status: ${productsResult.statusCode}');
    print('Products response: $productsBody');
    
    // Test categories endpoint
    final categoriesResponse = await HttpClient().getUrl(Uri.parse('$baseUrl/categories'));
    final categoriesResult = await categoriesResponse.close();
    final categoriesBody = await utf8.decodeStream(categoriesResult);
    print('Categories endpoint status: ${categoriesResult.statusCode}');
    print('Categories response: $categoriesBody');
    
    // Test health endpoint
    final healthResponse = await HttpClient().getUrl(Uri.parse('$baseUrl/health'));
    final healthResult = await healthResponse.close();
    final healthBody = await utf8.decodeStream(healthResult);
    print('Health endpoint status: ${healthResult.statusCode}');
    print('Health response: $healthBody');
    
  } catch (e) {
    print('Error connecting to API: $e');
  }
}