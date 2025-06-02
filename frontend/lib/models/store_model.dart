// lib/models/store_model.dart
class Store {
  final int id;
  final String name;
  final String? address; // Pode ser nulo
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Nome Indisponível',
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  // toJson pode ser útil para criar/atualizar
   Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}