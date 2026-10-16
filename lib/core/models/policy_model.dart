class PolicyModel {
  final double minimumPricePercentage; // e.g. 80% of selling price
  final double exchangeFloorPercentage; // e.g. 80% of original eligible value
  final String refundMode; // 'money_refund', 'exchange', 'no_refund'
  final int maxDistinctSkusPerSale; // default 10
  final int maxTotalUnitsPerSale; // default 100
  final int auditRetentionMonths; // default 6

  PolicyModel({
    this.minimumPricePercentage = 80.0,
    this.exchangeFloorPercentage = 80.0,
    this.refundMode = 'money_refund',
    this.maxDistinctSkusPerSale = 10,
    this.maxTotalUnitsPerSale = 100,
    this.auditRetentionMonths = 6,
  });

  double get minimumSellingPriceFloorPercent => minimumPricePercentage;

  factory PolicyModel.fromMap(Map<String, dynamic> data) {
    return PolicyModel(
      minimumPricePercentage: (data['minimumPricePercentage'] ?? 80.0).toDouble(),
      exchangeFloorPercentage: (data['exchangeFloorPercentage'] ?? 80.0).toDouble(),
      refundMode: data['refundMode'] ?? 'money_refund',
      maxDistinctSkusPerSale: (data['maxDistinctSkusPerSale'] ?? 10) as int,
      maxTotalUnitsPerSale: (data['maxTotalUnitsPerSale'] ?? 100) as int,
      auditRetentionMonths: (data['auditRetentionMonths'] ?? 6) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minimumPricePercentage': minimumPricePercentage,
      'exchangeFloorPercentage': exchangeFloorPercentage,
      'refundMode': refundMode,
      'maxDistinctSkusPerSale': maxDistinctSkusPerSale,
      'maxTotalUnitsPerSale': maxTotalUnitsPerSale,
      'auditRetentionMonths': auditRetentionMonths,
    };
  }

  PolicyModel copyWith({
    double? minimumPricePercentage,
    double? exchangeFloorPercentage,
    String? refundMode,
    int? maxDistinctSkusPerSale,
    int? maxTotalUnitsPerSale,
    int? auditRetentionMonths,
  }) {
    return PolicyModel(
      minimumPricePercentage: minimumPricePercentage ?? this.minimumPricePercentage,
      exchangeFloorPercentage: exchangeFloorPercentage ?? this.exchangeFloorPercentage,
      refundMode: refundMode ?? this.refundMode,
      maxDistinctSkusPerSale: maxDistinctSkusPerSale ?? this.maxDistinctSkusPerSale,
      maxTotalUnitsPerSale: maxTotalUnitsPerSale ?? this.maxTotalUnitsPerSale,
      auditRetentionMonths: auditRetentionMonths ?? this.auditRetentionMonths,
    );
  }
}
