// lib/providers/store_provider.dart
import 'package:flutter/foundation.dart';
import '/models/store_model.dart';
import '/services/api_service.dart';
import '/utils/app_prefs.dart';

class StoreProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _isLoading = false;
  String? _error;

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  int? get selectedStoreId => _selectedStore?.id;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StoreProvider() {
    debugPrint("StoreProvider inicializado.");
    // Não busca nada aqui, espera o token
  }

  // Chamado pelo ProxyProvider
  void updateAuthToken(String? authToken) {
    debugPrint("[StoreProvider] updateAuthToken chamado com token ${authToken != null ? 'presente' : 'nulo'}.");
    final bool wasLoggedIn = _apiService.token != null; // Verifica se já tinha token
    _apiService.setAuthToken(authToken); // Define token no serviço interno

    if (authToken != null) {
      // Usuário logou ou app iniciou com token
      // Só busca se estava deslogado ANTES ou se a lista está vazia
      if (!wasLoggedIn || _stores.isEmpty) {
        debugPrint("[StoreProvider] Token válido detectado. Buscando lojas...");
        fetchStores(); // Busca lojas
        _loadSelectedStorePreference(); // Tenta carregar pref
      } else {
         debugPrint("[StoreProvider] Token já estava definido, não buscando lojas novamente.");
      }
    } else {
      // Usuário deslogou (authToken é null)
      bool changed = false;
      if (_stores.isNotEmpty) { _stores = []; changed = true; }
      if (_selectedStore != null) { _selectedStore = null; changed = true; }
      if (_error != null) { _error = null; changed = true; }
      if (_isLoading) { _isLoading = false; changed = true; }

      // Só notifica se algo mudou
      if (changed) {
        debugPrint("[StoreProvider] Dados limpos devido ao logout.");
        notifyListeners();
      } else {
        debugPrint("[StoreProvider] Logout, mas nenhum estado interno precisou ser alterado.");
      }
    }
  }

  // --- Helpers Internos ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false; // Garante que não está carregando se deu erro
    notifyListeners();
    debugPrint("StoreProvider Error: $errorMsg");
  }

  Future<void> _loadSelectedStorePreference() async {
    final preferredId = await AppPrefs.getSelectedStoreId(); // await
    Store? storeToSelect;

    // Verifica se ainda está montado implicitamente (se for chamado de local seguro)
    if (_stores.isNotEmpty) {
       if (preferredId != null) {
          storeToSelect = _stores.firstWhere((s) => s.id == preferredId, orElse: () => _stores.first);
       } else {
           storeToSelect = _stores.first;
       }
    } else {
        storeToSelect = null;
    }

    // Só atualiza e notifica se a seleção realmente mudou
    if (_selectedStore?.id != storeToSelect?.id) {
       _selectedStore = storeToSelect;
       // Salva a nova seleção (ou null)
       await AppPrefs.setSelectedStoreId(_selectedStore?.id); // await
       debugPrint("StoreProvider: Seleção de loja definida como ID ${_selectedStore?.id}");
       notifyListeners(); // Notifica a mudança na seleção
    } else {
        debugPrint("StoreProvider: Seleção de loja permaneceu ID ${_selectedStore?.id}");
    }
  }

  // --- Ações Públicas ---
  Future<void> fetchStores() async {
    if (_apiService.token == null) return; // Sai se não autenticado
    _setLoading(true);
    try {
      _stores = await _apiService.fetchUserStores(); // await
      debugPrint("StoreProvider: Lojas carregadas: ${_stores.length}");
      // Atualiza a seleção após carregar (já notifica se mudar)
      await _loadSelectedStorePreference(); // await
    } catch (e) {
      _setError(e.toString());
      _stores = [];
      _selectedStore = null; // Garante limpeza em caso de erro
    } finally {
       // Garante que loading termine se não houve erro ou mudança de seleção
       if (_isLoading) _setLoading(false);
    }
  }

  Future<void> selectStore(Store store) async {
    if (_selectedStore?.id == store.id) return;
    _selectedStore = store;
    await AppPrefs.setSelectedStoreId(store.id);
    debugPrint("StoreProvider: Loja selecionada manualmente: ${store.name} (ID: ${store.id})");
    notifyListeners();
  }

  Future<Store> createStore(String name, String? address) async {
    if (_apiService.token == null) throw Exception("Usuário não autenticado.");
    _setLoading(true);
    try {
      final newStore = await _apiService.createStore(name, address ?? ''); // await
      // Recarrega TUDO para consistência (inclui seleção)
      await fetchStores(); // await (já gerencia loading e notificação)
      return newStore; // Retorna a loja criada
    } catch (e) {
      _setError(e.toString()); // Define erro (já notifica e para loading)
      rethrow;
    } finally {
        // Garante que loading termine se fetchStores falhar
        if(_isLoading) _setLoading(false);
    }
  }

  Future<Store> updateStore(int storeId, String name, String? address) async {
    if (_apiService.token == null) throw Exception("Usuário não autenticado.");
    _setLoading(true);
    try {
      final updatedStore = await _apiService.updateStore(storeId, name, address ?? ''); // await
      final index = _stores.indexWhere((s) => s.id == storeId);
      if (index != -1) _stores[index] = updatedStore;
      if (_selectedStore?.id == storeId) _selectedStore = updatedStore;
      _isLoading = false; // Termina loading ANTES de notificar
      notifyListeners(); // Notifica UI
      return updatedStore;
    } catch (e) {
      _setError(e.toString()); // Define erro e notifica
      rethrow;
    }
    // Finally não estritamente necessário se try/catch cobrem _setLoading(false)
  }

  Future<void> deleteStore(int storeId) async {
    if (_apiService.token == null) throw Exception("Usuário não autenticado.");
    _setLoading(true);
    try {
      await _apiService.deleteStore(storeId); // await
      _stores.removeWhere((s) => s.id == storeId);

      // Se a excluída era a selecionada, recarrega a preferência
      if (_selectedStore?.id == storeId) {
        debugPrint("StoreProvider: Loja selecionada ($storeId) excluída. Recarregando seleção...");
        // _loadSelectedStorePreference já chama notifyListeners se seleção mudar
        await _loadSelectedStorePreference(); // await
      }
      debugPrint("StoreProvider: Loja ($storeId) excluída.");
       _isLoading = false; // Termina loading antes da notificação final (se houver)
       // Notifica que a lista mudou (ou a seleção mudou via _loadSelected)
       notifyListeners();

    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
        // Garante que loading termine
       if (_isLoading) _setLoading(false);
    }
  }
}