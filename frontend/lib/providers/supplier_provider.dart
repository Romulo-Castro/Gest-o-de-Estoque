// frontend/lib/providers/supplier_provider.dart
import "package:flutter/foundation.dart";
import "/models/supplier_model.dart";
import "/services/api_service.dart";

class SupplierProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _authToken;
  int? _storeId;

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SupplierProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  void updateAuthToken(String? token) {
    _authToken = token;
    _apiService.setAuthToken(token);
    debugPrint("[SupplierProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
     if (_storeId != null && _authToken != null) {
      fetchSuppliers();
    } else if (_authToken == null) {
      clearSuppliers();
    }
  }

  Future<void> setStoreIdAndFetchIfNeeded(int? newStoreId) async {
    if (newStoreId == null) {
      _storeId = null;
      _suppliers = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      debugPrint("[SupplierProvider] Store ID nulo, fornecedores limpos.");
      return;
    }

    final bool storeChanged = _storeId != newStoreId;
    if (storeChanged || _suppliers.isEmpty) {
      _storeId = newStoreId;
      await fetchSuppliers();
      debugPrint("[SupplierProvider] setStoreIdAndFetchIfNeeded: Loja definida para $newStoreId e fornecedores buscados.");
    } else {
      debugPrint("[SupplierProvider] setStoreIdAndFetchIfNeeded: Loja $newStoreId já estava selecionada e fornecedores carregados.");
    }
  }

  void clearSuppliers() {
    _suppliers = [];
    _isLoading = false;
    _error = null;
    _storeId = null;
    notifyListeners();
     debugPrint("[SupplierProvider] Fornecedores e storeId limpos.");
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
    _suppliers = [];
    notifyListeners();
    debugPrint("SupplierProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchSuppliers() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar fornecedores.");
      return;
    }
    if (_authToken == null) {
      _setError("Usuário não autenticado para buscar fornecedores.");
      return;
    }
    _setLoading(true);
    try {
      _suppliers = await _apiService.fetchSuppliers(_storeId!);
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (_error == null) {
        _setLoading(false);
      }
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      final newSupplier = await _apiService.createSupplier(_storeId!, supplier);
      await fetchSuppliers();
      return newSupplier;
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> updateSupplier(int supplierId, Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      final updatedSupplier = await _apiService.updateSupplier(_storeId!, supplierId, supplier);
      await fetchSuppliers();
      return updatedSupplier;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      await _apiService.deleteSupplier(_storeId!, supplierId);
      await fetchSuppliers();
    } catch (e) {
      rethrow;
    }
  }
}