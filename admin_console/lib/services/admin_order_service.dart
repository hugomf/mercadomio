import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

// Admin order service - talks to the backend admin order endpoints
class AdminOrderService {
  final String baseUrl;
  final String? authToken;

  AdminOrderService({
    this.baseUrl = 'http://localhost:8080',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // GET /api/orders/admin?page&limit&status
  Future<AdminOrdersPage> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri = Uri.parse('$baseUrl/api/orders/admin')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return AdminOrdersPage.fromJson(data);
    }
    throw Exception(_errorMessage(response, 'Failed to load orders'));
  }

  // GET /api/orders/admin/stats -> { pending, paid, shipped, completed, cancelled }
  Future<Map<String, int>> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/admin/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      if (data is Map<String, dynamic>) {
        return data.map(
          (key, value) => MapEntry(key, value is num ? value.toInt() : 0),
        );
      }
      return {};
    }
    throw Exception(_errorMessage(response, 'Failed to load statistics'));
  }

  // PUT /api/orders/:id/status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status.englishValue}),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update order status'));
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
