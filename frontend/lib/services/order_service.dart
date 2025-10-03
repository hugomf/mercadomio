import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

// Order Service - Professional API client for order management
class OrderService {
  final String baseUrl;
  final String? authToken;

  OrderService({
    required this.baseUrl,
    this.authToken,
  });

  // Headers with authentication
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // Create order from cart
  Future<OrderResponse> createOrderFromCart(String cartId, {Map<String, dynamic>? paymentInfo}) async {
    final request = OrderCreateRequest(
      cartId: cartId,
      paymentInfo: paymentInfo,
    );

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body)['data'];
      return OrderResponse.fromJson(data);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'Failed to create order');
    } else {
      throw Exception('Failed to create order: ${response.statusCode}');
    }
  }

  // Get user's order history with pagination
  Future<OrderHistoryResponse> getOrderHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/orders').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] ?? jsonDecode(response.body);
      return OrderHistoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load order history: ${response.statusCode}');
    }
  }

  // Get specific order details
  Future<OrderResponse> getOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return OrderResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Order not found');
    } else if (response.statusCode == 403) {
      throw Exception('Access denied');
    } else {
      throw Exception('Failed to load order: ${response.statusCode}');
    }
  }

  // Update order status (admin functionality)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final requestBody = {
      'status': newStatus.englishValue,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'Failed to update order status');
    }
  }

  // Add payment information
  Future<void> addPaymentInfo(String orderId, Map<String, dynamic> paymentInfo) async {
    final requestBody = {
      'paymentInfo': paymentInfo,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/payment'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'Failed to add payment info');
    }
  }

  // Get order statistics (admin functionality)
  Future<Map<String, dynamic>> getOrderStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/admin/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  }

  // Simulated order completion for demo purposes (would normally come from payment gateway)
  Future<OrderResponse> simulateOrderCompletion(String orderId) async {
    // In a real app, this would integrate with payment providers
    final paymentInfo = {
      'provider': 'Stripe',
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': 0, // Would be populated from order
      'status': 'completed',
      'processedAt': DateTime.now().toIso8601String(),
    };

    await addPaymentInfo(orderId, paymentInfo);

    // Refresh order to get updated status
    return await getOrder(orderId);
  }

  // Mock checkout integration - in real app would integrate with payment processor
  Future<String> initiateCheckout(String cartId, {required String successUrl, required String cancelUrl}) async {
    // In a real implementation, this would:
    // 1. Create checkout session with payment provider (Stripe, PayPal, etc.)
    // 2. Return checkout URL for user redirection
    // 3. Handle callback/webhooks for payment completion

    // For demo purposes, simulate immediate success
    final order = await createOrderFromCart(cartId);
    return '$successUrl?order_id=${order.id}';
  }
}

// Extension for convenience methods
extension OrderResponseExtension on OrderResponse {
  // Get main tracking number (would come from shipping providers)
  String? get trackingNumber {
    return paymentInfo?['trackingNumber'];
  }

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == OrderStatus.pending;
  }

  // Check if order can be returned
  bool get canBeReturned {
    // Usually within 30 days of completion
    if (status == OrderStatus.completed) {
      final daysSinceCompletion = DateTime.now().difference(updatedAt).inDays;
      return daysSinceCompletion <= 30;
    }
    return false;
  }

  // Order progress percentage for UI display
  double get progressPercentage {
    switch (status) {
      case OrderStatus.pending:
        return 0.25;
      case OrderStatus.paid:
        return 0.50;
      case OrderStatus.shipped:
        return 0.75;
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }

  // Estimated delivery date (would integrate with shipping provider)
  String get estimatedDelivery {
    if (status == OrderStatus.shipped) {
      // Mock: 3-5 business days after shipping
      final estimatedDate = updatedAt.add(const Duration(days: 4));
      return '${estimatedDate.day}/${estimatedDate.month}/${estimatedDate.year}';
    }
    return 'Para calcularse después del envío';
  }
}
