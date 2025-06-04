// frontend/lib/providers/document_provider.dart
import "package:flutter/foundation.dart";
import "/models/document_model.dart";
import "/services/api_service.dart";

class DocumentProvider with ChangeNotifier {
  final ApiService _apiService;
  int? _storeId;
  String? _authToken;

  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DocumentProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  void updateAuthToken(String? token) {
    final bool tokenChanged = _authToken != token;
    _authToken = token;
    _apiService.setAuthToken(token);
    debugPrint("[DocumentProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
    if (tokenChanged && _storeId != null) { // Recarrega se o token mudou e temos uma loja
      fetchDocuments();
    } else if (token == null) {
      clearDocuments(); // Limpa se o token for nulo
    }
  }

  Future<void> setStoreIdAndFetchIfNeeded(int? newStoreId) async {
    if (newStoreId == null) {
      if (_storeId != null || _documents.isNotEmpty || _isLoading || _error != null) { // Só notifica se houver mudança real
        _storeId = null;
        _documents = [];
        _error = null;
        _isLoading = false;
        notifyListeners();
        debugPrint("[DocumentProvider] Store ID nulo, documentos limpos.");
      }
      return;
    }

    final bool storeActuallyChanged = _storeId != newStoreId;
    // Só busca se a loja mudou OU se a lista de documentos está vazia e não estamos carregando
    if (storeActuallyChanged || (_documents.isEmpty && !_isLoading)) {
      _storeId = newStoreId;
      debugPrint("[DocumentProvider] setStoreIdAndFetchIfNeeded: Loja definida para $newStoreId. Disparando busca.");
      await fetchDocuments(); // fetchDocuments lida com seu próprio loading e notificação
    } else {
      debugPrint("[DocumentProvider] setStoreIdAndFetchIfNeeded: Loja $newStoreId já estava selecionada (ou carregando) e/ou documentos já carregados.");
    }
  }

  void clearDocuments() {
    if (_documents.isNotEmpty || _isLoading || _error != null || _storeId != null) { // Só notifica se houver mudança real
      _documents = [];
      _isLoading = false;
      _error = null;
      _storeId = null;
      notifyListeners();
      debugPrint("[DocumentProvider] clearDocuments: Documentos e storeId limpos.");
    }
  }

  void _updateState({List<Document>? documents, bool? isLoading, String? error}) {
    bool changed = false;
    if (documents != null && !listEquals(_documents, documents)) { _documents = documents; changed = true; }
    if (isLoading != null && _isLoading != isLoading) { _isLoading = isLoading; changed = true; }
    if (error != null && _error != error) { _error = error; changed = true; } // Pode também limpar o erro se null for passado
    if (error == null && _error != null) { _error = null; changed = true; } // Limpa erro explicitamente


    if (changed) {
      notifyListeners();
    }
  }

  Future<void> fetchDocuments() async {
    if (_storeId == null || _storeId! <= 0) {
      _updateState(documents: [], error: "ID da loja inválido para buscar documentos.", isLoading: false);
      return;
    }
    if (_authToken == null) {
      _updateState(documents: [], error: "Usuário não autenticado para buscar documentos.", isLoading: false);
      return;
    }

    _updateState(isLoading: true, error: null); // Limpa erro ao iniciar
    try {
      final fetchedDocuments = await _apiService.fetchDocuments(_storeId!);
      _updateState(documents: fetchedDocuments, isLoading: false, error: null);
    } catch (e) {
      debugPrint("DocumentProvider Error (Store: $_storeId) em fetchDocuments: $e");
      _updateState(documents: [], error: e.toString(), isLoading: false);
    }
  }

  Future<void> fetchDocumentsWithFilters({
    DocumentType? type, String? startDate, String? endDate, int? customerId, int? supplierId,
  }) async {
    if (_storeId == null || _storeId! <= 0) {
      _updateState(documents: [], error: "ID da loja inválido para filtrar documentos.", isLoading: false);
      return;
    }
    if (_authToken == null) {
      _updateState(documents: [], error: "Usuário não autenticado para filtrar documentos.", isLoading: false);
      return;
    }
    _updateState(isLoading: true, error: null);
    try {
      final fetchedDocuments = await _apiService.fetchDocumentsWithFilters(
        _storeId!, type: type, startDate: startDate, endDate: endDate, customerId: customerId, supplierId: supplierId,
      );
      _updateState(documents: fetchedDocuments, isLoading: false, error: null);
    } catch (e) {
      debugPrint("DocumentProvider Error (Store: $_storeId) em fetchDocumentsWithFilters: $e");
      _updateState(documents: [], error: e.toString(), isLoading: false);
    }
  }

  Future<Document> fetchDocumentById(int documentId) async {
    // ... (código como antes, mas considere um loading local na tela de detalhes)
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      final doc = await _apiService.fetchDocumentById(_storeId!, documentId);
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) { // Atualiza na lista se já estava lá
        _documents[index] = doc;
        notifyListeners(); // Notifica para atualizar a UI da lista, se visível
      }
      return doc;
    } catch (e) {
      debugPrint("Erro ao buscar documento $documentId: $e");
      rethrow;
    }
  }

  Future<Document> createDocument(Document document) async {
    // ... (código como antes)
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    if (document.items?.isEmpty ?? true) throw Exception("Documento deve ter itens.");
    try {
      final newDocument = await _apiService.createDocument(_storeId!, document);
      _documents.insert(0, newDocument);
      notifyListeners();
      return newDocument;
    } catch (e) {
      rethrow;
    }
  }
  
  void addDocumentToList(Document newDoc) {
    if (_documents.any((doc) => doc.id == newDoc.id)) {
      final index = _documents.indexWhere((doc) => doc.id == newDoc.id);
      _documents[index] = newDoc;
    } else {
      _documents.insert(0, newDoc);
    }
    notifyListeners();
    debugPrint("[DocumentProvider] Documento ID ${newDoc.id} adicionado/atualizado na lista local.");
  }


  Future<void> cancelDocument(int documentId) async {
    // ... (código como antes)
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    if (_authToken == null) throw Exception("Usuário não autenticado.");
    try {
      await _apiService.cancelDocument(_storeId!, documentId);
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        _documents[index] = _documents[index].copyWith(status: "CANCELADO");
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}