class InvestorSubRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  InvestorSubRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory InvestorSubRecord.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return InvestorSubRecord(
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

class Investor {
  final String id; // INV-001 style
  final String name; // required
  final String phone; // optional
  final String email; // optional
  final double investAmount; // initial investment, required
  final DateTime date; // investment / join date
  final double profitShare; // number (percent), default 0
  final String status; // 'active' / 'inactive', default 'active'
  final String note; // optional
  final List<InvestorSubRecord> withdrawals; // list of {id, amount, date, note}
  final List<InvestorSubRecord> reinvestments; // list of {id, amount, date, note}

  Investor({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    required this.investAmount,
    DateTime? date,
    this.profitShare = 0.0,
    this.status = 'active',
    this.note = '',
    List<InvestorSubRecord>? withdrawals,
    List<InvestorSubRecord>? reinvestments,
  })  : date = date ?? DateTime.now(),
        withdrawals = withdrawals ?? [],
        reinvestments = reinvestments ?? [];

  // --- Spec Section 3 Formulas ---
  double get totalReinvestments => reinvestments.fold(0.0, (sum, r) => sum + r.amount);
  double get totalReinvested => totalReinvestments;
  double get totalWithdrawn => withdrawals.fold(0.0, (sum, w) => sum + w.amount);
  double get totalInvested => investAmount + totalReinvestments;
  double get netBalance => totalInvested - totalWithdrawn;
  bool get isActive => status.toLowerCase() == 'active';

  double calculateProfitDue(double netProfit) {
    if (profitShare <= 0) return 0.0;
    return netProfit * profitShare / 100.0;
  }

  // Backward compatibility getters
  double get initialInvestedAmount => investAmount;
  double get profitSharePercentage => profitShare;
  double get ownershipPercentage => profitShare;
  DateTime get investmentDate => date;
  String get notes => note;

  factory Investor.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final rawWithdrawals = data['withdrawals'] as List<dynamic>? ?? [];
    final withdrawals = rawWithdrawals.map((w) {
      if (w is Map<String, dynamic>) {
        return InvestorSubRecord.fromMap(w, w['id']?.toString() ?? '');
      }
      return InvestorSubRecord(id: '', amount: 0, date: DateTime.now());
    }).where((w) => w.id.isNotEmpty).toList();

    final rawReinvestments = data['reinvestments'] as List<dynamic>? ?? [];
    final reinvestments = rawReinvestments.map((r) {
      if (r is Map<String, dynamic>) {
        return InvestorSubRecord.fromMap(r, r['id']?.toString() ?? '');
      }
      return InvestorSubRecord(id: '', amount: 0, date: DateTime.now());
    }).where((r) => r.id.isNotEmpty).toList();

    return Investor(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      investAmount: (data['investAmount'] ?? data['initialInvestedAmount'] ?? 0.0).toDouble(),
      date: parseDate(data['date'] ?? data['investmentDate']),
      profitShare: (data['profitShare'] ?? data['profitSharePercentage'] ?? data['ownershipPercentage'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      note: data['note'] ?? data['notes'] ?? '',
      withdrawals: withdrawals,
      reinvestments: reinvestments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'investAmount': investAmount,
      'date': date.toIso8601String(),
      'profitShare': profitShare,
      'status': status,
      'note': note,
      'withdrawals': withdrawals.map((w) => w.toMap()).toList(),
      'reinvestments': reinvestments.map((r) => r.toMap()).toList(),
    };
  }

  Investor copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    double? investAmount,
    DateTime? date,
    double? profitShare,
    String? status,
    String? note,
    List<InvestorSubRecord>? withdrawals,
    List<InvestorSubRecord>? reinvestments,
  }) {
    return Investor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      investAmount: investAmount ?? this.investAmount,
      date: date ?? this.date,
      profitShare: profitShare ?? this.profitShare,
      status: status ?? this.status,
      note: note ?? this.note,
      withdrawals: withdrawals ?? this.withdrawals,
      reinvestments: reinvestments ?? this.reinvestments,
    );
  }
}

// Retain legacy class definition if used in older code/tests
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
