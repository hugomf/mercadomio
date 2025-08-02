import 'package:flutter/foundation.dart';
import 'cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCart() async {
    _setLoading(true);
    try {
      _cart = await _cartService.getCart();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    _setLoading(true);
    try {
      await _cartService.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error adding to cart: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateQuantity({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(
        productId: productId,
        variantId: variantId,
      );
      return;
    }

    _setLoading(true);
    try {
      await _cartService.updateCartItem(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating cart item: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromCart({
    required String productId,
    String? variantId,
  }) async {
    _setLoading(true);
    try {
      await _cartService.removeFromCart(
        productId: productId,
        variantId: variantId,
      );
      await loadCart();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error removing from cart: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearCart() async {
    _setLoading(true);
    try {
      await _cartService.clearCart();
      await loadCart();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error clearing cart: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}