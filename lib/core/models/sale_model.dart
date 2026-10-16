import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final String brandName;
  final String catalogName;
  final String productCode;
  final int quantity;
  final double unitCost; // Acquisition cost attributable to unit sold (COGS)
  final double unitPrice; // Base selling price before discount
  final double discountAmount; // Authorized discount reduction
  final double totalPrice; // Net sales revenue: (quantity * unitPrice) - discountAmount
  final double profit; // Gross profit: totalPrice - (quantity * unitCost)
  final String paymentMethod;
  final String sellerId;
  final String sellerName;
  final String sellerRole;
  final String status; // 'completed', 'corrected', 'refunded', 'exchanged'
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
    this.discountAmount = 0.0,
    double? totalPrice,
    double? profit,
    this.paymentMethod = 'Cash',
    this.sellerId = '',
    this.sellerName = 'Staff',
    this.sellerRole = 'Staff',
    this.status = 'completed',
    DateTime? timestamp,
    this.notes = '',
  })  : totalPrice = totalPrice ?? ((quantity * unitPrice) - discountAmount),
        profit = profit ??
            ((totalPrice ?? ((quantity * unitPrice) - discountAmount)) -
                (unitCost * quantity)),
        timestamp = timestamp ?? DateTime.now();

  double get grossSales => quantity * unitPrice;
  double get cogs => unitCost * quantity;

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
    final discount = (data['discountAmount'] ?? 0.0).toDouble();
    final total = (data['totalPrice'] ?? ((qty * price) - discount)).toDouble();
    final prof = (data['profit'] ?? (total - (cost * qty))).toDouble();

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
      discountAmount: discount,
      totalPrice: total,
      profit: prof,
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Staff',
      sellerRole: data['sellerRole'] ?? 'Staff',
      status: data['status'] ?? 'completed',
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
      'discountAmount': discountAmount,
      'totalPrice': totalPrice,
      'profit': profit,
      'paymentMethod': paymentMethod,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRole': sellerRole,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    String? brandName,
    String? catalogName,
    String? productCode,
    int? quantity,
    double? unitCost,
    double? unitPrice,
    double? discountAmount,
    double? totalPrice,
    double? profit,
    String? paymentMethod,
    String? sellerId,
    String? sellerName,
    String? sellerRole,
    String? status,
    DateTime? timestamp,
    String? notes,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      brandName: brandName ?? this.brandName,
      catalogName: catalogName ?? this.catalogName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      profit: profit ?? this.profit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRole: sellerRole ?? this.sellerRole,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}

class SaleCartItem {
  final Product product;
  int quantity;
  double unitPrice; // Sold unit price
  double discount; // Discount on line
  String notes;

  SaleCartItem({
    required this.product,
    this.quantity = 1,
    double? unitPrice,
    this.discount = 0.0,
    this.notes = '',
  }) : unitPrice = unitPrice ?? product.sellingPrice;

  double get grossLineTotal => quantity * unitPrice;
  double get netLineTotal => (quantity * unitPrice) - discount;
  double get unitCost => product.pricePerPiece;
  double get estimatedProfit => netLineTotal - (quantity * unitCost);
}

class SaleValidationResult {
  final bool isValid;
  final String? errorMessage;

  SaleValidationResult.success()
      : isValid = true,
        errorMessage = null;

  SaleValidationResult.failure(this.errorMessage) : isValid = false;
}

