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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          // Cart persistence indicator
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                authService.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                size: 20,
                color: authService.isAuthenticated
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
              ),
              onPressed: () {
                if (!authService.isAuthenticated) {
                  Get.snackbar(
                    'Sincronización de carrito',
                    'Inicia sesión para sincronizar tu carrito entre dispositivos',
                    backgroundColor: colorScheme.tertiary,
                    colorText: colorScheme.onTertiary,
                    margin: const EdgeInsets.all(20),
                    borderRadius: 8,
                  );
                }
              },
              tooltip: authService.isAuthenticated
                  ? 'Carrito sincronizado entre dispositivos'
                  : 'Carrito no sincronizado - inicia sesión',
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
                  'Error al cargar el carrito',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  cartController.error.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => cartController.loadCart(),
                  child: const Text('Reintentar'),
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
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu carrito está vacío',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Agrega productos para empezar!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  label: const Text('Seguir comprando'),
                ),
              ],
            ),
          );
        }

        if (MediaQuery.of(context).size.width >= 800) {
          return _buildDesktopLayout(cart, cartController);
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
    final colorScheme = Get.theme.colorScheme;
    final product = item.product;
    final displayName = product?.name ?? 'Producto';
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                image: displayImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(displayImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: displayImage.isEmpty
                  ? Icon(
                      Icons.shopping_bag,
                      color: colorScheme.outline,
                      size: 24,
                    )
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Variant information
                  if (variantInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Opción: ${variantInfo.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    '\$${displayPrice.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
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
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant),
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
                            color: item.quantity > 1
                                ? colorScheme.surfaceContainerLowest
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: item.quantity > 1
                                ? colorScheme.onSurface
                                : colorScheme.outline,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
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
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showRemoveItemDialog(item, cartController),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
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
    final colorScheme = Get.theme.colorScheme;
    final itemCount = cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item count and summary
          Row(
            children: [
              Text(
                '$itemCount ${itemCount == 1 ? 'artículo' : 'artículos'}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Subtotal: \$${cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '\$${cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
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
            child: const Text(
              'Finalizar Compra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                      'Próximamente',
                      'La gestión de domicilios estará disponible pronto',
                      backgroundColor: colorScheme.tertiary,
                      colorText: colorScheme.onTertiary,
                      margin: const EdgeInsets.all(20),
                      borderRadius: 8,
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('Domicilio'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to saved payment methods
                    Get.snackbar(
                      'Próximamente',
                      'La gestión de métodos de pago estará disponible pronto',
                      backgroundColor: colorScheme.tertiary,
                      colorText: colorScheme.onTertiary,
                      margin: const EdgeInsets.all(20),
                      borderRadius: 8,
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pago'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildDesktopLayout(Cart cart, CartController cartController) {
    final colorScheme = Get.theme.colorScheme;
    final itemCount =
        cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky header: breadcrumb + page title (matches Stitch desktop)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb: Inicio > Mi Carrito
                  Row(
                    children: [
                      InkWell(
                        onTap: _goToStorefront,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            'Inicio',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      Text(
                        'Mi Carrito',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title: "Mi Carrito" + count on the left, "Seguir
                  // comprando" link on the right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Carrito',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '($itemCount '
                              '${itemCount == 1 ? 'artículo' : 'artículos'})',
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _goToStorefront,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text(
                          'Seguir comprando',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDesktopCartTable(cart, cartController),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 380,
                      child: _buildDesktopSummary(cart, cartController),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCartTable(Cart cart, CartController cartController) {
    final colorScheme = Get.theme.colorScheme;

    // Column weight matching the Stitch design: Producto (6/12),
    // Cantidad (3/12), Subtotal (2/12), empty delete column (1/12).
    const productFlex = 6;
    const qtyFlex = 3;
    const subtotalFlex = 2;
    const deleteFlex = 1;

    TextStyle headerStyle() => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: colorScheme.onSurfaceVariant,
        );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column headers (only visible on desktop, matches Stitch)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: productFlex,
                  child: Text('Producto', style: headerStyle()),
                ),
                Expanded(
                  flex: qtyFlex,
                  child: Text(
                    'Cantidad',
                    textAlign: TextAlign.center,
                    style: headerStyle(),
                  ),
                ),
                Expanded(
                  flex: subtotalFlex,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: headerStyle(),
                  ),
                ),
                const Expanded(flex: deleteFlex, child: SizedBox()),
              ],
            ),
          ),
          for (final item in cart.items)
            _buildDesktopCartRow(item, cartController),
        ],
      ),
    );
  }

  Widget _buildDesktopCartRow(
      CartItem item, CartController cartController) {
    final colorScheme = Get.theme.colorScheme;
    final current = _currentUnitPrice(item);
    final original = _originalUnitPrice(item);
    final hasDiscount = current < original;

    Widget subtotal() => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${(current * item.quantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (hasDiscount)
              Text(
                '\$${(original * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: _buildDesktopProductCell(item)),
          Expanded(
            flex: 3,
            child: Center(child: _buildDesktopQuantityStepper(item, cartController)),
          ),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: subtotal())),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: colorScheme.onSurfaceVariant,
                onPressed: () => _showRemoveItemDialog(item, cartController),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProductCell(CartItem item) {
    final colorScheme = Get.theme.colorScheme;
    final product = item.product;
    final displayName = product?.name ?? 'Producto';
    final displayImage = product?.imageUrl ?? '';
    final variantInfo = item.variantId != null && product?.variants.isNotEmpty == true
        ? product!.variants.firstWhere(
            (v) => v.variantId == item.variantId,
            orElse: () => product.variants.first,
          )
        : null;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            image: displayImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(displayImage),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: displayImage.isEmpty
              ? Icon(Icons.shopping_bag, color: colorScheme.outline, size: 26)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_unitLabel(item) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    _unitLabel(item)!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (variantInfo != null && _unitLabel(item) == null) ...[
                const SizedBox(height: 3),
                Text(
                  'Opción: ${variantInfo.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              // Stock badge ("¡Últimas N!") when the variant is running low.
              if (variantInfo != null &&
                  variantInfo.isAvailable &&
                  variantInfo.stock > 0 &&
                  variantInfo.stock <= 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '¡Últimas ${variantInfo.stock}!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopQuantityStepper(CartItem item, CartController cartController) {
    final colorScheme = Get.theme.colorScheme;

    // Rounded-full pill (matches Stitch desktop): minus (left), qty, plus.
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
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
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(999)),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.quantity > 1
                    ? colorScheme.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(999)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                size: 16,
                color: item.quantity > 1
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              item.quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
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
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(999)),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(999)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 16, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummary(Cart cart, CartController cartController) {
    final colorScheme = Get.theme.colorScheme;

    // Pricing with discounts: subtotal is at original prices, total reflects
    // the resolved (effective) prices so discounts are visible in the cart.
    double originalTotal = 0;
    double effectiveTotal = 0;
    for (final item in cart.items) {
      originalTotal += _originalUnitPrice(item) * item.quantity;
      effectiveTotal += _currentUnitPrice(item) * item.quantity;
    }
    final savings = originalTotal - effectiveTotal;
    final hasDiscount = savings > 0.001;

    TextStyle rowLabel() => TextStyle(
          fontSize: 15,
          color: colorScheme.onSurfaceVariant,
        );
    TextStyle rowValue() =>
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen de compra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Subtotal / Envío / Descuentos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: rowLabel()),
              Text('\$${originalTotal.toStringAsFixed(2)}',
                  style: rowValue()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo de envío', style: rowLabel()),
              Text(
                'Envío gratis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Descuentos', style: rowLabel()),
              Text(
                hasDiscount
                    ? '-\$${savings.toStringAsFixed(2)}'
                    : '-\$0.00',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: hasDiscount ? colorScheme.error : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '\$${effectiveTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Savings alert (only when a discount really applies)
          if (hasDiscount) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '¡Ahorras ',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        children: [
                          TextSpan(
                            text: '\$${savings.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' en esta compra!'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Coupon input
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Código de cupón',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Get.snackbar(
                  'Cupón',
                  'Ingresa tu cupón en la pantalla de finalizar compra',
                  backgroundColor: colorScheme.tertiary,
                  colorText: colorScheme.onTertiary,
                  margin: const EdgeInsets.all(20),
                  borderRadius: 8,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout CTA
          ElevatedButton.icon(
            onPressed: () => _showCheckoutScreen(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.shopping_bag),
            label: const Text(
              'Finalizar Compra',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Lock note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Pago 100% seguro',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the storefront, matching the "Inicio" / "Seguir comprando" links.
  void _goToStorefront() {
    Get.offAll(() => const MainScreen());
  }

  /// Current unit price for a cart item: the effective price resolved by the
  /// pricing engine (customAttributes['effectivePrice']) when present, falling
  /// back to the product's base price.
  double _currentUnitPrice(CartItem item) {
    final effective = item.product?.customAttributes?['effectivePrice'];
    if (effective is num && effective > 0) return effective.toDouble();
    return item.product?.basePrice ?? 0.0;
  }

  /// Original (pre-discount) unit price for a cart item.
  double _originalUnitPrice(CartItem item) =>
      item.product?.basePrice ?? 0.0;

  /// Unit label (e.g. "1 kg") resolved by the pricing engine, when present.
  String? _unitLabel(CartItem item) {
    final raw = item.product?.customAttributes?['unit'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  void _showRemoveItemDialog(CartItem item, CartController cartController) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: Text(
          '¿Seguro que quieres eliminar ${item.product?.name ?? 'este artículo'} de tu carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartController cartController) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          '¿Seguro que quieres eliminar todos los artículos de tu carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cartController.clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutScreen(Cart cart) {
    Get.to(() => CheckoutScreen(cartId: cart.id));
  }
}
