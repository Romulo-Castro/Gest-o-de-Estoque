// lib/models/stock_item.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';

class StockItem {
  final int id;
  final int storeId; // <-- ADICIONADO
  String name;
  double quantity; // <-- Mudado para double
  // category foi movido para properties
  Map<String, dynamic> properties; // Para campos dinâmicos
  String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockItem({
    required this.id,
    required this.storeId, // <-- ADICIONADO
    required this.name,
    required this.quantity,
    required this.properties, // Recebe o Map
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
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
      storeId: json['store_id'] is String ? int.tryParse(json['store_id']) ?? 0 : json['store_id'] ?? 0, // <-- ADICIONADO
      name: json['name'] ?? 'Nome Indisponível',
      // Tenta parsear quantity como double (vem como REAL do SQLite)
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0, // <-- Mudado para double
      properties: parsedProperties, // Usa o Map parseado
      // imageUrl é construído pela API, image_filename vem do DB
      imageUrl: json['imageUrl'], // Recebe a URL completa construída
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  // Usado para enviar dados para criar/atualizar
   Map<String, dynamic> toJson() {
    return {
      // id e storeId geralmente não são enviados no corpo (vão na URL)
      'name': name,
      'quantity': quantity, // Envia como double
      'properties': properties, // Envia o Map diretamente (será stringificado pelo jsonEncode)
      // imageFilename é tratado separadamente
    };
  }

  // copyWith para facilitar updates
  StockItem copyWith({
    int? id,
    int? storeId,
    String? name,
    double? quantity,
    Map<String, dynamic>? properties,
    String? imageUrl, // Usar Optional<String> ou similar para diferenciar nulo de não mudança
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      properties: properties ?? this.properties, // Cuidado: isso substitui, não mescla
      // Para mesclar: properties: {...this.properties, ...?properties},
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}