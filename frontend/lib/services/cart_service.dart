import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../widgets/product_listing_widget.dart';

class CartItem {
  final String productId;
  final String? variantId;
  final int quantity;
  final Map<String, dynamic>? attributes;
  Product? product;

  CartItem({
    required this.productId,
    this.variantId,
    required this.quantity,
    this.attributes,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      variantId: json['variantId'],
      quantity: json['quantity'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'attributes': attributes,
    };
  }

  CartItem copyWith({
    String? productId,
    String? variantId,
    int? quantity,
    Map<String, dynamic>? attributes,
    Product? product,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      attributes: attributes ?? this.attributes,
      product: product ?? this.product,
    );
  }
}

class Cart {
  final String id;
  final String? userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  double get total {
    return items.fold(0.0, (sum, item) {
      if (item.product != null) {
        return sum + (item.product!.price * item.quantity);
      }
      return sum;
    });
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  String? _currentCartId;
  Cart? _currentCart;

  String get currentCartId {
    _currentCartId ??= 'guest-cart-${DateTime.now().millisecondsSinceEpoch}';
    return _currentCartId!;
  }

  Future<String> _getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://localhost:8080';
  }

  Future<Cart> getCart() async {
    final apiUrl = await _getApiUrl();
    final response = await http.get(
      Uri.parse('$apiUrl/api/cart/$currentCartId'),
    );

    if (response.statusCode == 200) {
      final cartData = json.decode(response.body);
      _currentCart = Cart.fromJson(cartData);
      
      // Enrich cart items with product details
      if (_currentCart != null) {
        await _enrichCartItemsWithProducts(_currentCart!);
      }
      
      return _currentCart!;
    } else {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
  }

  Future<void> _enrichCartItemsWithProducts(Cart cart) async {
    final apiUrl = await _getApiUrl();
    
    for (var item in cart.items) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/api/products/${item.productId}'),
        );
        
        if (response.statusCode == 200) {
          final productData = json.decode(response.body);
          item.product = Product.fromJson(productData);
        }
      } catch (e) {
        // Error loading product details for ${item.productId}: $e
      }
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
    Map<String, dynamic>? attributes,
  }) async {
    final apiUrl = await _getApiUrl();
    final response = await http.post(
      Uri.parse('$apiUrl/api/cart/$currentCartId/items'),
      body: json.encode({
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'attributes': attributes,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add to cart: ${response.statusCode}');
    }

    // Refresh cart after adding
    await getCart();
  }

  Future<void> updateCartItem({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final apiUrl = await _getApiUrl();
    final response = await http.put(
      Uri.parse('$apiUrl/api/cart/$currentCartId/items/$productId${variantId != null ? '?variantId=$variantId' : ''}'),
      body: json.encode({'quantity': quantity}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to update cart item: ${response.statusCode}');
    }

    // Refresh cart after updating
    await getCart();
  }

  Future<void> removeFromCart({
    required String productId,
    String? variantId,
  }) async {
    final apiUrl = await _getApiUrl();
    final response = await http.delete(
      Uri.parse('$apiUrl/api/cart/$currentCartId/items/$productId${variantId != null ? '?variantId=$variantId' : ''}'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to remove from cart: ${response.statusCode}');
    }

    // Refresh cart after removing
    await getCart();
  }

  Future<void> clearCart() async {
    final apiUrl = await _getApiUrl();
    final response = await http.delete(
      Uri.parse('$apiUrl/api/cart/$currentCartId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to clear cart: ${response.statusCode}');
    }

    // Refresh cart after clearing
    await getCart();
  }

  Future<void> mergeCarts(String guestCartId, String userCartId) async {
    final apiUrl = await _getApiUrl();
    final response = await http.post(
      Uri.parse('$apiUrl/api/cart/merge'),
      body: json.encode({
        'guestCartId': guestCartId,
        'userCartId': userCartId,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to merge carts: ${response.statusCode}');
    }

    // Update current cart ID to user cart
    _currentCartId = userCartId;
    await getCart();
  }

  Cart? get currentCart => _currentCart;

  void clearLocalCart() {
    _currentCart = null;
    _currentCartId = null;
  }
}