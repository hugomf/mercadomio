import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderListScreen extends StatelessWidget {
  final List<Order> orders;

  OrderListScreen({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Management'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text('Order ID: ${order.id}'),
            subtitle: Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}