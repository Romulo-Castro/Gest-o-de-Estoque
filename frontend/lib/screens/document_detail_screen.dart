// frontend/lib/screens/document_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/models/document_model.dart';
import '/providers/document_provider.dart';
import '/providers/store_provider.dart';

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;

  const DocumentDetailScreen({
    required this.documentId,
    super.key,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isLoading = true;
  Document? _document;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId == null) {
        throw Exception("Nenhuma loja selecionada");
      }

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final document = await docProvider.fetchDocumentById(widget.documentId);
      
      if (mounted) {
        setState(() {
          _document = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusColor(String? status) {
    if (status == "CANCELADO") return "Cancelado";
    if (status == "PROCESSADO") return "Processado";
    return "Em aberto";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Documento #${widget.documentId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocument,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Erro: $_error"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDocument,
                        child: const Text("Tentar novamente"),
                      ),
                    ],
                  ),
                )
              : _buildDocumentDetails(),
    );
  }

  Widget _buildDocumentDetails() {
    if (_document == null) {
      return const Center(child: Text("Documento não encontrado"));
    }

    final formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.parse(_document!.date));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Documento #${_document!.id}",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text(_getStatusColor(_document!.status)),
                        backgroundColor: _document!.status == "CANCELADO"
                            ? Colors.red[100]
                            : Colors.green[100],
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow("Tipo", documentTypeToString(_document!.type)),
                  _buildInfoRow("Data", formattedDate),
                  if (_document!.customerId != null)
                    _buildInfoRow("Cliente ID", _document!.customerId.toString()),
                  if (_document!.supplierId != null)
                    _buildInfoRow("Fornecedor ID", _document!.supplierId.toString()),
                  if (_document!.notes != null && _document!.notes!.isNotEmpty)
                    _buildInfoRow("Observações", _document!.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Itens do Documento",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _document!.items == null || _document!.items!.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Nenhum item encontrado neste documento."),
                  ),
                )
              : _buildItemsList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _document!.items!.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _document!.items![index];
          return ListTile(
            title: Text(item.itemName ?? "Item #${item.itemId}"),
            subtitle: Text("Quantidade: ${item.quantity}"),
            trailing: Text(
              "R\$ ${(item.price ?? 0).toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
