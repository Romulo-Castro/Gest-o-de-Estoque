// lib/screens/edit_store_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/store_model.dart';
import '/providers/store_provider.dart';

class EditStoreScreen extends StatefulWidget {
  final Store? initialStore;

  const EditStoreScreen({super.key, this.initialStore});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  bool get _isEditing => widget.initialStore != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialStore?.name ?? '');
    _addressController = TextEditingController(text: widget.initialStore?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveStore() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final storeProvider = context.read<StoreProvider>();
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    try {
      if (_isEditing) {
        await storeProvider.updateStore(widget.initialStore!.id, name, address.isNotEmpty ? address : null); // Passa null se vazio
      } else {
        await storeProvider.createStore(name, address.isNotEmpty ? address : null); // Passa null se vazio
      }

      // ★★★ VERIFICAÇÃO mounted ANTES DE NAVEGAR ★★★
      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar loja: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
       // ★★★ VERIFICAÇÃO mounted ANTES DE setState ★★★
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Loja' : 'Adicionar Loja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Salvar',
            onPressed: _isLoading ? null : _saveStore,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector( // Para esconder teclado
             onTap: () => FocusScope.of(context).unfocus(),
             child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome da Loja*'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Endereço (Opcional)', hintText: "Rua, número, cidade..."),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _saveStore(),
                      maxLines: 3, // Permite múltiplas linhas para endereço
                    ),
                    const SizedBox(height: 30),
                    // Botão de salvar foi para AppBar
                  ],
                ),
              ),
                     ),
          ),
           // --- Overlay de Loading ---
           if (_isLoading)
             Container(
               color: Colors.black.withAlpha(100), // Fundo mais suave
               child: const Center(child: CircularProgressIndicator()),
             ),
        ],
      ),
    );
  }
}