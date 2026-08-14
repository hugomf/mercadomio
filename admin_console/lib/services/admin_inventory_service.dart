import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

// Admin inventory service - lists products and updates variant stock.
class AdminInventoryService {
  final String baseUrl;
  final String? authToken;

  AdminInventoryService({
    this.baseUrl = 'http://localhost:8080',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // GET /api/products?page&limit&sort&order
  Future<ProductsPage> getProducts({
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': 'name',
      'order': 'asc',
    };
    final uri = Uri.parse('$baseUrl/api/products')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return ProductsPage.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response, 'Failed to load products'));
  }

  // PUT /api/products/:id/variants/:variantId/stock
  Future<void> updateStock(String productId, String variantId, int stock) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/products/$productId/variants/$variantId/stock'),
      headers: _headers,
      body: jsonEncode({'stock': stock}),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update stock'));
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final error = jsonDecode(response.body)['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'];
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}