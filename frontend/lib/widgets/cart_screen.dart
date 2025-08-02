import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/cart_controller.dart';
import '../services/cart_service.dart';
import '../main.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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
                  ? const Icon(Icons.shopping_bag, color: Colors.grey)
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
                  const SizedBox(height: 4),
                  Text(
                    '\$${displayPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 1) {
                      cartController.updateQuantity(
                        productId: item.productId,
                        variantId: item.variantId,
                        quantity: item.quantity - 1,
                      );
                    }
                  },
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    cartController.updateQuantity(
                      productId: item.productId,
                      variantId: item.variantId,
                      quantity: item.quantity + 1,
                    );
                  },
                ),
              ],
            ),
            
            // Item Total
            Text(
              '\$${itemTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showRemoveItemDialog(item, cartController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(Cart cart, CartController cartController) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cart.items.isEmpty
                ? null
                : () => _showCheckoutDialog(cart),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 18),
            ),
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

  void _showCheckoutDialog(Cart cart) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: \$${cart.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Checkout functionality will be implemented in the next phase.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}