// frontend/lib/models/document_item_model.dart
import "package:flutter/foundation.dart";

@immutable
class DocumentItem {
  final int id;
  final int documentId;
  final int itemId;
  final double quantity;
  final double? price; // Renomeado de unitPrice para price conforme usado no frontend
  final String? itemName; // Adicionado para compatibilidade com o frontend

  const DocumentItem({
    required this.id,
    required this.documentId,
    required this.itemId,
    required this.quantity,
    this.price,
    this.itemName,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json["id"] as int,
      documentId: json["document_id"] as int,
      itemId: json["item_id"] as int,
      quantity: (json["quantity"] as num).toDouble(),
      price: json["unit_price"] != null ? (json["unit_price"] as num).toDouble() : null,
      itemName: json["item_name"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "document_id": documentId,
        "item_id": itemId,
        "quantity": quantity,
        "unit_price": price,
        "item_name": itemName,
      };

  // CopyWith para facilitar atualizações imutáveis
  DocumentItem copyWith({
    int? id,
    int? documentId,
    int? itemId,
    double? quantity,
    double? price,
    String? itemName,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      itemName: itemName ?? this.itemName,
    );
  }
}
