import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/admin_order_service.dart';

// Orders dashboard. Rendered as the body of the admin shell (no Scaffold of
// its own) so the shell's AppBar/drawer/theme toggle stay in control.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final AdminOrderService _service = AdminOrderService();

  List<OrderResponse> _orders = [];
  Map<String, int> _stats = {};
  String? _statusFilter;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _orders.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOrders(status: _statusFilter),
        _service.getStats(),
      ]);
      final page = results[0] as AdminOrdersPage;
      final stats = results[1] as Map<String, int>;
      if (!mounted) return;
      setState(() {
        _orders = page.orders;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectFilter(String? status) {
    setState(() => _statusFilter = status);
    _load();
  }

  Future<void> _changeStatus(OrderResponse order, OrderStatus status) async {
    try {
      await _service.updateOrderStatus(order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.shortId} -> ${status.displayName}'),
          backgroundColor: Colors.green[700],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return _buildError(context);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildStats(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 8),
          if (_orders.isEmpty)
            _buildEmpty()
          else
            ..._orders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _statusFilter == null
                  ? 'No orders yet'
                  : 'No $_statusFilter orders',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final total = _stats.values.fold<int>(0, (sum, count) => sum + count);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatCard(
          label: 'Total',
          count: total,
          icon: Icons.receipt_long,
          color: Theme.of(context).colorScheme.primary,
        ),
        for (final status in OrderStatus.values)
          _StatCard(
            label: status.displayName,
            count: _stats[status.englishValue] ?? 0,
            icon: status.statusIcon,
            color: status.statusColor,
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _statusFilter == null,
            onSelected: (_) => _selectFilter(null),
          ),
          const SizedBox(width: 8),
          for (final status in OrderStatus.values) ...[
            ChoiceChip(
              label: Text(status.displayName),
              selected: _statusFilter == status.englishValue,
              onSelected: (_) => _selectFilter(status.englishValue),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderResponse order) {
    final availableTargets = OrderStatus.values
        .where((status) => order.status.canTransitionTo(status))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: order.status.statusColor.withAlpha(25),
          child: Icon(order.status.statusIcon,
              color: order.status.statusColor, size: 22),
        ),
        title: Row(
          children: [
            Text(
              '#${order.shortId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: order.status.statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.displayName,
                style: TextStyle(
                  color: order.status.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${order.itemsCount} items · \$${order.total.toStringAsFixed(2)} · '
          '${order.formattedDate}',
        ),
        trailing: availableTargets.isEmpty
            ? null
            : PopupMenuButton<OrderStatus>(
                tooltip: 'Update status',
                onSelected: (status) => _changeStatus(order, status),
                itemBuilder: (context) => [
                  for (final status in availableTargets)
                    PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(status.statusIcon,
                              color: status.statusColor, size: 20),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
