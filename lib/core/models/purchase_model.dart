import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String productId;
  final String productName;
  final String brandName;
  final String catalogName;
  final String productCode;
  final int quantity;
  final double pricePerPiece;
  final double totalAmount; // quantity * pricePerPiece
  final DateTime timestamp;
  final String supplier;
  final String notes;

  Purchase({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.catalogName,
    required this.productCode,
    required this.quantity,
    required this.pricePerPiece,
    double? totalAmount,
    DateTime? timestamp,
    this.supplier = '',
    this.notes = '',
  })  : totalAmount = totalAmount ?? (quantity * pricePerPiece),
        timestamp = timestamp ?? DateTime.now();

  factory Purchase.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final qty = (data['quantity'] ?? 0) as int;
    final cost = (data['pricePerPiece'] ?? 0.0).toDouble();

    return Purchase(
      id: documentId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      brandName: data['brandName'] ?? '',
      catalogName: data['catalogName'] ?? '',
      productCode: data['productCode'] ?? '',
      quantity: qty,
      pricePerPiece: cost,
      totalAmount: (data['totalAmount'] ?? (qty * cost)).toDouble(),
      timestamp: parseDate(data['timestamp'] ?? data['createdAt']),
      supplier: data['supplier'] ?? '',
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
      'pricePerPiece': pricePerPiece,
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'supplier': supplier,
      'notes': notes,
    };
  }
}
