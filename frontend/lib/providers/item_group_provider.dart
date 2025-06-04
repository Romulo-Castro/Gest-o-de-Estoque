// frontend/lib/providers/item_group_provider.dart
import "package:flutter/foundation.dart";
import "/models/item_group_model.dart";
import "/services/api_service.dart";

class ItemGroupProvider with ChangeNotifier {
  final ApiService _apiService;
  int? _storeId;

  List<ItemGroup> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<ItemGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Construtor padrão para uso com ProxyProvider
  ItemGroupProvider() : _apiService = ApiService(), _storeId = null;

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[ItemGroupProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    if (storeId != null && storeId > 0) {
      fetchItemGroups();
    } else {
      _groups = [];
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false;
    notifyListeners();
    debugPrint("ItemGroupProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchItemGroups() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar grupos.");
      return;
    }
    _setLoading(true);
    try {
      _groups = await _apiService.fetchItemGroups(_storeId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _groups = [];
    }
  }

  Future<ItemGroup> createItemGroup(String name, {String? description, int? parentGroupId}) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      // Criar objeto ItemGroup para passar ao ApiService
      final group = ItemGroup(
        id: 0, // ID será atribuído pelo backend
        storeId: _storeId!,
        name: name,
        description: description,
        createdAt: "",
        updatedAt: "",
      );
      
      final newGroup = await _apiService.createItemGroup(_storeId!, group);
      _groups.add(newGroup);
      _isLoading = false;
      notifyListeners();
      return newGroup;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<ItemGroup> updateItemGroup(int groupId, String name, {String? description, int? parentGroupId}) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      // Encontrar o grupo existente
      final existingGroup = _groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw Exception("Grupo não encontrado"),
      );
      
      // Criar objeto atualizado
      final group = existingGroup.copyWith(
        name: name,
        description: description,
      );
      
      final updatedGroup = await _apiService.updateItemGroup(_storeId!, groupId, group);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
      }
      _isLoading = false;
      notifyListeners();
      return updatedGroup;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteItemGroup(int groupId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      await _apiService.deleteItemGroup(_storeId!, groupId);
      _groups.removeWhere((g) => g.id == groupId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
}
