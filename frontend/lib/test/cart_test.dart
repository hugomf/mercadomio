import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CartTest {
  static const String baseUrl = 'http://localhost:8080';
  static const String cartId = 'test-cart-001';

  static Future<void> runTests() async {
    try {
      await testAddToCart();
      await testGetCart();
      await testUpdateQuantity();
      await testRemoveFromCart();
      await testClearCart();
    } catch (e) {
      throw Exception('Test failed: $e');
    }
  }

  static Future<void> testAddToCart() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/$cartId/items'),
      body: json.encode({
        'productId': 'product-123',
        'quantity': 2,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 201) {
      throw Exception('Add to cart failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> testGetCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart/$cartId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Get cart failed: ${response.statusCode} - ${response.body}');
    }

    json.decode(response.body);
  }

  static Future<void> testUpdateQuantity() async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/cart/$cartId/items/product-123'),
      body: json.encode({'quantity': 5}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Update quantity failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> testRemoveFromCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/$cartId/items/product-123'),
    );

    if (response.statusCode != 204) {
      throw Exception('Remove from cart failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> testClearCart() async {
    // First add an item
    await http.post(
      Uri.parse('$baseUrl/api/cart/$cartId/items'),
      body: json.encode({
        'productId': 'product-456',
        'quantity': 1,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    // Then clear it
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/$cartId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Clear cart failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> testMergeCarts() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/merge'),
      body: json.encode({
        'guestCartId': 'guest-cart-001',
        'userCartId': 'user-cart-001',
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Merge carts failed: ${response.statusCode} - ${response.body}');
    }
  }
}

void main() async {
  stdin.readLineSync();
  await CartTest.runTests();
}