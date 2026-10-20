class LoanPaymentEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  LoanPaymentEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory LoanPaymentEntry.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return LoanPaymentEntry(
      id: id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: parseDate(data['date']),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}

enum LoanState { cleared, overdue, dueSoon, active }

class Loan {
  final String id; // LN-001 style
  final String lender; // bank name or person name, required
  final String type; // 'bank' / 'person', default 'bank'
  final String phone; // optional
  final double amount; // total borrowed, required
  final double remaining; // starts equal to amount
  final double interestRate; // % per year, 0 if none
  final DateTime startDate; // default today
  final DateTime? dueDate; // optional
  final double monthlyPayment; // monthly installment (EMI), 0 if none
  final String purpose; // optional
  final String note; // optional
  final String status; // 'active' / 'cleared', starts active
  final List<LoanPaymentEntry> payments;

  Loan({
    required this.id,
    required this.lender,
    this.type = 'bank',
    this.phone = '',
    required this.amount,
    double? remaining,
    this.interestRate = 0.0,
    DateTime? startDate,
    this.dueDate,
    this.monthlyPayment = 0.0,
    this.purpose = '',
    this.note = '',
    this.status = 'active',
    List<LoanPaymentEntry>? payments,
  })  : remaining = remaining ?? amount,
        startDate = startDate ?? DateTime.now(),
        payments = payments ?? [];

  // --- Spec Section 4 Formulas ---
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get paidPercentage => amount > 0 ? ((amount - remaining) / amount * 100.0).clamp(0.0, 100.0) : 0.0;
  bool get isCleared => status.toLowerCase() == 'cleared' || remaining <= 0;

  LoanState get calculatedState {
    if (isCleared) return LoanState.cleared;
    if (dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      final diff = due.difference(today).inDays;
      if (diff < 0) return LoanState.overdue;
      if (diff <= 30) return LoanState.dueSoon;
    }
    return LoanState.active;
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  // Backward compatibility getters
  String get lenderName => lender;
  String get lenderType => type == 'person' ? 'Person' : 'Bank';
  double get principalBorrowed => amount;
  double get installmentAmount => monthlyPayment;
  String get notes => note;

  factory Loan.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawPayments = data['payments'] as List<dynamic>? ?? [];
    final payments = rawPayments.map((p) {
      if (p is Map<String, dynamic>) {
        return LoanPaymentEntry.fromMap(p, p['id']?.toString() ?? '');
      }
      return LoanPaymentEntry(id: '', amount: 0, date: DateTime.now());
    }).where((p) => p.id.isNotEmpty).toList();

    final amt = (data['amount'] ?? data['principalBorrowed'] ?? 0.0).toDouble();
    final rem = data['remaining'] != null ? (data['remaining']).toDouble() : amt;

    return Loan(
      id: id,
      lender: data['lender'] ?? data['lenderName'] ?? '',
      type: (data['type'] ?? data['lenderType'] ?? 'bank').toString().toLowerCase() == 'person' ? 'person' : 'bank',
      phone: data['phone'] ?? '',
      amount: amt,
      remaining: rem,
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      startDate: parseDate(data['startDate']),
      dueDate: parseOptionalDate(data['dueDate']),
      monthlyPayment: (data['monthlyPayment'] ?? data['installmentAmount'] ?? 0.0).toDouble(),
      purpose: data['purpose'] ?? '',
      note: data['note'] ?? data['notes'] ?? '',
      status: data['status'] ?? 'active',
      payments: payments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lender': lender,
      'type': type,
      'phone': phone,
      'amount': amount,
      'remaining': remaining,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'monthlyPayment': monthlyPayment,
      'purpose': purpose,
      'note': note,
      'status': status,
      'payments': payments.map((p) => p.toMap()).toList(),
    };
  }

  Loan copyWith({
    String? id,
    String? lender,
    String? type,
    String? phone,
    double? amount,
    double? remaining,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    double? monthlyPayment,
    String? purpose,
    String? note,
    String? status,
    List<LoanPaymentEntry>? payments,
  }) {
    return Loan(
      id: id ?? this.id,
      lender: lender ?? this.lender,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      amount: amount ?? this.amount,
      remaining: remaining ?? this.remaining,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      purpose: purpose ?? this.purpose,
      note: note ?? this.note,
      status: status ?? this.status,
      payments: payments ?? this.payments,
    );
  }
}

// Retain legacy LoanPayment class if referenced in older code
class LoanPayment {
  final String id;
  final String loanId;
  final DateTime paymentDate;
  final double totalAmount;
  final double principalPaid;
  final double interestPaid;
  final String paymentMethod;
  final String notes;

  LoanPayment({
    required this.id,
    required this.loanId,
    DateTime? paymentDate,
    required this.totalAmount,
    double? principalPaid,
    this.interestPaid = 0.0,
    this.paymentMethod = 'Bank Transfer',
    this.notes = '',
  })  : paymentDate = paymentDate ?? DateTime.now(),
        principalPaid = principalPaid ?? totalAmount;

  factory LoanPayment.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final total = (data['totalAmount'] ?? 0.0).toDouble();
    return LoanPayment(
      id: id,
      loanId: data['loanId'] ?? '',
      paymentDate: parseDate(data['paymentDate']),
      totalAmount: total,
      principalPaid: (data['principalPaid'] ?? total).toDouble(),
      interestPaid: (data['interestPaid'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Bank Transfer',
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
