import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'Super Admin (Owner)', 'Manager', 'Staff'
  final String approvalStatus; // 'approved', 'pending', 'rejected'
  final String deviceName;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Staff',
    this.approvalStatus = 'pending',
    this.deviceName = 'Mobile Device',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isApproved => approvalStatus == 'approved';
  bool get isOwner => role.contains('Owner') || role.contains('Super Admin');
  bool get isManager => role == 'Manager';
  bool get isStaff => role == 'Staff';

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Staff',
      approvalStatus: data['approvalStatus'] ?? 'pending',
      deviceName: data['deviceName'] ?? 'Device',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'approvalStatus': approvalStatus,
      'deviceName': deviceName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? approvalStatus,
    String? deviceName,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      deviceName: deviceName ?? this.deviceName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
