// frontend/lib/models/item_group_model.dart
import "package:flutter/foundation.dart";

@immutable
class ItemGroup {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final String createdAt;
  final String updatedAt;

  const ItemGroup({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemGroup.fromJson(Map<String, dynamic> json) {
    return ItemGroup(
      id: json["id"] as int,
      storeId: json["store_id"] as int,
      name: json["name"] as String,
      description: json["description"] as String?,
      createdAt: json["created_at"] as String,
      updatedAt: json["updated_at"] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "store_id": storeId,
        "name": name,
        "description": description,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };

  ItemGroup copyWith({
    int? id,
    int? storeId,
    String? name,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return ItemGroup(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

