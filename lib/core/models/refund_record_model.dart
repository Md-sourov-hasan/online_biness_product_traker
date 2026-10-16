class RefundRecord {
  final String id;
  final String originalSaleId;
  final String productId;
  final String productName;
  final int quantityReturned;
  final double refundAmount;
  final String type; // 'refund', 'exchange'
  final String replacementProductId;
  final String replacementProductName;
  final double replacementValue;
  final double customerDifferencePaid;
  final String resolvedByRole;
  final String resolvedByUserId;
  final String reason;
  final DateTime timestamp;

  RefundRecord({
    required this.id,
    required this.originalSaleId,
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.refundAmount,
    this.type = 'refund',
    this.replacementProductId = '',
    this.replacementProductName = '',
    this.replacementValue = 0.0,
    this.customerDifferencePaid = 0.0,
    required this.resolvedByRole,
    required this.resolvedByUserId,
    this.reason = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RefundRecord.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return RefundRecord(
      id: id,
      originalSaleId: data['originalSaleId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantityReturned: (data['quantityReturned'] ?? 0) as int,
      refundAmount: (data['refundAmount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'refund',
      replacementProductId: data['replacementProductId'] ?? '',
      replacementProductName: data['replacementProductName'] ?? '',
      replacementValue: (data['replacementValue'] ?? 0.0).toDouble(),
      customerDifferencePaid: (data['customerDifferencePaid'] ?? 0.0).toDouble(),
      resolvedByRole: data['resolvedByRole'] ?? 'Manager',
      resolvedByUserId: data['resolvedByUserId'] ?? '',
      reason: data['reason'] ?? '',
      timestamp: parseDate(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalSaleId': originalSaleId,
      'productId': productId,
      'productName': productName,
      'quantityReturned': quantityReturned,
      'refundAmount': refundAmount,
      'type': type,
      'replacementProductId': replacementProductId,
      'replacementProductName': replacementProductName,
      'replacementValue': replacementValue,
      'customerDifferencePaid': customerDifferencePaid,
      'resolvedByRole': resolvedByRole,
      'resolvedByUserId': resolvedByUserId,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
