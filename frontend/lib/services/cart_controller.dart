import 'package:get/get.dart';
import 'cart_service.dart';

class CartController extends GetxController {
  final CartService _cartService = CartService();
  
  Rx<Cart?> cart = Rx<Cart?>(null);
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      error.value = '';
      cart.value = await _cartService.getCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await _cartService.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      
      await loadCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
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

    try {
      isLoading.value = true;
      error.value = '';
      
      await _cartService.updateCartItem(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      
      await loadCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart({
    required String productId,
    String? variantId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await _cartService.removeFromCart(
        productId: productId,
        variantId: variantId,
      );
      
      await loadCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await _cartService.clearCart();
      await loadCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    error.value = '';
  }
}