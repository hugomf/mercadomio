import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // Payment Info Fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

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
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      Get.snackbar(
        'Required',
        'Please accept the terms and conditions',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

      // Payment data (in production, this would be tokenized)
      final paymentInfo = {
        'paymentMethod': 'credit_card',
        'cardholderName': _cardNameController.text,
        'lastFourDigits': _cardNumberController.text.substring(_cardNumberController.text.length - 4),
        'expiryMonth': _expiryController.text.split('/')[0],
        'expiryYear': _expiryController.text.split('/')[1],
        'billingAddress': shippingAddress, // Same as shipping for demo
      };

      // Create order from cart
      final orderResponse = await orderService.createOrderFromCart(
        widget.cartId,
        paymentInfo: {'shippingAddress': shippingAddress, 'payment': paymentInfo},
      );

      // For demo, simulate payment completion
      final updatedOrder = await orderService.simulateOrderCompletion(orderResponse.id);

      // Navigate to order confirmation
      Get.offAll(() => OrderConfirmationScreen(order: updatedOrder));

    } catch (e) {
      Get.snackbar(
        'Checkout Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Obx(() {
        final cartController = Get.find<CartController>();
        final cart = cartController.cart.value;

        if (cart == null) {
          return const Center(child: Text('Cart not found'));
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

  Widget _buildOrderSummary(Cart cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: product?.imageUrl.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(product!.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product?.imageUrl.isEmpty == true
                        ? const Icon(Icons.shopping_bag, size: 20, color: Colors.grey)
                        : null,
                  ),
                  title: Text(product?.name ?? 'Product'),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text('\$${total.toStringAsFixed(2)}'),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                if (!value!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(labelText: 'Address Line 1'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
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
                    decoration: const InputDecoration(labelText: 'ZIP Code'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Country'),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                suffixIcon: const Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                if (value!.replaceAll(' ', '').length < 13) return 'Invalid card number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '12/25',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value!)) return 'Use MM/YY format';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value!.length < 3) return 'Invalid CVV';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a demo checkout. No real payment will be processed.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
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
              title: const Text('I accept the terms and conditions'),
              subtitle: const Text('Review our terms of service and privacy policy'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to terms & conditions
              },
              child: const Text('View Terms & Conditions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(Cart cart) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Complete Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Status: ${order.status.displayName}'),
                    Text('Items: ${order.items.length}'),
                    Text('Total: \$${order.total.toStringAsFixed(2)}'),
                    if (order.trackingNumber != null) ...[
                      const SizedBox(height: 8),
                      Text('Tracking: ${order.trackingNumber}'),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
