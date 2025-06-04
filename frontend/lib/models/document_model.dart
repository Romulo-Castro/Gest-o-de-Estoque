// frontend/lib/models/document_model.dart
import "package:flutter/foundation.dart";
import "/models/document_item_model.dart"; // Importar o modelo do item

// Enum para tipos de documento (melhor que strings soltas)
enum DocumentType {
  ENTRADA,
  SAIDA,
  AJUSTE_ENTRADA,
  AJUSTE_SAIDA,
  UNKNOWN // Para casos inesperados
}

String documentTypeToString(DocumentType type) {
  switch (type) {
    case DocumentType.ENTRADA:
      return "ENTRADA";
    case DocumentType.SAIDA:
      return "SAIDA";
    case DocumentType.AJUSTE_ENTRADA:
      return "AJUSTE_ENTRADA";
    case DocumentType.AJUSTE_SAIDA:
      return "AJUSTE_SAIDA";
    default:
      return "UNKNOWN";
  }
}

DocumentType stringToDocumentType(String? typeStr) {
  switch (typeStr) {
    case "ENTRADA":
      return DocumentType.ENTRADA;
    case "SAIDA":
      return DocumentType.SAIDA;
    case "AJUSTE_ENTRADA":
      return DocumentType.AJUSTE_ENTRADA;
    case "AJUSTE_SAIDA":
      return DocumentType.AJUSTE_SAIDA;
    default:
      debugPrint("Tipo de documento desconhecido recebido: $typeStr");
      return DocumentType.UNKNOWN;
  }
}

@immutable
class Document {
  final int id;
  final int storeId;
  final DocumentType type;
  final String date; // Manter como String por simplicidade, converter na UI se necessário
  final int? customerId;
  final int? supplierId;
  final String? notes;
  final String? status; // Ex: "ABERTO", "PROCESSADO", "CANCELADO"
  final String createdAt;
  final String updatedAt;
  final List<DocumentItem>? items; // Lista de itens (pode ser null inicialmente)

  const Document({
    required this.id,
    required this.storeId,
    required this.type,
    required this.date,
    this.customerId,
    this.supplierId,
    this.notes,
    this.status,
    required this.createdAt,
    required this.updatedAt,
    this.items, // Adicionado
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    // Tratar a lista de itens se presente no JSON
    List<DocumentItem>? parsedItems;
    if (json["items"] != null && json["items"] is List) {
      parsedItems = (json["items"] as List)
          .map((itemJson) => DocumentItem.fromJson(itemJson as Map<String, dynamic>))
          .toList();
    }

    return Document(
      id: json["id"] as int,
      storeId: json["store_id"] as int,
      type: stringToDocumentType(json["type"] as String?),
      date: json["date"] as String,
      customerId: json["customer_id"] as int?,
      supplierId: json["supplier_id"] as int?,
      notes: json["notes"] as String?,
      status: json["status"] as String?, // Ler o status
      createdAt: json["created_at"] as String,
      updatedAt: json["updated_at"] as String,
      items: parsedItems, // Usar a lista parseada
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "store_id": storeId,
        "type": documentTypeToString(type),
        "date": date,
        "customer_id": customerId,
        "supplier_id": supplierId,
        "notes": notes,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
        // Não incluir itens aqui geralmente, eles são enviados separadamente na criação/edição
      };

  // CopyWith para facilitar atualizações imutáveis
  Document copyWith({
    int? id,
    int? storeId,
    DocumentType? type,
    String? date,
    int? customerId,
    int? supplierId,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
    List<DocumentItem>? items,
  }) {
    return Document(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

