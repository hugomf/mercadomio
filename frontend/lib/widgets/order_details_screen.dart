import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';

// Premium Order Details Screen - Complete order tracking experience
class OrderDetailsScreen extends StatefulWidget {
  final OrderResponse order;
  final OrderService orderService;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.orderService,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _simulateOrderAction(OrderStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      // Simulate order update - in real app this would call the API
      await widget.orderService.updateOrderStatus(
        widget.order.id,
        newStatus,
      );

      // Refresh order data
      final updatedOrder = await widget.orderService.getOrder(widget.order.id);

      setState(() {
        widget.order.status = updatedOrder.status;
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to ${newStatus.displayName}'),
          backgroundColor: newStatus.statusColor,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${order.id.substring(0, 8)}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (order.canBeCancelled && !_isLoading)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancelar pedido',
              onPressed: () => _showCancelDialog(),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(order),
                const SizedBox(height: 24),

                // Order Items
                _buildOrderItems(order),
                const SizedBox(height: 24),

                // Order Timeline
                if (order.statusTimeline.isNotEmpty) ...[
                  _buildOrderTimeline(order),
                  const SizedBox(height: 24),
                ],

                // Order Summary
                _buildOrderSummary(order),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderResponse order) {
    return Card(
      elevation: 6,
      shadowColor: order.status.statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: order.status.statusGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  order.status.statusIcon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado: ${order.status.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress indicator for active orders
            if (order.status != OrderStatus.completed &&
                order.status != OrderStatus.cancelled)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progreso del pedido',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(order.progressPercentage * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: order.progressPercentage,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    if (order.estimatedDelivery.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Entrega estimada: ${order.estimatedDelivery}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(OrderResponse order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOrderItemRow(item),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.inventory_2),
                    ),
                  )
                : const Icon(Icons.inventory_2, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 16),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Producto',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Item total
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderResponse order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del Pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...order.statusTimeline.map((timeline) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: timeline.isCompleted
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeline.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          timeline.formattedTime,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderResponse order) {
    const summaryItems = [
      {'label': 'Subtotal', 'value': 0.0},
      {'label': 'Envío', 'value': 0.0},
      {'label': 'Impuestos', 'value': 0.0},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...summaryItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    item['value'] == 0.0 ? 'Por calcularse' : '\$${(item['value'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderResponse order) {
    return Column(
      children: [
        if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {
              // Would integrate with tracking service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracking integration coming soon!')),
              );
            },
            icon: const Icon(Icons.track_changes),
            label: const Text('Rastrear paquete'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (order.canBeReturned)
          OutlinedButton.icon(
            onPressed: () => _showReturnDialog(),
            icon: const Icon(Icons.replay),
            label: const Text('Solicitar devolución'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        if (order.status == OrderStatus.completed && !_isLoading)
          ElevatedButton.icon(
            onPressed: () => _showReorderDialog(),
            icon: const Icon(Icons.reorder),
            label: const Text('Reordenar productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        // Demo: Add payment simulation for pending orders
        if (order.status == OrderStatus.pending && !_isLoading)
          ElevatedButton.icon(
            onPressed: () async {
              await _simulateOrderAction(OrderStatus.paid);
            },
            icon: const Icon(Icons.payment),
            label: const Text('Completar pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ].expand((widget) => [widget, const SizedBox(height: 12)]).toList()..removeLast(),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar este pedido? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _simulateOrderAction(OrderStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar devolución'),
        content: const Text(
          '¿Quieres solicitar una devolución para este pedido? '
          'Nuestro equipo de atención al cliente te contactará pronto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Would integrate with return system
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reordenar productos'),
        content: const Text(
          '¿Quieres agregar estos productos de vuelta a tu carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Would integrate with cart service
            child: const Text('Agregar al carrito'),
          ),
        ],
      ),
    );
  }
}
