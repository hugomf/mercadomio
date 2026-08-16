import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/cart_controller.dart';
import '../services/order_service.dart';
import '../services/config_service.dart';
import '../services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String cartId;

  const CheckoutScreen({super.key, required this.cartId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Shipping Address Fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'Mexico');

  // Coupon code
  final _couponController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showCouponField = false;
  int _selectedPayment = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user data if available
    final authService = Get.find<AuthService>();
    if (authService.currentUser != null) {
      final user = authService.currentUser!;
      _fullNameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  Future<void> _processOrder() async {
    final colorScheme = Get.theme.colorScheme;

    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      Get.snackbar(
        'Obligatorio',
        'Debes aceptar los términos y condiciones',
        backgroundColor: colorScheme.error,
        colorText: colorScheme.onError,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final configService = Get.find<ConfigService>();
      final apiUrl = await configService.getApiUrl();
      final authService = Get.find<AuthService>();

      final orderService = OrderService(
        baseUrl: apiUrl,
        authToken: authService.token,
      );

      // Shipping address data
      final shippingAddress = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'addressLine1': _addressLine1Controller.text,
        'addressLine2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'country': _countryController.text,
      };

      // Create order from cart (no card data collected client-side)
      final orderResponse = await orderService.createOrderFromCart(
        widget.cartId,
        paymentInfo: {'shippingAddress': shippingAddress},
        couponCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
      );

      // Create a Conekta hosted checkout session
      final checkout = await orderService.createCheckoutSession(orderResponse.id);

      if (checkout.demo) {
        // No gateway keys configured: keep the simulated offline flow
        final updatedOrder = await orderService.simulateOrderCompletion(orderResponse.id);
        Get.offAll(() => OrderConfirmationScreen(order: updatedOrder));
      } else {
        // Redirect to Conekta's secure hosted payment page
        final uri = Uri.parse(checkout.checkoutUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          Get.snackbar(
            'Pago pendiente',
            'No se pudo abrir la página de pago. Tu pedido #${orderResponse.id} queda pendiente de pago.',
            backgroundColor: colorScheme.tertiary,
            colorText: colorScheme.onTertiary,
            margin: const EdgeInsets.all(20),
            borderRadius: 8,
          );
        } else {
          Get.offAllNamed('/');
        }
      }

    } catch (e) {
      Get.snackbar(
        'Error al finalizar la compra',
        e.toString(),
        backgroundColor: colorScheme.error,
        colorText: colorScheme.onError,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Pago'),
      ),
      body: Obx(() {
        final cartController = Get.find<CartController>();
        final cart = cartController.cart.value;

        if (cart == null) {
          return Center(
            child: Text(
              'Carrito no encontrado',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        if (MediaQuery.of(context).size.width >= 800) {
          return Form(
            key: _formKey,
            child: _buildDesktopLayout(cart),
          );
        }

        return Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary
                      _buildOrderSummary(cart),

                      const SizedBox(height: 24),

                      // Shipping Information
                      _buildShippingSection(),

                      const SizedBox(height: 24),

                      // Coupon Code
                      _buildCouponSection(),

                      const SizedBox(height: 24),

                      // Payment Information
                      _buildPaymentSection(),

                      const SizedBox(height: 24),

                      // Terms and Conditions
                      _buildTermsSection(),
                    ],
                  ),
                ),
              ),

              // Checkout Button
              _buildCheckoutButton(cart),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopLayout(Cart cart) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount =
        cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Transactional header (brand + payment trust, Stitch style).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_basket,
                          color: colorScheme.primary, size: 26),
                      const SizedBox(width: 4),
                      Text(
                        'Mercadomio',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16, color: colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        'Pago Seguro',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb.
                    Row(
                      children: [
                        Text(
                          'Inicio',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16, color: colorScheme.onSurfaceVariant),
                        Text(
                          'Carrito',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16, color: colorScheme.onSurfaceVariant),
                        Text(
                          'Finalizar Compra',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finalizar Compra',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'producto' : 'productos'} en tu carrito',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDesktopDeliverySection(),
                              const SizedBox(height: 20),
                              _buildDesktopPaymentSection(),
                              const SizedBox(height: 20),
                              _buildDesktopTermsCard(),
                              const SizedBox(height: 20),
                              _buildDesktopSecurityBadge(colorScheme),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: 400,
                          child: _buildDesktopCheckoutButton(cart),
                        ),
                      ],
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

  Widget _buildDesktopDeliverySection() {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildDesktopSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Entrega a domicilio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShippingFields(),
        ],
      ),
    );
  }

  Widget _buildDesktopPaymentSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildDesktopSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Método de pago',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDesktopPaymentOptions(),
          const SizedBox(height: 24),
          Text(
            'Notas adicionales (opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Ej. Tocar el timbre dos veces, dejar con el portero...',
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
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
        ],
      ),
    );
  }

  Widget _buildDesktopSecurityBadge(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Pago 100% seguro y encriptado',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSectionCard({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildDesktopOrderItems(Cart cart) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final item in cart.items) ...[
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      image: item.product?.imageUrl.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(item.product!.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.product?.imageUrl.isEmpty == true
                        ? Icon(Icons.shopping_bag,
                            size: 24, color: colorScheme.outline)
                        : null,
                  ),
                  // Quantity badge.
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product?.name ?? 'Producto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_currentUnitPrice(item).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDesktopPaymentOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    const options = [
      (Icons.payments, 'Tarjeta de Crédito/Débito', 'Termina en •••• 4242'),
      (Icons.money, 'Efectivo al recibir', null),
      (Icons.storefront, 'OXXO Pay', null),
    ];
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          InkWell(
            onTap: () => setState(() => _selectedPayment = i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: i == _selectedPayment
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == _selectedPayment
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    options[i].$1,
                    color: i == _selectedPayment
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          options[i].$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (options[i].$3 != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            options[i].$3!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    i == _selectedPayment
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i == _selectedPayment
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (i != options.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDesktopTermsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: CheckboxListTile(
        value: _acceptTerms,
        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
        title: const Text('Acepto los términos y condiciones'),
        subtitle: const Text('Consulta los términos de servicio y la política de privacidad'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildDesktopCheckoutButton(Cart cart) {
    final colorScheme = Theme.of(context).colorScheme;

    // Pricing shown from the product catalog enrichment (same as the cart).
    double originalTotal = 0;
    double effectiveTotal = 0;
    for (final item in cart.items) {
      final qty = item.quantity;
      originalTotal += _originalUnitPrice(item) * qty;
      effectiveTotal += _currentUnitPrice(item) * qty;
    }
    final savings = originalTotal - effectiveTotal;
    final hasDiscount = savings > 0.001;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen de tu pedido',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          _buildDesktopOrderItems(cart),
          // Coupon toggle.
          InkWell(
            onTap: () => setState(() => _showCouponField = !_showCouponField),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    _showCouponField
                        ? 'Ocultar cupón'
                        : 'Agregar cupón de descuento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCouponField) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _couponController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Código de cupón',
                prefixIcon: const Icon(Icons.local_offer_outlined),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${originalTotal.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Descuento',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                hasDiscount ? '-\$${savings.toStringAsFixed(2)}' : '\$0.00',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasDiscount
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Envío',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Gratis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '\$${effectiveTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 1,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(
              _isLoading ? 'Procesando...' : 'Confirmar pedido',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.undo, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Regresa fácilmente si necesitas cambiar algo',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _currentUnitPrice(CartItem item) {
    final attrs = item.product?.customAttributes;
    final raw = attrs?['effectivePrice'];
    if (raw is num && raw > 0) return raw.toDouble();
    return item.product?.basePrice ?? 0.0;
  }

  double _originalUnitPrice(CartItem item) {
    return item.product?.basePrice ?? 0.0;
  }

  Widget _buildOrderSummary(Cart cart) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Pedido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final product = item.product;
                final total = (product?.basePrice ?? 0) * item.quantity;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      image: product?.imageUrl.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(product!.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product?.imageUrl.isEmpty == true
                        ? Icon(Icons.shopping_bag, size: 20, color: colorScheme.outline)
                        : null,
                  ),
                  title: Text(product?.name ?? 'Producto'),
                  subtitle: Text('Cant: ${item.quantity}'),
                  trailing: Text('\$${total.toStringAsFixed(2)}'),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopSectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Entrega a domicilio',
            ),
            const SizedBox(height: 16),
            _buildShippingFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty == true) return 'Requerido';
            if (!value!.contains('@')) return 'Correo inválido';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(labelText: 'Calle y número'),
          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(
            labelText: 'Dirección línea 2 (opcional)',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'Estado'),
                validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(labelText: 'Código postal'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'País'),
                validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSectionHeader({required IconData icon, required String title}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCouponSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Código de Promoción',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _couponController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu código (ej. SAVE10)',
                prefixIcon: Icon(Icons.local_offer_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los descuentos por cupón se aplican al finalizar.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pago seguro en línea',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Al confirmar tu pedido serás redirigido a nuestra página segura de pago '
                        'para pagar con tarjeta, OXXO o transferencia (SPEI). Tu tarjeta nunca '
                        'se procesa en esta app.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PaymentMethodChip(
                  icon: Icons.credit_card,
                  label: 'Tarjeta',
                ),
                _PaymentMethodChip(
                  icon: Icons.storefront,
                  label: 'OXXO',
                ),
                _PaymentMethodChip(
                  icon: Icons.account_balance,
                  label: 'SPEI',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (value) => setState(() => _acceptTerms = value ?? false),
              title: const Text('Acepto los términos y condiciones'),
              subtitle: const Text('Consulta los términos de servicio y la política de privacidad'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to terms & conditions
              },
              child: const Text('Ver Términos y Condiciones'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(Cart cart) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 24,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processOrder,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirmar Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final OrderResponse order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación del Pedido'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: colorScheme.primary,
            ),            const SizedBox(height: 16),
            Text(
              '¡Pedido Realizado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pedido #${order.id}',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Estado: ${order.status.displayName}'),
                    Text('Artículos: ${order.items.length}'),
                    Text('Total: \$${order.total.toStringAsFixed(2)}'),
                    if (order.trackingNumber != null) ...[
                      const SizedBox(height: 8),
                      Text('Seguimiento: ${order.trackingNumber}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.offAllNamed('/');
                },
                child: const Text('Seguir Comprando'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PaymentMethodChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
