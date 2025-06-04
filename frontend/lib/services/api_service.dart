// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert'; // Necessário para jsonEncode/Decode
import 'dart:io'; // Necessário para File
import 'package:flutter/foundation.dart'; // Necessário para debugPrint
import 'package:http/http.dart' as http;
// Corrija os caminhos de import conforme a estrutura do seu projeto
import '/models/stock_item.dart';
import '/models/store_model.dart';
import '/models/customer_model.dart';
import '/models/supplier_model.dart';
import '/models/item_group_model.dart';
import '/models/document_model.dart';
import 'package:mime/mime.dart'; // Para Mime type no upload
import 'package:http_parser/http_parser.dart'; // Para MediaType no upload

class ApiService {
  // Use o IP correto para seu ambiente de teste
  // Emulador Android: 'http://10.0.2.2:3000/api'
  // Dispositivo Físico (mesma rede): 'http://SEU_IP_LOCAL:3000/api'
  // Web: 'http://localhost:3000/api'
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Exemplo para Emulador Android
  String? _token; // Armazena o token JWT localmente no serviço

  // Define/Atualiza o token usado pelo serviço
  void setAuthToken(String? token) {
    _token = token;
    debugPrint("ApiService: Token ${token != null ? 'definido' : 'limpo'}.");
  }

  // Getter para o token (pode ser útil para debug ou lógica externa)
  String? get token => _token;

  // Helper para construir cabeçalhos HTTP padrão
  Map<String, String> _getHeaders({bool requiresAuth = true, bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      // Define o tipo de conteúdo como JSON para POST/PUT
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    // Adiciona o token de autorização se necessário e disponível
    if (requiresAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (requiresAuth && _token == null) {
      // Loga um aviso se uma rota protegida for chamada sem token
      debugPrint("AVISO ApiService: Tentativa de requisição autenticada sem token.");
      // Considerar lançar um erro aqui para interromper a requisição
      // throw Exception("Usuário não autenticado.");
    }
    return headers;
  }

  // --- Métodos de Autenticação ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(requiresAuth: false), // Login não envia token prévio
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response); // Processa a resposta
    } catch (e) {
      throw _handleError(e); // Processa erros
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Lojas (Stores) ---
  Future<List<Store>> fetchUserStores() async {
    final url = Uri.parse('$_baseUrl/stores');
     debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => Store.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Store> createStore(String name, String? address) async { // Address opcional
    final url = Uri.parse('$_baseUrl/stores');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'address': address ?? ''}), // Envia address como string vazia se nulo
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Store.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Store> updateStore(int storeId, String name, String? address) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId');
     debugPrint('API Request: PUT $url');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'address': address ?? ''}),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Store.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteStore(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId');
     debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false); // Verifica apenas o status code
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Itens de Estoque (StockItems) ---
  Future<List<StockItem>> fetchStockItems(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => StockItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<StockItem> createStockItem(int storeId, StockItem item) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock');
    debugPrint('API Request: POST $url');
    try {
      // ★★★ VERIFICAÇÃO CONFIRMADA ★★★
      // item.toJson() é chamado aqui, que deve incluir 'properties'
      final response = await http.post(
        url,
        headers: _getHeaders(), // isJson = true por padrão
        body: jsonEncode(item.toJson()), // Codifica o Map retornado por toJson
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return StockItem.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<StockItem> updateStockItem(int storeId, int itemId, StockItem item) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock/$itemId');
    debugPrint('API Request: PUT $url');
    try {
       // ★★★ VERIFICAÇÃO CONFIRMADA ★★★
       // item.toJson() é chamado aqui, que deve incluir 'properties'
      final response = await http.put(
        url,
        headers: _getHeaders(), // isJson = true por padrão
        body: jsonEncode(item.toJson()), // Codifica o Map retornado por toJson
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return StockItem.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteStockItem(int storeId, int itemId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock/$itemId');
     debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Implementação do método para remover imagem do item
  Future<void> deleteItemImage(int storeId, int itemId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock/$itemId/image');
    debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<StockItem> uploadImage(int storeId, int itemId, File imageFile) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/stock/$itemId/image');
    debugPrint('API Request: POST (Multipart) $url');
    try {
      var request = http.MultipartRequest('POST', url);

      // Adiciona token ao cabeçalho da requisição multipart
      final headers = _getHeaders(isJson: false); // Pega header de auth sem Content-Type JSON
       if (headers.containsKey('Authorization')) {
           request.headers['Authorization'] = headers['Authorization']!;
       } else {
            throw Exception("Usuário não autenticado para upload.");
       }

      // Determina Mime type
      String? mimeType = lookupMimeType(imageFile.path);
      MediaType? contentType;
      if (mimeType != null) {
        var typeParts = mimeType.split('/');
        if (typeParts.length == 2) { contentType = MediaType(typeParts[0], typeParts[1]); }
      }

      // Adiciona o arquivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'productImage', // Nome do campo esperado pelo backend (multer)
          imageFile.path,
          contentType: contentType,
        ),
      );

      // Envia a requisição
      var streamedResponse = await request.send().timeout(const Duration(seconds: 45)); // Timeout maior para upload
      final response = await http.Response.fromStream(streamedResponse);

      // Trata a resposta (que deve ser o item atualizado em JSON)
      Map<String, dynamic> body = _handleResponse(response);
      return StockItem.fromJson(body);

    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Grupos de Itens (ItemGroups) ---
  Future<List<ItemGroup>> fetchItemGroups(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/groups');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => ItemGroup.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ItemGroup> createItemGroup(int storeId, ItemGroup group) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/groups');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(group.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return ItemGroup.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ItemGroup> updateItemGroup(int storeId, int groupId, ItemGroup group) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/groups/$groupId');
    debugPrint('API Request: PUT $url');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(group.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return ItemGroup.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteItemGroup(int storeId, int groupId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/groups/$groupId');
    debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Clientes (Customers) ---
  Future<List<Customer>> fetchCustomers(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/customers');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => Customer.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Customer> createCustomer(int storeId, Customer customer) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/customers');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(customer.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Customer.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Customer> updateCustomer(int storeId, int customerId, Customer customer) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/customers/$customerId');
    debugPrint('API Request: PUT $url');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(customer.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Customer.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteCustomer(int storeId, int customerId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/customers/$customerId');
    debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Fornecedores (Suppliers) ---
  Future<List<Supplier>> fetchSuppliers(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/suppliers');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => Supplier.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Supplier> createSupplier(int storeId, Supplier supplier) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/suppliers');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(supplier.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Supplier.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Supplier> updateSupplier(int storeId, int supplierId, Supplier supplier) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/suppliers/$supplierId');
    debugPrint('API Request: PUT $url');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(supplier.toJson()),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Supplier.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteSupplier(int storeId, int supplierId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/suppliers/$supplierId');
    debugPrint('API Request: DELETE $url');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos de Documentos (Documents) ---
  Future<List<Document>> fetchDocuments(int storeId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/documents');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => Document.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Implementação do método para buscar documentos com filtros
  Future<List<Document>> fetchDocumentsWithFilters(
    int storeId, {
    DocumentType? type,
    String? startDate,
    String? endDate,
    int? customerId,
    int? supplierId,
  }) async {
    // Construir a URL com os parâmetros de consulta
    final queryParams = <String, String>{};
    if (type != null) {
      queryParams['type'] = documentTypeToString(type);
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate;
    }
    if (customerId != null) {
      queryParams['customerId'] = customerId.toString();
    }
    if (supplierId != null) {
      queryParams['supplierId'] = supplierId.toString();
    }

    final url = Uri.parse('$_baseUrl/stores/$storeId/documents').replace(queryParameters: queryParams);
    debugPrint('API Request: GET $url');
    
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      List<dynamic> body = _handleResponse(response);
      return body.map((dynamic item) => Document.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Document> fetchDocumentById(int storeId, int documentId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/documents/$documentId');
    debugPrint('API Request: GET $url');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Document.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Document> createDocument(int storeId, Document document) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/documents');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(document.toJson()),
      ).timeout(const Duration(seconds: 30)); // Timeout maior para documentos com muitos itens
      Map<String, dynamic> body = _handleResponse(response);
      return Document.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Document> updateDocumentHeader(int storeId, int documentId, Map<String, dynamic> headerData) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/documents/$documentId/header');
    debugPrint('API Request: PUT $url');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(headerData),
      ).timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = _handleResponse(response);
      return Document.fromJson(body);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelDocument(int storeId, int documentId) async {
    final url = Uri.parse('$_baseUrl/stores/$storeId/documents/$documentId/cancel');
    debugPrint('API Request: POST $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      _handleResponse(response, expectBody: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Métodos Auxiliares para Tratamento de Respostas e Erros ---
  dynamic _handleResponse(http.Response response, {bool expectBody = true}) {
    final statusCode = response.statusCode;
    final hasBody = response.body.isNotEmpty;

    if (statusCode >= 200 && statusCode < 300) {
      if (expectBody && hasBody) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception("Erro ao decodificar resposta JSON: $e");
        }
      } else if (expectBody && !hasBody) {
        throw Exception("Resposta vazia quando esperava corpo JSON");
      } else {
        return null; // Sucesso sem corpo esperado (ex: DELETE)
      }
    } else {
      // Tenta extrair mensagem de erro do corpo da resposta
      String errorMessage = "Erro HTTP $statusCode";
      if (hasBody) {
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        } catch (_) {
          // Se não conseguir decodificar, usa o corpo bruto
          errorMessage = "Erro HTTP $statusCode: ${response.body}";
        }
      }
      throw Exception(errorMessage);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is TimeoutException) {
      return Exception("Tempo limite excedido. Verifique sua conexão.");
    } else if (error is SocketException) {
      return Exception("Erro de conexão. Verifique sua internet ou o servidor.");
    } else if (error is FormatException) {
      return Exception("Erro de formato na resposta.");
    } else if (error is Exception) {
      return error;
    } else {
      return Exception("Erro desconhecido: $error");
    }
  }
}
