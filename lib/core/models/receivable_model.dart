class MoneyLentReturnEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  MoneyLentReturnEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory MoneyLentReturnEntry.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return MoneyLentReturnEntry(
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

class Receivable {
  final String id; // LT-001 style
  final String person; // required
  final String phone; // optional
  final double amount; // amount given, required
  final double remaining; // starts equal to amount
  final DateTime date; // date given, default today
  final DateTime? dueDate; // expected return date, optional
  final String reason; // purpose
  final String note; // optional
  final String status; // 'pending' / 'partially_returned' / 'returned', starts pending
  final List<MoneyLentReturnEntry> returns;

  Receivable({
    required this.id,
    required this.person,
    this.phone = '',
    required this.amount,
    double? remaining,
    DateTime? date,
    this.dueDate,
    this.reason = '',
    this.note = '',
    this.status = 'pending',
    List<MoneyLentReturnEntry>? returns,
  })  : remaining = remaining ?? amount,
        date = date ?? DateTime.now(),
        returns = returns ?? [];

  // --- Spec Section 5 Formulas ---
  double get totalReturned => returns.fold(0.0, (sum, r) => sum + r.amount);
  double get returnedPercentage => amount > 0 ? (totalReturned / amount * 100.0).clamp(0.0, 100.0) : 0.0;
  bool get isReturned => status.toLowerCase() == 'returned' || remaining <= 0;

  // Overdue = due date passed and status is not returned
  bool get isOverdue {
    if (isReturned || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays < 0;
  }

  // Due Soon = due within 0 to 7 days and status is not returned
  bool get isDueSoon {
    if (isReturned || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = due.difference(today).inDays;
    return diff >= 0 && diff <= 7;
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  // Backward compatibility getters
  String get borrower => person;
  double get amountLent => amount;
  DateTime get dateLent => date;
  String get purpose => reason;
  String get notes => note;

  factory Receivable.fromMap(Map<String, dynamic> data, String id) {
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

    final rawReturns = data['returns'] as List<dynamic>? ?? [];
    final returnsList = rawReturns.map((r) {
      if (r is Map<String, dynamic>) {
        return MoneyLentReturnEntry.fromMap(r, r['id']?.toString() ?? '');
      }
      return MoneyLentReturnEntry(id: '', amount: 0, date: DateTime.now());
    }).where((r) => r.id.isNotEmpty).toList();

    final amt = (data['amount'] ?? data['amountLent'] ?? 0.0).toDouble();
    final rem = data['remaining'] != null ? (data['remaining']).toDouble() : amt;

    return Receivable(
      id: id,
      person: data['person'] ?? data['borrower'] ?? '',
      phone: data['phone'] ?? '',
      amount: amt,
      remaining: rem,
      date: parseDate(data['date'] ?? data['dateLent']),
      dueDate: parseOptionalDate(data['dueDate']),
      reason: data['reason'] ?? data['purpose'] ?? '',
      note: data['note'] ?? data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      returns: returnsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person': person,
      'phone': phone,
      'amount': amount,
      'remaining': remaining,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'reason': reason,
      'note': note,
      'status': status,
      'returns': returns.map((r) => r.toMap()).toList(),
    };
  }

  Receivable copyWith({
    String? id,
    String? person,
    String? phone,
    double? amount,
    double? remaining,
    DateTime? date,
    DateTime? dueDate,
    String? reason,
    String? note,
    String? status,
    List<MoneyLentReturnEntry>? returns,
  }) {
    return Receivable(
      id: id ?? this.id,
      person: person ?? this.person,
      phone: phone ?? this.phone,
      amount: amount ?? this.amount,
      remaining: remaining ?? this.remaining,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      status: status ?? this.status,
      returns: returns ?? this.returns,
    );
  }
}

// Retain legacy ReceivablePayment class if referenced in older code
class ReceivablePayment {
  final String id;
  final String receivableId;
  final DateTime paymentDate;
  final double principalReturned;
  final double interestReceived;
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
