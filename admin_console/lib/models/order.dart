class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime orderDate;
  final double totalAmount;

  Order({
    required this.id,
    required this.items,
    required this.orderDate,
    required this.totalAmount,
  });
}

class OrderItem {
  final String productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}