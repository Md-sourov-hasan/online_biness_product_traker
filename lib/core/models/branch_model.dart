import 'package:flutter/material.dart';

class Branch {
  final String id;
  final String name;
  final String banglaName;
  final String address;
  final String managerName;
  final String managerPhone;
  final String email;
  final int colorValue;
  final String status; // 'active', 'inactive'
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.name,
    this.banglaName = '',
    required this.address,
    this.managerName = 'Branch Manager',
    this.managerPhone = '+880 1700-000000',
    this.email = '',
    this.colorValue = 0xFF2563EB,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);
  bool get isActive => status == 'active';

  factory Branch.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Branch(
      id: documentId.isNotEmpty ? documentId : (data['id'] ?? ''),
      name: data['name'] ?? '',
      banglaName: data['banglaName'] ?? '',
      address: data['address'] ?? '',
      managerName: data['managerName'] ?? 'Branch Manager',
      managerPhone: data['managerPhone'] ?? '+880 1700-000000',
      email: data['email'] ?? '',
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF2563EB,
      status: data['status'] ?? 'active',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'banglaName': banglaName,
      'address': address,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'email': email,
      'colorValue': colorValue,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? banglaName,
    String? address,
    String? managerName,
    String? managerPhone,
    String? email,
    int? colorValue,
    String? status,
    DateTime? createdAt,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      banglaName: banglaName ?? this.banglaName,
      address: address ?? this.address,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      email: email ?? this.email,
      colorValue: colorValue ?? this.colorValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
