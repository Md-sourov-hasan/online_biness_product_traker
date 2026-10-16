import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String brandName;
  final String catalogName;
  final String productCode;
  final int quantity;
  final double pricePerPiece; // Cost price per unit (Acquisition cost)
  final double sellingPrice; // Customer-facing base price before discounts
  final double totalPrice; // Auto-calculated (quantity * pricePerPiece)
  final DateTime buyingDate;
  final String notes;
  final int lowStockThreshold;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.brandName,
    required this.catalogName,
    required this.productCode,
    required this.quantity,
    required this.pricePerPiece,
    double? sellingPrice,
    double? totalPrice,
    DateTime? buyingDate,
    this.notes = '',
    this.lowStockThreshold = 3,
    this.imageUrl,
    DateTime? createdAt,
  })  : sellingPrice = sellingPrice ?? (pricePerPiece * 1.25),
        totalPrice = totalPrice ?? (quantity * pricePerPiece),
        buyingDate = buyingDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  String get displayName => '$brandName $catalogName'.trim();

  // Backward compatibility getters
  String get name => displayName;
  double get costPrice => pricePerPiece;
  int get stockQuantity => quantity;
  String get sku => productCode;
  String get category => brandName;

  // Pricing Helpers per Spec Section 7.3
  static double calculateSellingPriceWithMarkup(double cost, double markupPercentage) {
    return cost * (1.0 + (markupPercentage / 100.0));
  }

  static double calculateSellingPriceWithMargin(double cost, double marginPercentage) {
    if (marginPercentage >= 100.0) return cost;
    return cost / (1.0 - (marginPercentage / 100.0));
  }

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final qty = (data['quantity'] ?? data['stockQuantity'] ?? 0) as int;
    final cost = (data['pricePerPiece'] ?? data['costPrice'] ?? 0.0).toDouble();
    final sell = (data['sellingPrice'] ?? (cost * 1.25)).toDouble();

    return Product(
      id: documentId,
      brandName: data['brandName'] ?? data['category'] ?? 'General',
      catalogName: data['catalogName'] ?? data['name'] ?? '',
      productCode: data['productCode'] ?? data['sku'] ?? '',
      quantity: qty,
      pricePerPiece: cost,
      sellingPrice: sell > 0 ? sell : (cost * 1.25),
      totalPrice: (data['totalPrice'] ?? (qty * cost)).toDouble(),
      buyingDate: parseDate(data['buyingDate']),
      notes: data['notes'] ?? '',
      lowStockThreshold: data['lowStockThreshold'] ?? 3,
      imageUrl: data['imageUrl'],
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brandName': brandName,
      'catalogName': catalogName,
      'productCode': productCode,
      'quantity': quantity,
      'pricePerPiece': pricePerPiece,
      'sellingPrice': sellingPrice,
      'totalPrice': totalPrice,
      'buyingDate': buyingDate.toIso8601String(),
      'notes': notes,
      'lowStockThreshold': lowStockThreshold,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? brandName,
    String? catalogName,
    String? productCode,
    int? quantity,
    double? pricePerPiece,
    double? sellingPrice,
    double? totalPrice,
    DateTime? buyingDate,
    String? notes,
    int? lowStockThreshold,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    final updatedQty = quantity ?? this.quantity;
    final updatedCost = pricePerPiece ?? this.pricePerPiece;
    final updatedSell = sellingPrice ?? this.sellingPrice;
    return Product(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      catalogName: catalogName ?? this.catalogName,
      productCode: productCode ?? this.productCode,
      quantity: updatedQty,
      pricePerPiece: updatedCost,
      sellingPrice: updatedSell,
      totalPrice: totalPrice ?? (updatedQty * updatedCost),
      buyingDate: buyingDate ?? this.buyingDate,
      notes: notes ?? this.notes,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
