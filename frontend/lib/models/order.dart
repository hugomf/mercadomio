import 'package:flutter/material.dart';

// Order Status Enum - Complete with Material Design styling
enum OrderStatus {
  pending,
  paid,
  shipped,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.paid:
        return 'Pagado';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get englishValue => toString().split('.').last;

  Color get statusColor {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange[600]!;
      case OrderStatus.paid:
        return Colors.blue[600]!;
      case OrderStatus.shipped:
        return Colors.deepPurple[600]!;
      case OrderStatus.completed:
        return Colors.green[600]!;
      case OrderStatus.cancelled:
        return Colors.red[600]!;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.paid:
        return Icons.account_balance_wallet;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  LinearGradient get statusGradient {
    switch (this) {
      case OrderStatus.pending:
        return const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]);
      case OrderStatus.paid:
        return const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]);
      case OrderStatus.shipped:
        return const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)]);
      case OrderStatus.completed:
        return const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]);
      case OrderStatus.cancelled:
        return const LinearGradient(colors: [Color(0xFFF44336), Color(0xFFEF5350)]);
    }
  }
}

// Order Item Model
class OrderItem {
  final String id;
  final String productId;
  final String variantId;
  final int quantity;
  final double price;
  final String? productName;
  final String? imageUrl;

  // Calculated properties
  double get total => price * quantity;

  OrderItem({
    required this.id,
    required this.productId,
    this.variantId = '',
    required this.quantity,
    required this.price,
    this.productName,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      productName: json['productName'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'price': price,
      'productName': productName,
      'imageUrl': imageUrl,
    };
  }
}

// Order Response Model - Complete with UI-ready properties
class OrderResponse {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final Map<String, dynamic>? paymentInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // UI-ready calculated properties
  String get formattedDate {
    final today = DateTime.now();
    final orderDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (orderDate == DateTime(today.year, today.month, today.day)) {
      return 'Hoy, ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (orderDate == DateTime(today.year, today.month, today.day - 1)) {
      return 'Ayer, ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  double get progressPercentage {
    switch (status) {
      case OrderStatus.pending: return 0.1;
      case OrderStatus.paid: return 0.33;
      case OrderStatus.shipped: return 0.67;
      case OrderStatus.completed: return 1.0;
      case OrderStatus.cancelled: return 1.0;
    }
  }

  String get estimatedDelivery {
    if (status == OrderStatus.completed || status == OrderStatus.cancelled) {
      return '';
    }
    // Mock delivery estimate
    return (DateTime.now().add(const Duration(days: 3))).toString().split(' ')[0];
  }

  bool get canBeCancelled {
    return status == OrderStatus.pending;
  }

  bool get canBeReturned {
    return status == OrderStatus.completed;
  }

  String? get trackingNumber {
    // Mock tracking number for shipped orders
    if (status.index >= OrderStatus.shipped.index) {
      return "TRK${id.substring(0, 8).toUpperCase()}";
    }
    return null;
  }

  String get formattedTime => '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Status tracking for timeline UI
  List<OrderStatusTimeline> get statusTimeline {
    final now = DateTime.now();
    final timeline = <OrderStatusTimeline>[];

    // Add statuses based on current order status
    if (status.index >= OrderStatus.pending.index) {
      timeline.add(OrderStatusTimeline(
        status: OrderStatus.pending,
        timestamp: createdAt,
        isCompleted: true,
        description: 'Orden creada exitosamente',
      ));
    }

    if (status.index >= OrderStatus.paid.index) {
      timeline.add(OrderStatusTimeline(
        status: OrderStatus.paid,
        timestamp: createdAt.add(const Duration(hours: 1)), // Mock time
        isCompleted: true,
        description: 'Pago procesado correctamente',
      ));
    }

    if (status.index >= OrderStatus.shipped.index) {
      timeline.add(OrderStatusTimeline(
        status: OrderStatus.shipped,
        timestamp: updatedAt,
        isCompleted: status == OrderStatus.shipped || status == OrderStatus.completed,
        description: 'Paquete enviado',
      ));
    }

    if (status == OrderStatus.completed) {
      timeline.add(OrderStatusTimeline(
        status: OrderStatus.completed,
        timestamp: updatedAt,
        isCompleted: true,
        description: 'Orden completada - ¡Gracias por tu compra!',
      ));
    }

    if (status == OrderStatus.cancelled) {
      timeline.add(OrderStatusTimeline(
        status: OrderStatus.cancelled,
        timestamp: updatedAt,
        isCompleted: true,
        description: 'Orden cancelada',
      ));
    }

    return timeline;
  }

  OrderResponse({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    this.paymentInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ?? [],
      total: (json['total'] ?? 0.0).toDouble(),
      status: _parseOrderStatus(json['status'] ?? 'pending'),
      paymentInfo: json['paymentInfo'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'paid': return OrderStatus.paid;
      case 'shipped': return OrderStatus.shipped;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.englishValue,
      'paymentInfo': paymentInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Timeline model for order status tracking UI
class OrderStatusTimeline {
  final OrderStatus status;
  final DateTime timestamp;
  final bool isCompleted;
  final String description;

  OrderStatusTimeline({
    required this.status,
    required this.timestamp,
    required this.isCompleted,
    required this.description,
  });

  String get formattedTime {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// Request models
class OrderCreateRequest {
  final String cartId;
  final Map<String, dynamic>? paymentInfo;

  OrderCreateRequest({
    required this.cartId,
    this.paymentInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'paymentInfo': paymentInfo,
    };
  }
}

class OrderHistoryResponse {
  final List<OrderResponse> orders;
  final int total;
  final int page;
  final int limit;

  OrderHistoryResponse({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory OrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResponse(
      orders: (json['orders'] as List<dynamic>?)
             ?.map((order) => OrderResponse.fromJson(order))
             .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}
