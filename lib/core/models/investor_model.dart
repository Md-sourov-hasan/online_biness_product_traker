class Investor {
  final String id;
  final String name;
  final DateTime investmentDate;
  final String investmentType; // 'Equity Partner', 'Profit-Share Partner', 'Fixed ROI', 'Silent Partner'
  final double initialInvestedAmount;
  final double ownershipPercentage; // Equity %
  final double profitSharePercentage; // Profit-share % (can differ from equity)
  final double agreedRoiPercentage; // For fixed-return model
  final String status; // 'active', 'inactive'
  final String notes;
  final DateTime createdAt;

  Investor({
    required this.id,
    required this.name,
    DateTime? investmentDate,
    this.investmentType = 'Equity Partner',
    required this.initialInvestedAmount,
    this.ownershipPercentage = 0.0,
    this.profitSharePercentage = 0.0,
    this.agreedRoiPercentage = 0.0,
    this.status = 'active',
    this.notes = '',
    DateTime? createdAt,
  })  : investmentDate = investmentDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  // Core Equity Formulas per Spec Section 11.2 & 11.3
  double get postMoneyValuation {
    if (ownershipPercentage <= 0) return 0.0;
    return initialInvestedAmount / (ownershipPercentage / 100.0);
  }

  double get preMoneyValuation {
    final post = postMoneyValuation;
    if (post <= 0) return 0.0;
    return post - initialInvestedAmount;
  }

  double calculateProfitDistribution(double distributableProfit) {
    if (profitSharePercentage <= 0) return 0.0;
    return distributableProfit * (profitSharePercentage / 100.0);
  }

  factory Investor.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Investor(
      id: id,
      name: data['name'] ?? '',
      investmentDate: parseDate(data['investmentDate']),
      investmentType: data['investmentType'] ?? 'Equity Partner',
      initialInvestedAmount: (data['initialInvestedAmount'] ?? 0.0).toDouble(),
      ownershipPercentage: (data['ownershipPercentage'] ?? 0.0).toDouble(),
      profitSharePercentage: (data['profitSharePercentage'] ?? 0.0).toDouble(),
      agreedRoiPercentage: (data['agreedRoiPercentage'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      notes: data['notes'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'investmentDate': investmentDate.toIso8601String(),
      'investmentType': investmentType,
      'initialInvestedAmount': initialInvestedAmount,
      'ownershipPercentage': ownershipPercentage,
      'profitSharePercentage': profitSharePercentage,
      'agreedRoiPercentage': agreedRoiPercentage,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Investor copyWith({
    String? id,
    String? name,
    DateTime? investmentDate,
    String? investmentType,
    double? initialInvestedAmount,
    double? ownershipPercentage,
    double? profitSharePercentage,
    double? agreedRoiPercentage,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Investor(
      id: id ?? this.id,
      name: name ?? this.name,
      investmentDate: investmentDate ?? this.investmentDate,
      investmentType: investmentType ?? this.investmentType,
      initialInvestedAmount: initialInvestedAmount ?? this.initialInvestedAmount,
      ownershipPercentage: ownershipPercentage ?? this.ownershipPercentage,
      profitSharePercentage: profitSharePercentage ?? this.profitSharePercentage,
      agreedRoiPercentage: agreedRoiPercentage ?? this.agreedRoiPercentage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class InvestorTransaction {
  final String id;
  final String investorId;
  final String type; // 'contribution', 'withdrawal', 'distribution', 'reinvestment'
  final double amount;
  final DateTime date;
  final String notes;

  InvestorTransaction({
    required this.id,
    required this.investorId,
    required this.type,
    required this.amount,
    DateTime? date,
    this.notes = '',
  }) : date = date ?? DateTime.now();

  factory InvestorTransaction.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return InvestorTransaction(
      id: id,
      investorId: data['investorId'] ?? '',
      type: data['type'] ?? 'contribution',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: parseDate(data['date']),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investorId': investorId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
