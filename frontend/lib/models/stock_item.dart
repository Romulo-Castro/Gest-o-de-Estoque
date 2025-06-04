// lib/models/stock_item.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';

class StockItem {
  final int id;
  final int storeId;
  String name;
  double quantity;
  int? groupId; // Adicionado campo groupId
  Map<String, dynamic> properties;
  String? imageUrl;
  final String createdAt;
  final String updatedAt;

  StockItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.quantity,
    required this.properties,
    this.groupId, // Adicionado como parâmetro opcional
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    // Parse das propriedades JSON (se vier como string do DB)
     Map<String, dynamic> parsedProperties = {};
     if (json['properties'] != null) {
        if (json['properties'] is String) {
           try { parsedProperties = jsonDecode(json['properties']); }
           catch(e) { debugPrint("Erro ao parsear properties (string): ${json['properties']}"); }
        } else if (json['properties'] is Map) {
            // Converte chaves/valores para os tipos corretos se necessário
           parsedProperties = Map<String, dynamic>.from(json['properties']);
        }
     }

    return StockItem(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      storeId: json['store_id'] is String ? int.tryParse(json['store_id']) ?? 0 : json['store_id'] ?? 0,
      name: json['name'] ?? 'Nome Indisponível',
      // Tenta parsear quantity como double (vem como REAL do SQLite)
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      groupId: json['group_id'] is String ? int.tryParse(json['group_id']) : json['group_id'], // Adicionado parsing de groupId
      properties: parsedProperties,
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] ?? "",
      updatedAt: json['updatedAt'] ?? "",
    );
  }

  // Usado para enviar dados para criar/atualizar
   Map<String, dynamic> toJson() {
    return {
      // id e storeId geralmente não são enviados no corpo (vão na URL)
      'name': name,
      'quantity': quantity,
      'group_id': groupId, // Adicionado groupId ao JSON
      'properties': properties,
    };
  }

  // copyWith para facilitar updates
  StockItem copyWith({
    int? id,
    int? storeId,
    String? name,
    double? quantity,
    int? groupId, // Adicionado ao copyWith
    Map<String, dynamic>? properties,
    String? imageUrl,
    String? createdAt,
    String? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      groupId: groupId ?? this.groupId, // Adicionado ao construtor
      properties: properties ?? this.properties,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
