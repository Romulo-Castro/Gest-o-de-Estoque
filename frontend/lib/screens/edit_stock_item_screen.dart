// lib/screens/edit_stock_item_screen.dart
import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "/models/stock_item.dart";
import "/models/item_group_model.dart"; // Importar modelo de grupo
import "/providers/auth_provider.dart";
import "/providers/item_group_provider.dart"; // Importar provider de grupo
// Para obter storeId
import "/services/api_service.dart";
import "/utils/app_prefs.dart";
import "package:image_picker/image_picker.dart";

class EditStockItemScreen extends StatefulWidget {
  final int storeId;
  final StockItem? initialItem;

  const EditStockItemScreen({
    required this.storeId,
    super.key,
    this.initialItem,
  });

  @override
  State<EditStockItemScreen> createState() => _EditStockItemScreenState();
}

class _EditStockItemScreenState extends State<EditStockItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController; // Mantido por compatibilidade, mas grupo é preferível
  final Map<String, TextEditingController> _propControllers = {};

  // Estado para Grupo de Item
  ItemGroup? _selectedItemGroup;

  File? _selectedImageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  final bool _isInit = true; // Para carregar dados iniciais apenas uma vez
  bool get _isEditing => widget.initialItem != null;

  // Preferências
  List<String> _activeProperties = [];
  int _quantityDecimals = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _categoryController = TextEditingController();
    _loadPreferencesAndSetupControllers();
    _currentImageUrl = widget.initialItem?.imageUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureApiServiceToken();
      // Carregar grupos de itens após o build inicial
      _loadItemGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _propControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadPreferencesAndSetupControllers() async {
    _activeProperties = await AppPrefs.getItemProperties();
    _quantityDecimals = await AppPrefs.getQuantityDecimals();

    _nameController.text = widget.initialItem?.name ?? "";
    final initialQuantity = widget.initialItem?.quantity ?? 0.0;
    _quantityController.text = initialQuantity.toStringAsFixed(_quantityDecimals);

    // Manter categoria por compatibilidade, mas priorizar grupo
    if (_activeProperties.contains(AppPrefs.propCategory)) {
      _categoryController.text = widget.initialItem?.properties[AppPrefs.propCategory]?.toString() ?? "";
    }

    // Configura controllers dinâmicos (exceto os dedicados e grupo)
    _setupDynamicControllers();

    // O grupo será carregado e selecionado em _loadItemGroups

    if (mounted) setState(() {});
  }

  Future<void> _loadItemGroups() async {
    // Acessa o ItemGroupProvider (precisa estar disponível via Provider)
    // Idealmente, injetado ou acessado de forma mais robusta.
    // Assumindo que está disponível no contexto acima desta tela.
    try {
      final groupProvider = Provider.of<ItemGroupProvider>(context, listen: false);
      // Garante que os grupos sejam buscados se ainda não o foram
      if (groupProvider.groups.isEmpty && groupProvider.isLoading == false) {
         await groupProvider.fetchItemGroups();
      }
      // Seleciona o grupo inicial se estiver editando
      if (_isEditing && widget.initialItem?.groupId != null) {
        // Corrigido: Não retornar null no orElse, mas sim encontrar o grupo ou deixar como null
        try {
          _selectedItemGroup = groupProvider.groups.firstWhere(
            (g) => g.id == widget.initialItem!.groupId,
          );
        } catch (e) {
          // Se não encontrar o grupo, deixa como null
          _selectedItemGroup = null;
          debugPrint("Grupo não encontrado: ${widget.initialItem!.groupId}");
        }
      }
      if (mounted) setState(() {}); // Atualiza a UI com os grupos carregados
    } catch (e) {
      debugPrint("Erro ao carregar grupos de itens: $e");
      if (mounted) _showErrorSnackbar("Erro ao carregar grupos de itens.");
    }
  }

  void _setupDynamicControllers() {
    _propControllers.forEach((_, controller) => controller.dispose());
    _propControllers.clear();

    for (String propKey in _activeProperties) {
      if (propKey != AppPrefs.propName &&
          propKey != AppPrefs.propQuantity &&
          propKey != AppPrefs.propImage &&
          propKey != AppPrefs.propCategory && // Pula categoria
          propKey != AppPrefs.propGroupId) // Pula groupId
      {
        String initialValue = "";
        if (_isEditing && widget.initialItem?.properties.containsKey(propKey) == true) {
          initialValue = widget.initialItem!.properties[propKey]?.toString() ?? "";
        }
        _propControllers[propKey] = TextEditingController(text: initialValue);
      }
    }
  }

  bool _ensureApiServiceToken() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) _showErrorSnackbar("Sessão inválida. Faça login novamente.");
      return false;
    }
    _apiService.setAuthToken(token);
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null && mounted) {
        setState(() { _selectedImageFile = File(pickedFile.path); _currentImageUrl = null; });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar("Erro ao selecionar imagem: $e");
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    if (!_activeProperties.contains(AppPrefs.propImage)) {
      _showInfoSnackbar("Gerenciamento de imagens desativado.");
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text("Tirar Foto (Câmera)"),
                  onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.camera); }),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Escolher da Galeria"),
                onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.gallery); },
              ),
              if (_selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Remover Imagem", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    if (mounted) setState(() { _selectedImageFile = null; _currentImageUrl = null; });
                    Navigator.of(ctx).pop();
                    _showInfoSnackbar("Imagem removida localmente. Salve para confirmar.");
                  },
                ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _saveItem() async {
    FocusScope.of(context).unfocus();
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isLoading) {
      return;
    }
    if (!_ensureApiServiceToken()) {
      _showErrorSnackbar("Erro: Usuário não autenticado.");
      return;
    }

    setState(() => _isLoading = true);

    final normalizedQuantity = _quantityController.text.replaceAll(",", ".");
    final double quantity = double.tryParse(normalizedQuantity) ?? 0.0;

    final Map<String, dynamic> properties = {};
    // Categoria (mantida por compatibilidade, mas grupo é preferível)
    if (_activeProperties.contains(AppPrefs.propCategory)) {
      final categoryValue = _categoryController.text.trim();
      properties[AppPrefs.propCategory] = categoryValue.isNotEmpty ? categoryValue : null;
    }
    // Outras propriedades dinâmicas
    _propControllers.forEach((key, controller) {
      if (_activeProperties.contains(key)) {
        final value = controller.text.trim();
        properties[key] = value.isNotEmpty ? value : null; // Simplificado, ajustar tipos se necessário
      }
    });

    try {
      StockItem itemToSave;
      StockItem? savedItem;

      // Usar o ID do grupo selecionado
      final int? groupId = _selectedItemGroup?.id;

      if (_isEditing) {
        itemToSave = widget.initialItem!.copyWith(
          name: _nameController.text.trim(),
          quantity: quantity,
          groupId: groupId,
          properties: properties,
        );
        savedItem = await _apiService.updateStockItem(widget.storeId, itemToSave.id, itemToSave);
      } else {
        itemToSave = StockItem(
          id: 0,
          storeId: widget.storeId,
          name: _nameController.text.trim(),
          quantity: quantity,
          groupId: groupId,
          properties: properties,
          createdAt: "",
          updatedAt: "",
        );
        savedItem = await _apiService.createStockItem(widget.storeId, itemToSave);
      }

      // Upload da imagem (se selecionada)
      if (_selectedImageFile != null) {
        final itemWithImage = await _apiService.uploadImage(widget.storeId, savedItem.id, _selectedImageFile!);
        savedItem = itemWithImage;
      }
      // Remoção de imagem (se desmarcada)
      else if (_isEditing && _currentImageUrl == null && _selectedImageFile == null && widget.initialItem?.imageUrl != null) {
         // Implementação da chamada API para remover imagem do item
         try {
           await _apiService.deleteItemImage(widget.storeId, savedItem.id);
           _showInfoSnackbar("Imagem removida no servidor.");
         } catch (imgError) {
           _showErrorSnackbar("Erro ao remover imagem no servidor: $imgError");
           // Continuar mesmo se a remoção da imagem falhar?
         }
      }

      if (mounted) {
        Navigator.pop(context, true); // Sinaliza sucesso
      }
    } catch (e) {
      if (mounted) { _showErrorSnackbar("Erro ao salvar item: $e"); }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }

  Future<void> _deleteItem() async {
    if (!_isEditing || _isLoading) return;
    if (!_ensureApiServiceToken()) { _showErrorSnackbar("Erro: Usuário não autenticado."); return; }

    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir o item \"${widget.initialItem!.name}\"? Esta ação não pode ser desfeita."),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed && mounted) {
      setState(() => _isLoading = true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Excluindo item..."), duration: Duration(seconds: 5)));
      try {
        await _apiService.deleteStockItem(widget.storeId, widget.initialItem!.id);
        scaffoldMessenger.removeCurrentSnackBar();
        if (mounted) {
          Navigator.pop(context, true); // Sinaliza sucesso
        }
      } catch (e) {
        scaffoldMessenger.removeCurrentSnackBar();
        if (mounted) {
          _showErrorSnackbar("Erro ao excluir item: $e");
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Helper para obter a imagem (local ou remota)
  ImageProvider? _getImageProvider() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      // Adicionar token se necessário para imagens privadas
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Map<String, String>? headers;
      if (token != null) {
        headers = {"Authorization": "Bearer $token"};
      }
      return NetworkImage(_currentImageUrl!, headers: headers);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Acessa o provider de grupos para o dropdown
    final itemGroupProvider = context.watch<ItemGroupProvider>();

    if (_activeProperties.isEmpty && !_isLoading) {
      return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? "Editar Item" : "Adicionar Item")),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Item" : "Adicionar Item"),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[700],
              tooltip: "Excluir Item",
              onPressed: _isLoading ? null : _deleteItem,
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: "Salvar Item",
            onPressed: _isLoading ? null : _saveItem,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --- Seção da Imagem ---
                    if (_activeProperties.contains(AppPrefs.propImage)) ...[
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : () => _showImageSourceActionSheet(context),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getImageProvider(),
                            onBackgroundImageError: (_selectedImageFile == null && _currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                ? (exception, stackTrace) {
                                    debugPrint("Erro ao carregar imagem de rede (Edit): $_currentImageUrl -> $exception");
                                    // Limpar URL se houver erro
                                    if (mounted) {
                                      setState(() {
                                        _currentImageUrl = null;
                                      });
                                    }
                                  }
                                : null,
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Campo de Nome ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome do Item *",
                        hintText: "Ex: Arroz Tipo 1",
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nome é obrigatório";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Campo de Quantidade ---
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: "Quantidade *",
                        hintText: "Ex: 10.5",
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*$')),
                      ],
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Quantidade é obrigatória";
                        }
                        final normalizedValue = value.replaceAll(",", ".");
                        if (double.tryParse(normalizedValue) == null) {
                          return "Quantidade inválida";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Dropdown de Grupo de Item ---
                    DropdownButtonFormField<ItemGroup?>(
                      decoration: const InputDecoration(
                        labelText: "Grupo",
                        hintText: "Selecione um grupo",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      value: _selectedItemGroup,
                      items: [
                        const DropdownMenuItem<ItemGroup?>(
                          value: null,
                          child: Text("Sem grupo"),
                        ),
                        ...itemGroupProvider.groups.map((group) {
                          return DropdownMenuItem<ItemGroup?>(
                            value: group,
                            child: Text(group.name),
                          );
                        }),
                      ],
                      onChanged: _isLoading ? null : (ItemGroup? newValue) {
                        setState(() {
                          _selectedItemGroup = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Campo de Categoria (mantido por compatibilidade) ---
                    if (_activeProperties.contains(AppPrefs.propCategory))
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: "Categoria (opcional)",
                          hintText: "Ex: Alimentos",
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                      ),

                    // --- Campos Dinâmicos ---
                    ..._propControllers.entries.map((entry) {
                      final propKey = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: "$propKey (opcional)",
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                          enabled: !_isLoading,
                        ),
                      );
                    }),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}