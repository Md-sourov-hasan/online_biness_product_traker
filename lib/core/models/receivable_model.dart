class Receivable {
  final String id;
  final String borrower;
  final double amountLent;
  final String interestAgreement; // 'None', 'Percentage', 'Fixed Amount'
  final double interestRate;
  final String interestRateUnit; // 'Yearly', 'Monthly', 'Flat'
  final String purpose;
  final DateTime dateLent;
  final DateTime dueDate;
  final String status; // 'pending', 'partial', 'returned', 'overdue'
  final String notes;
  final DateTime createdAt;

  Receivable({
    required this.id,
    required this.borrower,
    required this.amountLent,
    this.interestAgreement = 'None',
    this.interestRate = 0.0,
    this.interestRateUnit = 'Yearly',
    this.purpose = '',
    DateTime? dateLent,
    DateTime? dueDate,
    this.status = 'pending',
    this.notes = '',
    DateTime? createdAt,
  })  : dateLent = dateLent ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 90)),
        createdAt = createdAt ?? DateTime.now();

  factory Receivable.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Receivable(
      id: id,
      borrower: data['borrower'] ?? '',
      amountLent: (data['amountLent'] ?? 0.0).toDouble(),
      interestAgreement: data['interestAgreement'] ?? 'None',
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      interestRateUnit: data['interestRateUnit'] ?? 'Yearly',
      purpose: data['purpose'] ?? '',
      dateLent: parseDate(data['dateLent']),
      dueDate: parseDate(data['dueDate']),
      status: data['status'] ?? 'pending',
      notes: data['notes'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower': borrower,
      'amountLent': amountLent,
      'interestAgreement': interestAgreement,
      'interestRate': interestRate,
      'interestRateUnit': interestRateUnit,
      'purpose': purpose,
      'dateLent': dateLent.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Receivable copyWith({
    String? id,
    String? borrower,
    double? amountLent,
    String? interestAgreement,
    double? interestRate,
    String? interestRateUnit,
    String? purpose,
    DateTime? dateLent,
    DateTime? dueDate,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Receivable(
      id: id ?? this.id,
      borrower: borrower ?? this.borrower,
      amountLent: amountLent ?? this.amountLent,
      interestAgreement: interestAgreement ?? this.interestAgreement,
      interestRate: interestRate ?? this.interestRate,
      interestRateUnit: interestRateUnit ?? this.interestRateUnit,
      purpose: purpose ?? this.purpose,
      dateLent: dateLent ?? this.dateLent,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReceivablePayment {
  final String id;
  final String receivableId;
  final DateTime paymentDate;
  final double principalReturned; // Receivable reduction
  final double interestReceived; // Management accounting interest income
  final String paymentMethod;
  final String notes;

  ReceivablePayment({
    required this.id,
    required this.receivableId,
    DateTime? paymentDate,
    required this.principalReturned,
    this.interestReceived = 0.0,
    this.paymentMethod = 'Cash',
    this.notes = '',
  }) : paymentDate = paymentDate ?? DateTime.now();

  double get totalReceived => principalReturned + interestReceived;

  factory ReceivablePayment.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return ReceivablePayment(
      id: id,
      receivableId: data['receivableId'] ?? '',
      paymentDate: parseDate(data['paymentDate']),
      principalReturned: (data['principalReturned'] ?? 0.0).toDouble(),
      interestReceived: (data['interestReceived'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receivableId': receivableId,
      'paymentDate': paymentDate.toIso8601String(),
      'principalReturned': principalReturned,
      'interestReceived': interestReceived,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
