import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_history_screen.dart';
import 'order_details_screen.dart';

// Demo screen to showcase Order Management UI features
class OrderDemoScreen extends StatefulWidget {
  const OrderDemoScreen({super.key});

  @override
  State<OrderDemoScreen> createState() => _OrderDemoScreenState();
}

class _OrderDemoScreenState extends State<OrderDemoScreen> {
  // Mock order service for demo
  late OrderService _orderService;

  @override
  void initState() {
    super.initState();
    // Initialize with mock service
    _orderService = OrderService(
      baseUrl: 'http://localhost:8080', // Mock URL
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    '🛍️ Order Management UI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Professional E-commerce Experience',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Features showcase
                _buildFeatureCard(
                  context,
                  '📋 Order History',
                  'Beautiful card-based design with status indicators, progress bars, and smooth animations.',
                  Icons.receipt_long,
                  Colors.blue,
                ),
                const SizedBox(height: 16),

                _buildFeatureCard(
                  context,
                  '📈 Order Tracking',
                  'Real-time status updates, timeline views, and delivery tracking integration.',
                  Icons.track_changes,
                  Colors.green,
                ),
                const SizedBox(height: 16),

                _buildFeatureCard(
                  context,
                  '🎨 Modern UI/UX',
                  'Material You design, gradient effects, and professional animations.',
                  Icons.design_services,
                  Colors.purple,
                ),
                const SizedBox(height: 16),

                _buildFeatureCard(
                  context,
                  '🛡️ User Security',
                  'Protected routes, ownership validation, and comprehensive error handling.',
                  Icons.security,
                  Colors.red,
                ),
                const SizedBox(height: 32),

                // Action buttons for demo
                const Text(
                  'Demo Screens',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildDemoButton(
                  context,
                  'View Order History',
                  'Browse beautiful order cards with status indicators',
                  Icons.history,
                  Colors.orange,
                  _showOrderHistoryDemo,
                ),
                const SizedBox(height: 12),

                _buildDemoButton(
                  context,
                  'View Order Details',
                  'Explore detailed order view with timeline and actions',
                  Icons.details,
                  Colors.blue,
                  _showOrderDetailsDemo,
                ),
                const SizedBox(height: 12),

                _buildDemoButton(
                  context,
                  'API Integration Ready',
                  'Complete REST API integration with authentication',
                  Icons.api,
                  Colors.green,
                  _showApiIntegrationInfo,
                ),
                const SizedBox(height: 12),

                _buildDemoButton(
                  context,
                  '💳 Payment Integration',
                  'Stripe payment processing with simulation support',
                  Icons.payment,
                  Colors.purple,
                  _showPaymentIntegrationInfo,
                ),
                const SizedBox(height: 12),

                _buildDemoButton(
                  context,
                  'Complete E-commerce Flow',
                  'From cart → order → payment processing',
                  Icons.shopping_cart_checkout,
                  Colors.indigo,
                  _showCompleteFlowDemo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(BuildContext context, String title, String subtitle, IconData icon, MaterialColor color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.start,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  void _showOrderHistoryDemo() {
    // Navigate to order history screen (would normally check if user is logged in)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderHistoryScreen(
          orderService: _orderService,
        ),
      ),
    );
  }

  void _showOrderDetailsDemo() {
    // Create a mock order for demo
    final mockOrder = OrderResponse(
      id: '507f1f77bcf86cd799439011',
      userId: 'user123',
      items: [
        OrderItem(
          id: 'item1',
          productId: 'product1',
          quantity: 2,
          price: 25.99,
          productName: 'Producto de Prueba Premium',
        ),
      ],
      total: 51.98,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          order: mockOrder,
          orderService: _orderService,
        ),
      ),
    );
  }

  void _showApiIntegrationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Complete API Integration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Order creation from cart', style: TextStyle(fontSize: 14)),
            Text('• JWT-authenticated endpoints', style: TextStyle(fontSize: 14)),
            Text('• Status validation & updates', style: TextStyle(fontSize: 14)),
            Text('• User ownership verification', style: TextStyle(fontSize: 14)),
            Text('• Comprehensive error handling', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Text(
              'All APIs tested and production-ready! 🎯',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentIntegrationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💳 Stripe Payment Integration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• PaymentIntent creation for orders', style: TextStyle(fontSize: 14)),
            Text('• Payment confirmation & status updates', style: TextStyle(fontSize: 14)),
            Text('• Webhook handling for payment events', style: TextStyle(fontSize: 14)),
            Text('• Simulation mode for testing', style: TextStyle(fontSize: 14)),
            Text('• Secure card data handling', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Text(
              'Production-ready payment processing! 💰',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCompleteFlowDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛍️ Complete E-commerce Flow'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Browse Products → 🛒 Add to Cart', style: TextStyle(fontSize: 14)),
            Text('📦 View Cart → 💳 Checkout Process', style: TextStyle(fontSize: 14)),
            Text('📋 Create Order → 💰 Payment Processing', style: TextStyle(fontSize: 14)),
            Text('📊 Order Tracking → 📦 Delivery Status', style: TextStyle(fontSize: 14)),
            Text('📱 Mobile notifications & updates', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Text(
              'End-to-end customer experience! 🌟',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
