// frontend/lib/screens/edit_document_screen.dart
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "/models/document_model.dart";
import "/models/document_item_model.dart";
import "/models/stock_item.dart";
import "/models/customer_model.dart";
import "/models/supplier_model.dart";
import "/providers/document_provider.dart";
import "/providers/stock_provider.dart";
import "/providers/customer_provider.dart";
import "/providers/supplier_provider.dart";
import "/providers/store_provider.dart";
import "/providers/auth_provider.dart"; // ★★★ IMPORT ADICIONADO ★★★
import "/services/api_service.dart";

class EditDocumentScreen extends StatefulWidget {
  const EditDocumentScreen({super.key});

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  DocumentType _selectedType = DocumentType.ENTRADA;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  final _notesController = TextEditingController();

  final List<DocumentItem> _items = [];
  bool _isLoadingInitialData = true;
  bool _isSaving = false;

  StockItem? _selectedStockItem;
  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController(text: "0.00");

  final _addItemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenData();
    });
  }

  Future<void> _initializeScreenData() async {
    if (!mounted) return;
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma loja selecionada."), backgroundColor: Colors.red));
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      return;
    }
    await _loadInitialData(storeId);
  }

  Future<void> _loadInitialData(int storeId) async {
    if (!mounted) return;
    setState(() => _isLoadingInitialData = true);
    String? errorMsg;
    try {
      final stockProvider = context.read<StockProvider>();
      final customerProvider = context.read<CustomerProvider>();
      final supplierProvider = context.read<SupplierProvider>();

      await stockProvider.setStoreIdAndFetchIfNeeded(storeId);
      await customerProvider.setStoreIdAndFetchIfNeeded(storeId);
      await supplierProvider.setStoreIdAndFetchIfNeeded(storeId);

    } catch (e) {
      errorMsg = e.toString();
      debugPrint("[EditDocumentScreen] Erro ao carregar dados iniciais: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
        if (errorMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $errorMsg"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)))
    .then((pickedDate) {
      if (pickedDate == null) return;
      if (mounted) setState(() => _selectedDate = pickedDate);
    });
  }

  void _addItemToList() {
    if (!_addItemFormKey.currentState!.validate()) return;
    if (_selectedStockItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um item."), backgroundColor: Colors.orange));
      return;
    }
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quantidade inválida."), backgroundColor: Colors.orange));
      return;
    }
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preço inválido."), backgroundColor: Colors.orange));
      return;
    }
    if (_items.any((item) => item.itemId == _selectedStockItem!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item já adicionado."), backgroundColor: Colors.orange));
      return;
    }
    if (mounted) {
      setState(() {
        _items.add(DocumentItem(id: 0, documentId: 0, itemId: _selectedStockItem!.id, itemName: _selectedStockItem!.name, quantity: quantity, price: price));
        _selectedStockItem = null;
        _quantityController.text = "1";
        _priceController.text = "0.00";
        _addItemFormKey.currentState?.reset();
      });
    }
    FocusScope.of(context).unfocus();
  }

  void _removeItem(int index) {
    if (mounted) setState(() => _items.removeAt(index));
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adicione pelo menos um item ao documento."), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedType == DocumentType.SAIDA && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um cliente para documentos de saída."), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedType == DocumentType.ENTRADA && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um fornecedor para documentos de entrada."), backgroundColor: Colors.orange));
      return;
    }

    _formKey.currentState!.save();
    if (mounted) setState(() => _isSaving = true);

    final apiService = context.read<ApiService>();
    // ★★★ OBTENDO O TOKEN CORRETAMENTE ★★★
    final authToken = context.read<AuthProvider>().token;
    apiService.setAuthToken(authToken);

    final formattedDate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    final storeId = context.read<StoreProvider>().selectedStoreId!;

    try {
      final document = Document(id: 0, storeId: storeId, type: _selectedType, date: formattedDate, customerId: _selectedCustomer?.id, supplierId: _selectedSupplier?.id, notes: _notesController.text.isEmpty ? null : _notesController.text, status: "ABERTO", createdAt: "", updatedAt: "", items: _items);
      
      final newDoc = await apiService.createDocument(storeId, document);
      if (mounted) {
        context.read<DocumentProvider>().addDocumentToList(newDoc); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento criado com sucesso!"), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao criar documento: $error"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    final stockProvider = context.watch<StockProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final supplierProvider = context.watch<SupplierProvider>();

    if (storeId == null && !_isLoadingInitialData) {
      return Scaffold(appBar: AppBar(title: const Text("Criar Documento")), body: const Center(child: Text("Loja não selecionada.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Criar Documento"), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _isSaving || _isLoadingInitialData ? null : _saveDocument)]),
      body: _isLoadingInitialData
          ? const Center(child: CircularProgressIndicator())
          : _isSaving
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<DocumentType>(value: _selectedType, decoration: const InputDecoration(labelText: "Tipo de Documento*"), items: DocumentType.values.where((t) => t != DocumentType.UNKNOWN).map((type) => DropdownMenuItem(value: type, child: Text(documentTypeToString(type)))).toList(), onChanged: (value) { if (value != null && mounted) setState(() { _selectedType = value; if (_selectedType != DocumentType.SAIDA) _selectedCustomer = null; if (_selectedType != DocumentType.ENTRADA) _selectedSupplier = null;});}),
                        const SizedBox(height: 10),
                        Row(children: [Expanded(child: Text("Data: ${DateFormat("dd/MM/yyyy").format(_selectedDate)}")), TextButton.icon(icon: const Icon(Icons.calendar_today), label: const Text("Selecionar Data"), onPressed: _presentDatePicker)]),
                        if (_selectedType == DocumentType.SAIDA) DropdownButtonFormField<Customer>(value: _selectedCustomer, decoration: const InputDecoration(labelText: "Cliente*"), items: customerProvider.customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: (value) { if(mounted) setState(() => _selectedCustomer = value);}, validator: (value) => value == null ? "Selecione um cliente" : null),
                        if (_selectedType == DocumentType.ENTRADA) DropdownButtonFormField<Supplier>(value: _selectedSupplier, decoration: const InputDecoration(labelText: "Fornecedor*"), items: supplierProvider.suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (value) { if(mounted) setState(() => _selectedSupplier = value);}, validator: (value) => value == null ? "Selecione um fornecedor" : null),
                        TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: "Observações"), keyboardType: TextInputType.multiline, maxLines: 2),
                        const SizedBox(height: 20), const Divider(), const SizedBox(height: 10),
                        Text("Itens do Documento", style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 10),
                        Card(elevation: 2, margin: const EdgeInsets.symmetric(vertical: 8), child: Padding(padding: const EdgeInsets.all(12.0), child: Form(key: _addItemFormKey, child: Column(children: [
                          DropdownButtonFormField<StockItem>(value: _selectedStockItem, hint: const Text("Selecione um item..."), isExpanded: true, items: stockProvider.items.map((item) => DropdownMenuItem(value: item, child: Text("${item.name} (Disp: ${item.quantity.toStringAsFixed(0)})"))).toList(), onChanged: (value) { if (mounted) setState(() => _selectedStockItem = value); }, validator: (value) => value == null ? "Selecione um item" : null),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(flex: 2, child: TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: "Qtd*", hintText: "1"), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {if(v==null||v.isEmpty)return"Obrigatório";final q=double.tryParse(v.replaceAll(',', '.'));if(q==null||q<=0)return"Inválido";return null;})),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: "Preço*", hintText: "0.00"), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {if(v==null||v.isEmpty)return"Obrigatório";final p=double.tryParse(v.replaceAll(',', '.'));if(p==null||p<0)return"Inválido";return null;}))
                          ]),
                          const SizedBox(height: 12), ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text("Adicionar Item"), onPressed: _addItemToList)
                        ])))),
                        const SizedBox(height: 16), Text("Itens Adicionados (${_items.length})", style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
                        if (_items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum item adicionado ainda.")))
                        else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _items.length, itemBuilder: (ctx, index) { final item = _items[index]; String stockItemName = item.itemName ?? "Item Desconhecido"; try { final stockItem = stockProvider.items.firstWhere((si) => si.id == item.itemId); stockItemName = stockItem.name; } catch (e) {/* Item não encontrado no stockProvider, usa itemName */} return Card(margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(title: Text(stockItemName), subtitle: Text("Qtd: ${item.quantity} × R\$ ${item.price?.toStringAsFixed(2) ?? '0.00'}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(index)))); }),
                        const SizedBox(height: 32), ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text("Salvar Documento"), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: _isSaving || _isLoadingInitialData ? null : _saveDocument),
                      ],
                    ),
                  ),
                ),
    );
  }
}