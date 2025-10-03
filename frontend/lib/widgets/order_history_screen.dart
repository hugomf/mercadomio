import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_details_screen.dart';

// Professional Order History Screen - Selling Point UI
class OrderHistoryScreen extends StatefulWidget {
  final OrderService orderService;

  const OrderHistoryScreen({
    super.key,
    required this.orderService,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late Future<OrderHistoryResponse> _ordersFuture;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.orderService.getOrderHistory(page: _currentPage, limit: _limit);

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadMoreOrders() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    // In a real app, you'd append to existing list
    // For demo, we'll refresh with new page
    widget.orderService.getOrderHistory(page: _currentPage, limit: _limit).then((newOrders) {
      setState(() {
        _ordersFuture = Future.value(newOrders);
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters coming soon!')),
              );
            },
          ),
        ],
      ),
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
        child: FutureBuilder<OrderHistoryResponse>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error!);
            }

            if (!snapshot.hasData || snapshot.data!.orders.isEmpty) {
              return _buildEmptyView();
            }

            final orders = snapshot.data!.orders;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _currentPage = 1;
                    _ordersFuture = widget.orderService.getOrderHistory(
                      page: _currentPage,
                      limit: _limit,
                    );
                  });
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= orders.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OrderCard(
                        order: order,
                        onTap: () => _navigateToOrderDetails(order),
                        animationDelay: index * 100,
                      ),
                    );

                    // Note: Load more logic would go here for pagination
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to continue shopping or cart
          Navigator.of(context).pushNamed('/products');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.shopping_bag, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _ordersFuture = widget.orderService.getOrderHistory(
                  page: _currentPage,
                  limit: _limit,
                );
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/products');
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(OrderResponse order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          order: order,
          orderService: widget.orderService,
        ),
      ),
    );
  }
}

// Professional Order Card Widget - Key selling point
class OrderCard extends StatefulWidget {
  final OrderResponse order;
  final VoidCallback onTap;
  final int animationDelay;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Delayed animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 8,
          shadowColor: order.status.statusColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with order ID and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #${order.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: order.status.statusGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              order.status.statusIcon,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.status.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date and time
                  Text(
                    order.formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Order items preview
                  if (order.items.length <= 3) ...[
                    // Show all items if 3 or fewer
                    for (var item in order.items) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildOrderItemRow(item),
                      ),
                    ],
                  ] else ...[
                    // Show first 2 items with "more" indicator
                    for (var i = 0; i < 2; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildOrderItemRow(order.items[i]),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '+ ${order.items.length - 2} más',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Total and action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.itemsCount} producto${order.itemsCount != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      // Progress indicator for active orders
                      if (order.status != OrderStatus.completed &&
                          order.status != OrderStatus.cancelled)
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: order.progressPercentage,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              order.status.statusColor,
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.chevron_right),
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Row(
      children: [
        // Product image placeholder
        Container(
          width: 40,
          height: 40,
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
              : const Icon(Icons.inventory_2, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        // Product details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Producto',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Cant: ${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Item total
        Text(
          '\$${item.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
