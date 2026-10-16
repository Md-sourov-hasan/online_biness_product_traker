class DiscountRule {
  final String id;
  final String name;
  final String scope; // 'all', 'product', 'brand', 'catalog'
  final String targetValue; // id or brand name or category name
  final double discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final String requesterId;
  final String requesterName;
  final String approverId;
  final String approverName;
  final String status; // 'pending', 'approved', 'rejected', 'expired'
  final String reason;
  final DateTime createdAt;

  DiscountRule({
    required this.id,
    required this.name,
    this.scope = 'all',
    this.targetValue = '',
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    this.requesterId = '',
    this.requesterName = '',
    this.approverId = '',
    this.approverName = '',
    this.status = 'pending',
    this.reason = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCurrentlyActive {
    if (status != 'approved') return false;
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        now.isBefore(endDate.add(const Duration(seconds: 1)));
  }

  factory DiscountRule.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return DiscountRule(
      id: id,
      name: data['name'] ?? '',
      scope: data['scope'] ?? 'all',
      targetValue: data['targetValue'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      approverId: data['approverId'] ?? '',
      approverName: data['approverName'] ?? '',
      status: data['status'] ?? 'pending',
      reason: data['reason'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scope': scope,
      'targetValue': targetValue,
      'discountPercentage': discountPercentage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'requesterId': requesterId,
      'requesterName': requesterName,
      'approverId': approverId,
      'approverName': approverName,
      'status': status,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DiscountRule copyWith({
    String? id,
    String? name,
    String? scope,
    String? targetValue,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    String? requesterId,
    String? requesterName,
    String? approverId,
    String? approverName,
    String? status,
    String? reason,
    DateTime? createdAt,
  }) {
    return DiscountRule(
      id: id ?? this.id,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      targetValue: targetValue ?? this.targetValue,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
