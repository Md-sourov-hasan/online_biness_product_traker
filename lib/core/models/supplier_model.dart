class Supplier {
  final String id;
  final String name;
  final String contactPhone;
  final String email;
  final String address;
  final String status; // 'active', 'inactive'
  final String notes;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactPhone = '',
    this.email = '',
    this.address = '',
    this.status = 'active',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Supplier.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Supplier(
      id: id,
      name: data['name'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      status: data['status'] ?? 'active',
      notes: data['notes'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPhone': contactPhone,
      'email': email,
      'address': address,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPhone,
    String? email,
    String? address,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPhone: contactPhone ?? this.contactPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
