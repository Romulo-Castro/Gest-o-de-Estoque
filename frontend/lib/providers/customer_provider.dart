// frontend/lib/providers/customer_provider.dart
import "package:flutter/foundation.dart";
import "/models/customer_model.dart";
import "/services/api_service.dart";

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _authToken;
  int? _storeId;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  void updateAuthToken(String? token) {
    _authToken = token;
    _apiService.setAuthToken(token);
    debugPrint("[CustomerProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
    if (_storeId != null && _authToken != null) { // Só busca se tiver loja e token
      fetchCustomers();
    } else if (_authToken == null) {
      clearCustomers(); // Limpa se o token for removido
    }
  }

  Future<void> setStoreIdAndFetchIfNeeded(int? newStoreId) async {
    if (newStoreId == null) {
      _storeId = null;
      _customers = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      debugPrint("[CustomerProvider] Store ID nulo, clientes limpos.");
      return;
    }

    final bool storeChanged = _storeId != newStoreId;
    if (storeChanged || _customers.isEmpty) { // Só busca se a loja mudou ou se a lista está vazia
      _storeId = newStoreId;
      await fetchCustomers(); // fetchCustomers já trata _isLoading e notifyListeners
      debugPrint("[CustomerProvider] setStoreIdAndFetchIfNeeded: Loja definida para $newStoreId e clientes buscados.");
    } else {
      debugPrint("[CustomerProvider] setStoreIdAndFetchIfNeeded: Loja $newStoreId já estava selecionada e clientes carregados.");
    }
  }
  
  void clearCustomers() {
    _customers = [];
    _isLoading = false;
    _error = null;
    _storeId = null; // Limpa o storeId também
    notifyListeners();
    debugPrint("[CustomerProvider] Clientes e storeId limpos.");
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
    _customers = []; // Limpa em caso de erro
    notifyListeners();
    debugPrint("CustomerProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchCustomers() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar clientes.");
      return;
    }
    if (_authToken == null) {
      _setError("Usuário não autenticado para buscar clientes.");
      return;
    }
    _setLoading(true);
    try {
      _customers = await _apiService.fetchCustomers(_storeId!);
      _error = null; // Limpa erro anterior em caso de sucesso
    } catch (e) {
      _setError(e.toString());
    } finally {
      // _setLoading(false) é chamado por _setError ou aqui se não houver erro
      if (_error == null) {
        _setLoading(false);
      }
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    // Idealmente, a tela de edição lida com seu próprio _isLoading para o save
    try {
      final newCustomer = await _apiService.createCustomer(_storeId!, customer);
      // Opcional: Adicionar à lista local e notificar, ou confiar no fetchCustomers da tela de lista
      // _customers.add(newCustomer);
      // notifyListeners();
      await fetchCustomers(); // Recarrega a lista após criar
      return newCustomer;
    } catch (e) {
      rethrow;
    }
  }

  Future<Customer> updateCustomer(int customerId, Customer customer) async {
     if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
     if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      final updatedCustomer = await _apiService.updateCustomer(_storeId!, customerId, customer);
      // final index = _customers.indexWhere((c) => c.id == customerId);
      // if (index != -1) {
      //   _customers[index] = updatedCustomer;
      // }
      // notifyListeners();
      await fetchCustomers(); // Recarrega a lista após atualizar
      return updatedCustomer;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      await _apiService.deleteCustomer(_storeId!, customerId);
      // _customers.removeWhere((c) => c.id == customerId);
      // notifyListeners();
      await fetchCustomers(); // Recarrega a lista após deletar
    } catch (e) {
      rethrow;
    }
  }
}