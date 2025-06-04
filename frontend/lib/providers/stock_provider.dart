// frontend/lib/providers/stock_provider.dart
import "package:flutter/foundation.dart";
import "/models/stock_item.dart";
import "/services/api_service.dart";

class StockProvider with ChangeNotifier {
  final ApiService _apiService; // Será inicializado pelo ProxyProvider
  int? _storeId;
  String? _authToken;

  List<StockItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<StockItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StockProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  void updateAuthToken(String? token) {
    _authToken = token;
    _apiService.setAuthToken(token);
    debugPrint("[StockProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
    if (_storeId != null) {
      fetchStockItems(); // Recarrega se o token mudou e uma loja está selecionada
    }
  }

  // Método seguro para definir storeId e buscar dados se necessário
  Future<void> setStoreIdAndFetchIfNeeded(int? newStoreId) async {
    if (newStoreId == null) {
      _storeId = null;
      _items = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      debugPrint("[StockProvider] Store ID nulo, itens limpos.");
      return;
    }

    final bool storeChanged = _storeId != newStoreId;
    if (storeChanged || _items.isEmpty) {
      _storeId = newStoreId;
      await fetchStockItems();
      debugPrint("[StockProvider] setStoreIdAndFetchIfNeeded: Loja definida para $newStoreId e itens buscados.");
    } else {
      debugPrint("[StockProvider] setStoreIdAndFetchIfNeeded: Loja $newStoreId já estava selecionada e itens carregados.");
    }
  }
  
  void clearItems() {
    _items = [];
    _isLoading = false;
    _error = null;
    _storeId = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading && _error == null && loading == false) return;
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false;
    _items = [];
    notifyListeners();
    debugPrint("StockProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchStockItems() async {
    if (_storeId == null || _storeId! <= 0) {
      _items = [];
      _setError("ID da loja inválido para buscar itens.");
      return;
    }
    if (_authToken == null) {
      _items = [];
      _setError("Usuário não autenticado para buscar itens.");
      return;
    }
    _setLoading(true);
    try {
      _items = await _apiService.fetchStockItems(_storeId!);
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (_error == null) {
        _setLoading(false);
      }
    }
  }

  // ... (createStockItem, updateStockItem, deleteStockItem como antes, mas assegure-se que usam _authToken e _storeId)
  // Exemplo para createStockItem:
  Future<StockItem> createStockItem(StockItem item) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    // _setLoading(true); // Loading da tela de edição é mais apropriado
    try {
      final newItem = await _apiService.createStockItem(_storeId!, item);
      _items.add(newItem); // Adiciona à lista local
      // _isLoading = false;
      notifyListeners(); // Notifica para atualizar a lista na StockScreen, por exemplo
      return newItem;
    } catch (e) {
      // _setError(e.toString()); // Erro deve ser tratado na tela
      rethrow;
    }
  }
  // Adapte updateStockItem e deleteStockItem similarmente
}