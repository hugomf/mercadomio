import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CartTest {
  static const String baseUrl = 'http://localhost:8080';
  static const String cartId = 'test-cart-001';

  static Future<void> runTests() async {
    print('🧪 Starting Cart Functionality Tests...\n');
    
    try {
      await testAddToCart();
      await testGetCart();
      await testUpdateQuantity();
      await testRemoveFromCart();
      await testClearCart();
      
      print('✅ All cart tests passed!');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  static Future<void> testAddToCart() async {
    print('Testing: Add to cart...');
    
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
    print('✅ Add to cart test passed');
  }

  static Future<void> testGetCart() async {
    print('Testing: Get cart...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart/$cartId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Get cart failed: ${response.statusCode} - ${response.body}');
    }

    final cart = json.decode(response.body);
    print('✅ Get cart test passed');
    print('   Cart items: ${cart['items']?.length ?? 0}');
  }

  static Future<void> testUpdateQuantity() async {
    print('Testing: Update quantity...');
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/cart/$cartId/items/product-123'),
      body: json.encode({'quantity': 5}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Update quantity failed: ${response.statusCode} - ${response.body}');
    }
    print('✅ Update quantity test passed');
  }

  static Future<void> testRemoveFromCart() async {
    print('Testing: Remove from cart...');
    
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/$cartId/items/product-123'),
    );

    if (response.statusCode != 204) {
      throw Exception('Remove from cart failed: ${response.statusCode} - ${response.body}');
    }
    print('✅ Remove from cart test passed');
  }

  static Future<void> testClearCart() async {
    print('Testing: Clear cart...');
    
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
    print('✅ Clear cart test passed');
  }

  static Future<void> testMergeCarts() async {
    print('Testing: Merge carts...');
    
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
    print('✅ Merge carts test passed');
  }
}

void main() async {
  print('Make sure your backend server is running on http://localhost:8080');
  print('Press Enter to continue...');
  stdin.readLineSync();
  
  await CartTest.runTests();
}