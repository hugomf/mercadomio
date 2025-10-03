import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/cart_controller.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          // Cart persistence indicator
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                authService.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                size: 20,
                color: authService.isAuthenticated ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                if (!authService.isAuthenticated) {
                  Get.snackbar(
                    'Cart Sync',
                    'Login to sync your cart across devices',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
              },
              tooltip: authService.isAuthenticated
                  ? 'Cart synced across devices'
                  : 'Cart not synced - login required',
            ),
          )),
          Obx(() {
            if (cartController.cart.value?.items.isEmpty ?? true) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(cartController),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (cartController.isLoading.value && cartController.cart.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading cart',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  cartController.error.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => cartController.loadCart(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final cart = cartController.cart.value;
        if (cart == null || cart.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add some products to get started!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to products by going to main screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Continue Shopping'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return _buildCartItem(item, cartController);
                },
              ),
            ),
            _buildCartSummary(cart, cartController),
          ],
        );
      }),
    );
  }

  Widget _buildCartItem(CartItem item, CartController cartController) {
    final product = item.product;
    final displayName = product?.name ?? 'Product';
    final displayPrice = product?.basePrice ?? 0.0;
    final displayImage = product?.imageUrl ?? '';
    final itemTotal = displayPrice * item.quantity;

    // Show variant information if available
    final variantInfo = item.variantId != null && product?.variants.isNotEmpty == true
        ? product!.variants.firstWhere(
            (v) => v.variantId == item.variantId,
            orElse: () => product.variants.first,
          )
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: displayImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(displayImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: displayImage.isEmpty
                  ? const Icon(Icons.shopping_bag, color: Colors.grey, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Variant information
                  if (variantInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Option: ${variantInfo.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    '\$${displayPrice.toStringAsFixed(2)} each',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity and Price Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1) {
                            cartController.updateQuantity(
                              productId: item.productId,
                              variantId: item.variantId,
                              quantity: item.quantity - 1,
                            );
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: item.quantity > 1 ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: item.quantity > 1 ? Colors.black54 : Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          cartController.updateQuantity(
                            productId: item.productId,
                            variantId: item.variantId,
                            quantity: item.quantity + 1,
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Item total and remove
                Row(
                  children: [
                    Text(
                      '\$${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showRemoveItemDialog(item, cartController),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(Cart cart, CartController cartController) {
    final itemCount = cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item count and summary
          Row(
            children: [
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                'Subtotal: \$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkout button
          ElevatedButton(
            onPressed: cart.items.isEmpty
                ? null
                : () => _showCheckoutScreen(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Additional options
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to saved addresses/payment methods
                    Get.snackbar(
                      'Coming Soon',
                      'Address and payment management coming next!',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('Delivery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to saved payment methods
                    Get.snackbar(
                      'Coming Soon',
                      'Payment method management coming next!',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Payment'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(CartItem item, CartController cartController) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
          'Are you sure you want to remove ${item.product?.name ?? 'this item'} from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartController.removeFromCart(
                productId: item.productId,
                variantId: item.variantId,
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartController cartController) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartController.clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutScreen(Cart cart) {
    Get.to(() => CheckoutScreen(cartId: cart.id));
  }
}
