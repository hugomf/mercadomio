import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pricing.dart';

// Admin pricing service - manages price schedules and price sets.
class AdminPricingService {
  final String baseUrl;
  final String? authToken;

  AdminPricingService({
    this.baseUrl = 'http://localhost:8080',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // GET /api/pricing/price-sets?page&limit
  Future<List<PriceSet>> listPriceSets({int page = 1, int limit = 100}) async {
    final uri = Uri.parse('$baseUrl/api/pricing/price-sets')
        .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response, 'Failed to load price sets');
    final data = jsonDecode(response.body)['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is List) {
      return items
          .map((e) => PriceSet.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  // POST /api/pricing/price-sets
  Future<PriceSet> createPriceSet(PriceSet set) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pricing/price-sets'),
      headers: _headers,
      body: jsonEncode(set.toJson()),
    );
    _checkStatus(response, 'Failed to create price set');
    return PriceSet.fromJson(jsonDecode(response.body)['data']);
  }

  // PUT /api/pricing/price-sets/:id
  Future<void> updatePriceSet(String id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/pricing/price-sets/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    _checkStatus(response, 'Failed to update price set');
  }

  // DELETE /api/pricing/price-sets/:id
  Future<void> deletePriceSet(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/pricing/price-sets/$id'),
      headers: _headers,
    );
    _checkStatus(response, 'Failed to delete price set');
  }

  // GET /api/pricing/price-schedules?page&limit
  Future<List<PriceSchedule>> listPriceSchedules(
      {int page = 1, int limit = 100}) async {
    final uri = Uri.parse('$baseUrl/api/pricing/price-schedules')
        .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response, 'Failed to load price schedules');
    final data = jsonDecode(response.body)['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is List) {
      return items
          .map((e) => PriceSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  // POST /api/pricing/price-schedules
  Future<PriceSchedule> createPriceSchedule(PriceSchedule schedule) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pricing/price-schedules'),
      headers: _headers,
      body: jsonEncode(schedule.toJson()),
    );
    _checkStatus(response, 'Failed to create price schedule');
    return PriceSchedule.fromJson(jsonDecode(response.body)['data']);
  }

  // PUT /api/pricing/price-schedules/:id
  Future<void> updatePriceSchedule(
      String id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/pricing/price-schedules/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    _checkStatus(response, 'Failed to update price schedule');
  }

  // DELETE /api/pricing/price-schedules/:id
  Future<void> deletePriceSchedule(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/pricing/price-schedules/$id'),
      headers: _headers,
    );
    _checkStatus(response, 'Failed to delete price schedule');
  }

  // GET /api/pricing/price-history?productId&limit
  Future<List<PriceHistoryEntry>> listPriceHistory(
      {String productId = '', int limit = 50}) async {
    final query = {
      'limit': '$limit',
      if (productId.isNotEmpty) 'productId': productId,
    };
    final uri = Uri.parse('$baseUrl/api/pricing/price-history')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response, 'Failed to load price history');
    final data = jsonDecode(response.body)['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is List) {
      return items
          .map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  void _checkStatus(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(_errorMessage(response, fallback));
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