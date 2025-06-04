// frontend/lib/screens/edit_item_group_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/models/item_group_model.dart";
import "/providers/item_group_provider.dart";
import "/providers/store_provider.dart"; // Para obter o storeId

class EditItemGroupScreen extends StatefulWidget {
  final int? groupId; // Null para adicionar, preenchido para editar

  const EditItemGroupScreen({super.key, this.groupId});

  @override
  State<EditItemGroupScreen> createState() => _EditItemGroupScreenState();
}

class _EditItemGroupScreenState extends State<EditItemGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = true;
  ItemGroup? _initialGroupData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.groupId != null) {
        _loadGroupData();
      }
      _isInit = false;
    }
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    if (storeId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Erro: Loja não selecionada."), backgroundColor: Colors.red),
       );
       setState(() { _isLoading = false; });
       Navigator.of(context).pop();
       return;
    }

    try {
      // Busca o grupo na lista do provider
      final provider = Provider.of<ItemGroupProvider>(context, listen: false);
      _initialGroupData = provider.groups.firstWhere((g) => g.id == widget.groupId);

      _nameController.text = _initialGroupData!.name;
      _descriptionController.text = _initialGroupData!.description ?? "";
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar grupo: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final groupProvider = Provider.of<ItemGroupProvider>(context, listen: false);

    try {
      if (widget.groupId == null) {
        // Criar novo grupo
        await groupProvider.createItemGroup(
          _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grupo criado com sucesso!"), backgroundColor: Colors.green),
        );
      } else {
        // Atualizar grupo existente
        await groupProvider.updateItemGroup(
          widget.groupId!,
          _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grupo atualizado com sucesso!"), backgroundColor: Colors.green),
        );
      }
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar grupo: $error"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
         setState(() {
           _isLoading = false;
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId == null ? "Adicionar Grupo" : "Editar Grupo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nome*"),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nome é obrigatório.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: "Descrição"),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Salvar Grupo"),
                        onPressed: _saveForm,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

