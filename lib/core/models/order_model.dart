import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtSale;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      priceAtSale: (data['priceAtSale'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtSale': priceAtSale,
    };
  }
}

class AppOrder {
  final String id;
  final String customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
  });

  factory AppOrder.fromMap(Map<String, dynamic> data, String documentId) {
    return AppOrder(
      id: documentId,
      customerName: data['customerName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  AppOrder copyWith({
    String? id,
    String? customerName,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
  }) {
    return AppOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
