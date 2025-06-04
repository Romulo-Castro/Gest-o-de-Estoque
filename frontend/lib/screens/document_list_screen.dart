// frontend/lib/screens/document_list_screen.dart
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "/models/document_model.dart";
import "/providers/document_provider.dart";
import "/providers/store_provider.dart";
import "/screens/edit_document_screen.dart";
import "/screens/document_detail_screen.dart";
import "/widgets/app_drawer.dart";

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  DocumentType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  // int? _currentStoreIdForScreen; // Não é mais necessário rastrear aqui, o provider faz.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialDataLoad();
    });
  }

  // Este método é chamado quando as dependências mudam (ex: StoreProvider notificando)
  // OU quando o widget é inserido na árvore pela primeira vez (após initState).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sempre que as dependências mudarem (ex: StoreProvider notificar uma nova loja),
    // tentamos carregar os dados. O provider internamente decidirá se precisa de uma nova busca.
    _triggerInitialDataLoad();
  }

  // Método unificado para carregar dados
  void _triggerInitialDataLoad() {
    if (!mounted) return;
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    Provider.of<DocumentProvider>(context, listen: false).setStoreIdAndFetchIfNeeded(storeId);
  }


  IconData _getDocIcon(DocumentType type) {
    switch (type) {
      case DocumentType.ENTRADA: return Icons.input;
      case DocumentType.SAIDA: return Icons.output;
      case DocumentType.AJUSTE_ENTRADA: return Icons.add_circle_outline;
      case DocumentType.AJUSTE_SAIDA: return Icons.remove_circle_outline;
      default: return Icons.help_outline;
    }
  }

  Color _getDocColor(DocumentType type, String? status) {
    if (status == "CANCELADO") return Colors.grey;
    switch (type) {
      case DocumentType.ENTRADA:
      case DocumentType.AJUSTE_ENTRADA:
        return Colors.green;
      case DocumentType.SAIDA:
      case DocumentType.AJUSTE_SAIDA:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showFilterDialog() {
    // Salva os valores atuais dos filtros para o caso de o usuário cancelar
    DocumentType? tempSelectedType = _selectedType;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // Permite setState dentro do diálogo
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text("Filtrar Documentos"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tipo de Documento:"),
                  DropdownButton<DocumentType?>(
                    isExpanded: true,
                    value: tempSelectedType,
                    items: [
                      const DropdownMenuItem<DocumentType?>(value: null, child: Text("Todos os Tipos")),
                      ...DocumentType.values.where((t) => t != DocumentType.UNKNOWN).map((type) {
                        return DropdownMenuItem<DocumentType?>(
                          value: type,
                          child: Text(documentTypeToString(type)),
                        );
                      }),
                    ],
                    onChanged: (value) => setDialogState(() => tempSelectedType = value),
                  ),
                  const SizedBox(height: 16),
                  const Text("Data Inicial:"),
                  Row(children: [ /* ... como antes, usando tempStartDate ... */
                    Expanded(child: Text(tempStartDate == null ? "Não definida" : DateFormat("dd/MM/yyyy").format(tempStartDate!))),
                    IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async { final date = await showDatePicker(context: context, initialDate: tempStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (date != null) setDialogState(() => tempStartDate = date); }),
                    if (tempStartDate != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setDialogState(() => tempStartDate = null)),
                  ],),
                  const SizedBox(height: 16),
                  const Text("Data Final:"),
                  Row(children: [ /* ... como antes, usando tempEndDate ... */
                    Expanded(child: Text(tempEndDate == null ? "Não definida" : DateFormat("dd/MM/yyyy").format(tempEndDate!))),
                    IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async { final date = await showDatePicker(context: context, initialDate: tempEndDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (date != null) setDialogState(() => tempEndDate = date); }),
                    if (tempEndDate != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setDialogState(() => tempEndDate = null)),
                  ],),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
              TextButton(onPressed: () {
                setState(() { // Atualiza os filtros da tela principal
                  _selectedType = tempSelectedType;
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                Navigator.of(ctx).pop();
                _applyFilters();
              }, child: const Text("Aplicar")),
               TextButton(
                onPressed: () {
                  setDialogState(() { // Limpa os filtros temporários do diálogo
                    tempSelectedType = null;
                    tempStartDate = null;
                    tempEndDate = null;
                  });
                   setState(() { // Limpa os filtros da tela principal
                    _selectedType = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.of(context).pop();
                  _applyFilters(); // Reaplica com filtros limpos
                },
                child: const Text("Limpar Filtros", style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyFilters() {
    if (!mounted) return;
    // O storeId já está no DocumentProvider, não precisamos passá-lo aqui explicitamente
    // se o provider já foi configurado com o storeId correto.
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    
    String? startDateStr = _startDate != null ? DateFormat("yyyy-MM-dd").format(_startDate!) : null;
    String? endDateStr = _endDate != null ? DateFormat("yyyy-MM-dd").format(_endDate!) : null;
    
    docProvider.fetchDocumentsWithFilters(
      type: _selectedType,
      startDate: startDateStr,
      endDate: endDateStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStoreId; // Para o check inicial

    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Documentos")),
        drawer: const AppDrawer(),
        body: const Center(child: Text("Por favor, selecione uma loja primeiro.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Documentos"),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), tooltip: "Filtrar Documentos", onPressed: _showFilterDialog),
          Consumer<DocumentProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : _triggerInitialDataLoad, // Chama o método unificado
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<DocumentProvider>(
        builder: (ctx, docProvider, child) {
          if (docProvider.isLoading && docProvider.documents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (docProvider.error != null) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Erro ao carregar documentos: ${docProvider.error}"),
              ElevatedButton(onPressed: _triggerInitialDataLoad, child: const Text("Tentar Novamente")),
            ]));
          }
          if (docProvider.documents.isEmpty) {
            return const Center(child: Text("Nenhum documento encontrado."));
          }
          return ListView.builder(
            itemCount: docProvider.documents.length,
            itemBuilder: (ctx, index) {
              final doc = docProvider.documents[index];
              final formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date));
              final color = _getDocColor(doc.type, doc.status);
              return ListTile(
                leading: Icon(_getDocIcon(doc.type), color: color),
                title: Text("#${doc.id} - ${documentTypeToString(doc.type)}"),
                subtitle: Text("Data: $formattedDate ${doc.status != null ? "- ${doc.status}" : ""}"),
                trailing: doc.status == "CANCELADO"
                    ? const Icon(Icons.cancel, color: Colors.grey)
                    : IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: "Cancelar Documento",
                        onPressed: () async {
                          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("Confirmar Cancelamento"), content: Text("Tem certeza que deseja cancelar o documento #${doc.id}? Isso reverterá os movimentos de estoque associados."), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Não")), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sim, Cancelar", style: TextStyle(color: Colors.red)))],));
                          if (confirm == true && mounted) {
                            try {
                              await context.read<DocumentProvider>().cancelDocument(doc.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento cancelado!"), backgroundColor: Colors.green));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao cancelar: $e"), backgroundColor: Colors.red));
                            }
                          }
                        },
                      ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => DocumentDetailScreen(documentId: doc.id))),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const EditDocumentScreen())),
      ),
    );
  }
}