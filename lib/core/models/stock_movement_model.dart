import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovement {
  final String id;
  final String productId;
  final String type; // 'restock', 'sale', 'adjustment'
  final int quantity; // Positive for restock, negative for sale/deduction
  final DateTime timestamp;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.timestamp,
  });

  factory StockMovement.fromMap(Map<String, dynamic> data, String documentId) {
    return StockMovement(
      id: documentId,
      productId: data['productId'] ?? '',
      type: data['type'] ?? 'adjustment',
      quantity: data['quantity'] ?? 0,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
