import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String type; // 'sale', 'purchase', 'expense', 'product_add', 'product_update', 'product_delete', 'backup', 'auth'
  final String title;
  final String description;
  final DateTime timestamp;
  final String? performedBy;

  ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    DateTime? timestamp,
    this.performedBy,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ActivityLog.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ActivityLog(
      id: documentId,
      type: data['type'] ?? 'info',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: parseDate(data['timestamp'] ?? data['createdAt']),
      performedBy: data['performedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'performedBy': performedBy,
    };
  }
}
