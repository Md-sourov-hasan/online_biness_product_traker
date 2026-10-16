class Loan {
  final String id;
  final String lenderType; // 'Bank', 'Individual', 'Business', 'Other'
  final String lenderName;
  final String purpose;
  final double principalBorrowed;
  final double interestRate; // e.g. 12%
  final String interestRateUnit; // 'Annual', 'Monthly', 'Flat'
  final String interestMethod; // 'Simple', 'Reducing Balance', 'Flat'
  final DateTime startDate;
  final DateTime dueDate;
  final String repaymentFrequency; // 'Monthly', 'Weekly', 'One-time'
  final double installmentAmount;
  final String status; // 'active', 'paid', 'overdue', 'restructured'
  final String notes;
  final DateTime createdAt;

  Loan({
    required this.id,
    this.lenderType = 'Bank',
    required this.lenderName,
    this.purpose = '',
    required this.principalBorrowed,
    this.interestRate = 0.0,
    this.interestRateUnit = 'Annual',
    this.interestMethod = 'Simple',
    DateTime? startDate,
    DateTime? dueDate,
    this.repaymentFrequency = 'Monthly',
    this.installmentAmount = 0.0,
    this.status = 'active',
    this.notes = '',
    DateTime? createdAt,
  })  : startDate = startDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 365)),
        createdAt = createdAt ?? DateTime.now();

  factory Loan.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Loan(
      id: id,
      lenderType: data['lenderType'] ?? 'Bank',
      lenderName: data['lenderName'] ?? '',
      purpose: data['purpose'] ?? '',
      principalBorrowed: (data['principalBorrowed'] ?? 0.0).toDouble(),
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      interestRateUnit: data['interestRateUnit'] ?? 'Annual',
      interestMethod: data['interestMethod'] ?? 'Simple',
      startDate: parseDate(data['startDate']),
      dueDate: parseDate(data['dueDate']),
      repaymentFrequency: data['repaymentFrequency'] ?? 'Monthly',
      installmentAmount: (data['installmentAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      notes: data['notes'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lenderType': lenderType,
      'lenderName': lenderName,
      'purpose': purpose,
      'principalBorrowed': principalBorrowed,
      'interestRate': interestRate,
      'interestRateUnit': interestRateUnit,
      'interestMethod': interestMethod,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'repaymentFrequency': repaymentFrequency,
      'installmentAmount': installmentAmount,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Loan copyWith({
    String? id,
    String? lenderType,
    String? lenderName,
    String? purpose,
    double? principalBorrowed,
    double? interestRate,
    String? interestRateUnit,
    String? interestMethod,
    DateTime? startDate,
    DateTime? dueDate,
    String? repaymentFrequency,
    double? installmentAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      lenderType: lenderType ?? this.lenderType,
      lenderName: lenderName ?? this.lenderName,
      purpose: purpose ?? this.purpose,
      principalBorrowed: principalBorrowed ?? this.principalBorrowed,
      interestRate: interestRate ?? this.interestRate,
      interestRateUnit: interestRateUnit ?? this.interestRateUnit,
      interestMethod: interestMethod ?? this.interestMethod,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      repaymentFrequency: repaymentFrequency ?? this.repaymentFrequency,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LoanPayment {
  final String id;
  final String loanId;
  final DateTime paymentDate;
  final double totalAmount;
  final double principalPaid; // Liability reduction
  final double interestPaid; // Operating interest expense
  final String paymentMethod;
  final String notes;

  LoanPayment({
    required this.id,
    required this.loanId,
    DateTime? paymentDate,
    required this.totalAmount,
    required this.principalPaid,
    required this.interestPaid,
    this.paymentMethod = 'Cash',
    this.notes = '',
  }) : paymentDate = paymentDate ?? DateTime.now();

  factory LoanPayment.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return LoanPayment(
      id: id,
      loanId: data['loanId'] ?? '',
      paymentDate: parseDate(data['paymentDate']),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      principalPaid: (data['principalPaid'] ?? 0.0).toDouble(),
      interestPaid: (data['interestPaid'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'paymentDate': paymentDate.toIso8601String(),
      'totalAmount': totalAmount,
      'principalPaid': principalPaid,
      'interestPaid': interestPaid,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
