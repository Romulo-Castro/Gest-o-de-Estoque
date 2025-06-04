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
  bool _hasFetchedStores = false; // Flag para saber se já buscou lojas

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  int? get selectedStoreId => _selectedStore?.id;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // Novo getter para indicar se buscou e não encontrou lojas
  bool get hasNoStores => _hasFetchedStores && _stores.isEmpty && !_isLoading && _error == null;

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
      // Só busca se estava deslogado ANTES ou se a lista está vazia (ou nunca buscou)
      if (!wasLoggedIn || !_hasFetchedStores) {
        debugPrint("[StoreProvider] Token válido detectado ou primeira inicialização. Buscando lojas...");
        fetchStores(); // Busca lojas e tenta carregar preferência
      } else {
         debugPrint("[StoreProvider] Token já estava definido e lojas já foram buscadas, não buscando novamente.");
         // Garante que a seleção seja carregada se por algum motivo não foi
         if (_selectedStore == null && _stores.isNotEmpty) {
           _loadSelectedStorePreference();
         }
      }
    } else {
      // Usuário deslogou (authToken é null)
      bool changed = false;
      if (_stores.isNotEmpty) { _stores = []; changed = true; }
      if (_selectedStore != null) { _selectedStore = null; changed = true; }
      if (_error != null) { _error = null; changed = true; }
      if (_isLoading) { _isLoading = false; changed = true; }
      if (_hasFetchedStores) { _hasFetchedStores = false; changed = true; } // Reseta flag

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
    if (loading) {
      _error = null;
      _hasFetchedStores = false; // Reseta flag ao iniciar carregamento
    }
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false; // Garante que não está carregando se deu erro
    _hasFetchedStores = true; // Marca que tentou buscar, mesmo com erro
    notifyListeners();
    debugPrint("StoreProvider Error: $errorMsg");
  }

  Future<void> _loadSelectedStorePreference() async {
    final preferredId = await AppPrefs.getSelectedStoreId();
    Store? storeToSelect;

    // Só tenta selecionar se a lista de lojas NÃO estiver vazia
    if (_stores.isNotEmpty) {
       if (preferredId != null) {
          // Tenta encontrar a preferida, senão pega a primeira
          storeToSelect = _stores.firstWhere((s) => s.id == preferredId, orElse: () => _stores.first);
       } else {
           // Se não há preferência salva, seleciona a primeira
           storeToSelect = _stores.first;
       }
    } else {
        // Se a lista está vazia, garante que não há seleção
        storeToSelect = null;
    }

    // Só atualiza e notifica se a seleção realmente mudou
    if (_selectedStore?.id != storeToSelect?.id) {
       _selectedStore = storeToSelect;
       // Salva a nova seleção (ou null)
       await AppPrefs.setSelectedStoreId(_selectedStore?.id);
       debugPrint("StoreProvider: Seleção de loja definida como ID ${_selectedStore?.id}");
       notifyListeners(); // Notifica a mudança na seleção
    } else {
        debugPrint("StoreProvider: Seleção de loja permaneceu ID ${_selectedStore?.id}");
    }
  }

  // --- Ações Públicas ---
  Future<void> fetchStores() async {
    if (_apiService.token == null) {
        debugPrint("StoreProvider: fetchStores chamado sem token, ignorando.");
        return; // Sai se não autenticado
    }
    _setLoading(true);
    try {
      _stores = await _apiService.fetchUserStores();
      _hasFetchedStores = true; // Marca que a busca foi concluída (com ou sem sucesso na lista)
      debugPrint("StoreProvider: Lojas carregadas: ${_stores.length}");
      // Atualiza a seleção após carregar (já notifica se mudar)
      await _loadSelectedStorePreference();
      // Se não houve mudança na seleção, mas o loading precisa terminar
      if (_isLoading) _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _stores = []; // Limpa lojas em caso de erro
      _selectedStore = null; // Garante limpeza da seleção
      // _setError já chama notifyListeners e _setLoading(false)
    } finally {
       // Garante que loading termine se não houve erro ou mudança de seleção
       // e _loadSelectedStorePreference não o fez.
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
      final newStore = await _apiService.createStore(name, address ?? '');
      // Adiciona a nova loja localmente e a seleciona
      _stores.add(newStore);
      await selectStore(newStore); // Seleciona a nova loja e notifica
      _isLoading = false; // Loading termina aqui
      // Não precisa chamar fetchStores completo, apenas adiciona e seleciona
      notifyListeners(); // Garante notificação final
      return newStore;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
        if(_isLoading) _setLoading(false);
    }
  }

  Future<Store> updateStore(int storeId, String name, String? address) async {
    if (_apiService.token == null) throw Exception("Usuário não autenticado.");
    _setLoading(true);
    try {
      final updatedStore = await _apiService.updateStore(storeId, name, address ?? '');
      final index = _stores.indexWhere((s) => s.id == storeId);
      if (index != -1) _stores[index] = updatedStore;
      if (_selectedStore?.id == storeId) _selectedStore = updatedStore;
      _isLoading = false;
      notifyListeners();
      return updatedStore;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteStore(int storeId) async {
    if (_apiService.token == null) throw Exception("Usuário não autenticado.");
    _setLoading(true);
    try {
      await _apiService.deleteStore(storeId);
      _stores.removeWhere((s) => s.id == storeId);

      // Se a excluída era a selecionada, recarrega a preferência/seleciona outra
      if (_selectedStore?.id == storeId) {
        debugPrint("StoreProvider: Loja selecionada ($storeId) excluída. Recarregando seleção...");
        await _loadSelectedStorePreference(); // Tenta selecionar outra
      }
      debugPrint("StoreProvider: Loja ($storeId) excluída.");
       _isLoading = false;
       // Notifica que a lista mudou (ou a seleção mudou via _loadSelected)
       // Se _loadSelected não notificou (pq a seleção não mudou), notifica aqui
       if (!_isLoading) notifyListeners(); // Garante notificação se _loadSelected não o fez

    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
       if (_isLoading) _setLoading(false);
    }
  }
}