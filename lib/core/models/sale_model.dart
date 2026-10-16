import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final String brandName;
  final String catalogName;
  final String productCode;
  final int quantity;
  final double unitCost; // Buying cost per piece
  final double unitPrice; // Sold price per piece
  final double totalPrice; // quantity * unitPrice (Revenue)
  final double profit; // (unitPrice - unitCost) * quantity
  final DateTime timestamp;
  final String notes;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.catalogName,
    required this.productCode,
    required this.quantity,
    required this.unitCost,
    required this.unitPrice,
    double? totalPrice,
    double? profit,
    DateTime? timestamp,
    this.notes = '',
  })  : totalPrice = totalPrice ?? (quantity * unitPrice),
        profit = profit ?? ((unitPrice - unitCost) * quantity),
        timestamp = timestamp ?? DateTime.now();

  factory Sale.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final qty = (data['quantity'] ?? 0) as int;
    final cost = (data['unitCost'] ?? 0.0).toDouble();
    final price = (data['unitPrice'] ?? 0.0).toDouble();

    return Sale(
      id: documentId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      brandName: data['brandName'] ?? '',
      catalogName: data['catalogName'] ?? '',
      productCode: data['productCode'] ?? '',
      quantity: qty,
      unitCost: cost,
      unitPrice: price,
      totalPrice: (data['totalPrice'] ?? (qty * price)).toDouble(),
      profit: (data['profit'] ?? ((price - cost) * qty)).toDouble(),
      timestamp: parseDate(data['timestamp'] ?? data['createdAt']),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'brandName': brandName,
      'catalogName': catalogName,
      'productCode': productCode,
      'quantity': quantity,
      'unitCost': unitCost,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'profit': profit,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }
}
