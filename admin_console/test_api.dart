import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  final baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.1.218:8080/api';
  
  print('Testing API connection to: $baseUrl');
  
  try {
    // Test products endpoint
    final productsResponse = await http.get(Uri.parse('$baseUrl/products'));
    print('Products endpoint status: ${productsResponse.statusCode}');
    print('Products response: ${productsResponse.body}');
    
    // Test categories endpoint
    final categoriesResponse = await http.get(Uri.parse('$baseUrl/categories'));
    print('Categories endpoint status: ${categoriesResponse.statusCode}');
    print('Categories response: ${categoriesResponse.body}');
    
    // Test health endpoint
    final healthResponse = await http.get(Uri.parse('$baseUrl/health'));
    print('Health endpoint status: ${healthResponse.statusCode}');
    print('Health response: ${healthResponse.body}');
    
  } catch (e) {
    print('Error connecting to API: $e');
  }
}