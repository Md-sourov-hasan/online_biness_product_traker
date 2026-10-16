import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String category;
  final double amount;
  final String notes;
  final DateTime date;
  final String creatorId;
  final String creatorName;
  final String creatorRole;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    this.notes = '',
    DateTime? date,
    this.creatorId = '',
    this.creatorName = 'Staff',
    this.creatorRole = 'Staff',
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Expense(
      id: documentId,
      category: data['category'] ?? 'Others',
      amount: (data['amount'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      date: parseDate(data['date']),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Staff',
      creatorRole: data['creatorRole'] ?? 'Staff',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'notes': notes,
      'date': date.toIso8601String(),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorRole': creatorRole,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? category,
    double? amount,
    String? notes,
    DateTime? date,
    String? creatorId,
    String? creatorName,
    String? creatorRole,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorRole: creatorRole ?? this.creatorRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
