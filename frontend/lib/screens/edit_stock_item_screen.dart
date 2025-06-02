// lib/screens/edit_stock_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Corrigido: Usar caminhos de pacote relativos se estiver na mesma lib
// ou package:nome_pacote/ se estiverem em locais diferentes dentro de lib
import '/models/stock_item.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';
import '/utils/app_prefs.dart';
import 'package:image_picker/image_picker.dart';

class EditStockItemScreen extends StatefulWidget {
  final int storeId;
  final StockItem? initialItem;

  const EditStockItemScreen({
    required this.storeId,
    super.key, // Usa super.key
    this.initialItem
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
  late TextEditingController _categoryController; // Controller dedicado para categoria
  final Map<String, TextEditingController> _propControllers = {}; // Para OUTROS campos dinâmicos

  File? _selectedImageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool get _isEditing => widget.initialItem != null;

  // Preferências
  List<String> _activeProperties = [];
  int _quantityDecimals = 0;

  @override
  void initState() {
    super.initState();
    // Inicializa controllers dedicados ANTES de carregar preferências
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _categoryController = TextEditingController();
    // Carrega preferências e inicializa controllers com valores
    _loadPreferencesAndSetupControllers();
    _currentImageUrl = widget.initialItem?.imageUrl;
    // Garante token no ApiService ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureApiServiceToken());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose(); // Dispose do controller de categoria
    _propControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadPreferencesAndSetupControllers() async {
    // Carrega preferências
    _activeProperties = await AppPrefs.getItemProperties();
    _quantityDecimals = await AppPrefs.getQuantityDecimals();

    // Define valores iniciais para controllers dedicados
    _nameController.text = widget.initialItem?.name ?? '';
    final initialQuantity = widget.initialItem?.quantity ?? 0.0;
    _quantityController.text = initialQuantity.toStringAsFixed(_quantityDecimals);
    if (_activeProperties.contains(AppPrefs.propCategory)) {
      _categoryController.text = widget.initialItem?.properties[AppPrefs.propCategory]?.toString() ?? '';
    }

    // Configura controllers para OUTRAS propriedades dinâmicas
    _setupDynamicControllers();

    // Atualiza a UI se o widget ainda estiver montado
    if (mounted) setState(() {});
  }

  void _setupDynamicControllers() {
    // Limpa controllers antigos (exceto os dedicados)
    _propControllers.forEach((_, controller) => controller.dispose());
    _propControllers.clear();

    // Cria controllers para propriedades ativas que NÃO SÃO nome, quantidade, imagem ou categoria
    for (String propKey in _activeProperties) {
      if (propKey != AppPrefs.propName &&
          propKey != AppPrefs.propQuantity &&
          propKey != AppPrefs.propImage &&
          propKey != AppPrefs.propCategory) // Pula categoria também
      {
        String initialValue = '';
        if (_isEditing && widget.initialItem?.properties.containsKey(propKey) == true) {
          initialValue = widget.initialItem!.properties[propKey]?.toString() ?? '';
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
                  title: const Text('Tirar Foto (Câmera)'),
                  onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.camera); }),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.gallery); },
              ),
              // Opção de remover aparece se houver imagem local ou remota
              if (_selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remover Imagem', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    if (mounted) setState(() { _selectedImageFile = null; _currentImageUrl = null; });
                    Navigator.of(ctx).pop();
                    // TODO: Implementar deleção da imagem no backend (ainda pendente)
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
    // Validação do formulário
    if (formState == null || !formState.validate() || _isLoading) {
      debugPrint("Formulário inválido ou salvamento em progresso.");
      return;
    }
    if (!_ensureApiServiceToken()) {
      _showErrorSnackbar("Erro: Usuário não autenticado.");
      return;
    }

    setState(() => _isLoading = true);

    // Processa quantidade
    final normalizedQuantity = _quantityController.text.replaceAll(',', '.');
    final double quantity = double.tryParse(normalizedQuantity) ?? 0.0;

    // Monta o objeto 'properties'
    final Map<String, dynamic> properties = {};
    // Adiciona Categoria (se ativa)
    if (_activeProperties.contains(AppPrefs.propCategory)) {
      final categoryValue = _categoryController.text.trim();
      properties[AppPrefs.propCategory] = categoryValue.isNotEmpty ? categoryValue : null;
      debugPrint("Salvando Categoria em properties: ${properties[AppPrefs.propCategory]}");
    } else {
     debugPrint("Categoria NÃO está ativa nas preferências.");
    }
    // Adiciona outras propriedades dinâmicas
    _propControllers.forEach((key, controller) {
      if (_activeProperties.contains(key)) { // Re-checa se está ativa
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          if (key == AppPrefs.propMinStock) { // Exemplo de conversão numérica
            properties[key] = double.tryParse(value);
          } else {
            properties[key] = value;
          }
        } else {
          properties[key] = null; // Define como null se campo for limpo
        }
      }
    });

    try {
      StockItem itemToSave;
      StockItem? savedItem; // Nullable para o resultado da API

      if (_isEditing) {
        // Atualiza item existente
        itemToSave = widget.initialItem!.copyWith(
          name: _nameController.text.trim(),
          quantity: quantity,
          properties: properties, // Passa o Map completo
        );
        savedItem = await _apiService.updateStockItem(widget.storeId, itemToSave.id, itemToSave);
      } else {
        // Cria novo item
        itemToSave = StockItem(
            id: 0, // Backend gera o ID
            storeId: widget.storeId,
            name: _nameController.text.trim(),
            quantity: quantity,
            properties: properties); // Passa o Map completo
        savedItem = await _apiService.createStockItem(widget.storeId, itemToSave);
      }

      // Upload da imagem (se selecionada E o item foi salvo/criado com sucesso)
      if (_selectedImageFile != null) {
        debugPrint("Enviando imagem selecionada para o item ID: ${savedItem.id}");
        final itemWithImage = await _apiService.uploadImage(widget.storeId, savedItem.id, _selectedImageFile!);
        savedItem = itemWithImage; // Atualiza com a resposta do upload
      }
      // Lógica para remoção de imagem (se imagem foi removida localmente durante edição)
      else if (_isEditing && _currentImageUrl == null && _selectedImageFile == null) {
        // TODO: Chamar API para remover imagem do item ID: ${savedItem.id}
        debugPrint("TODO: Chamar API para remover imagem do item ID: ${savedItem.id}");
      }

      // Se chegou aqui sem erro, a operação foi bem-sucedida
      if (mounted) {
        Navigator.pop(context, true); // Retorna true para sinalizar sucesso
      }
    } catch (e) {
      // Mostra erro se qualquer passo falhar
      if (mounted) { _showErrorSnackbar("Erro ao salvar item: $e"); }
    } finally {
      // Garante que o loading seja desativado
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
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o item "${widget.initialItem!.name}"? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir'),
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

  // --- Funções SnackBar ---
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
  // _showSuccessSnackbar removida

  @override
  Widget build(BuildContext context) {
    // Mostra loading inicial apenas se as propriedades ainda não foram carregadas
    // e não estiver já em estado de loading por outra ação
    if (_activeProperties.isEmpty && !_isLoading) {
      return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? 'Editar Item' : 'Adicionar Item')),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Item' : 'Adicionar Item'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[700],
              tooltip: 'Excluir Item',
              onPressed: _isLoading ? null : _deleteItem,
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Salvar Item',
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
                                  }
                                : null,
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                                ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600])
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(child: Text('Toque para alterar a imagem', style: TextStyle(color: Colors.grey, fontSize: 12))),
                      const SizedBox(height: 24),
                    ],

                    // --- Campos Obrigatórios ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome do Produto*'),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Nome é obrigatório.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantidade*'),
                      keyboardType: TextInputType.numberWithOptions(decimal: _quantityDecimals > 0, signed: false),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,' + _quantityDecimals.toString() + r'}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Insira a quantidade.';
                        final normalizedValue = value.replaceAll(',', '.');
                        if (double.tryParse(normalizedValue) == null) return 'Número inválido.';
                        if (double.parse(normalizedValue) < 0) return 'Quantidade não pode ser negativa.';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                     // --- Campo Categoria (se ativo) ---
                     if (_activeProperties.contains(AppPrefs.propCategory)) ...[
                         TextFormField(
                            controller: _categoryController, // Usa o controller dedicado
                            decoration: InputDecoration(
                                labelText: _getPropertyDisplayName(AppPrefs.propCategory), // Usa helper
                                prefixIcon: _getPropertyIcon(AppPrefs.propCategory), // Usa helper
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            // Validação opcional
                          ),
                          const SizedBox(height: 16),
                     ],


                    // --- Campos Dinâmicos (Outros) ---
                    ..._activeProperties
                        .where((key) => _propControllers.containsKey(key)) // Itera sobre os controllers criados
                        .map((propKey) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _propControllers[propKey],
                          decoration: InputDecoration(
                            labelText: _getPropertyDisplayName(propKey),
                            prefixIcon: _getPropertyIcon(propKey),
                          ),
                          keyboardType: _getPropertyKeyboardType(propKey),
                          // Define o último campo dinâmico para ter ação 'done'
                          textInputAction: (propKey == _activeProperties.lastWhere((k) => _propControllers.containsKey(k), orElse: () => ''))
                                              ? TextInputAction.done
                                              : TextInputAction.next,
                          // Submete o form se for o último campo
                          onFieldSubmitted: (propKey == _activeProperties.lastWhere((k) => _propControllers.containsKey(k), orElse: () => ''))
                                               ? (_) => _saveItem()
                                               : null,
                          // Adicionar validações específicas aqui se necessário
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // --- Overlay de Loading ---
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha((255 * 0.4).round()),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- Helper para obter o ImageProvider correto ---
  ImageProvider<Object>? _getImageProvider() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return NetworkImage(_currentImageUrl!);
    }
    return null;
  }

  // --- Helpers para Campos Dinâmicos ---
  String _getPropertyDisplayName(String key) {
    switch (key) {
      case AppPrefs.propCategory: return 'Categoria';
      case AppPrefs.propBarcode: return 'Código de Barras';
      case AppPrefs.propDescription: return 'Descrição';
      case AppPrefs.propTags: return 'Tags (separadas por vírgula)';
      case AppPrefs.propUom: return 'Unidade (kg, L, pç)';
      case AppPrefs.propMinStock: return 'Estoque Mínimo';
      default: return key; // Retorna a chave se não houver nome mapeado
    }
  }
  Icon? _getPropertyIcon(String key) {
    switch (key) {
      case AppPrefs.propCategory: return const Icon(Icons.category_outlined);
      case AppPrefs.propBarcode: return const Icon(Icons.qr_code_scanner);
      case AppPrefs.propDescription: return const Icon(Icons.description_outlined);
      case AppPrefs.propTags: return const Icon(Icons.sell_outlined);
      case AppPrefs.propUom: return const Icon(Icons.square_foot_outlined);
      case AppPrefs.propMinStock: return const Icon(Icons.warning_amber_outlined);
      default: return null; // Sem ícone por padrão
    }
  }
  TextInputType _getPropertyKeyboardType(String key) {
    switch (key) {
      case AppPrefs.propBarcode: return TextInputType.text;
      case AppPrefs.propMinStock: return const TextInputType.numberWithOptions(decimal: true, signed: false);
      // Adicionar outros tipos conforme necessário
      default: return TextInputType.text; // Padrão texto
    }
  }

} // Fim da classe _EditStockItemScreenState