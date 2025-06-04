// frontend/lib/models/customer_model.dart
import 'package:flutter/foundation.dart';

@immutable
class Customer {
  final int id;
  final int storeId;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const Customer({
    required this.id,
    required this.storeId,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  // CopyWith para facilitar atualizações imutáveis
  Customer copyWith({
    int? id,
    int? storeId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

