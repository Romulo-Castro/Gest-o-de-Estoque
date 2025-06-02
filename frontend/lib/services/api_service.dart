// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert'; // Necessário para jsonEncode/Decode
import 'dart:io'; // Necessário para File
import 'package:flutter/foundation.dart'; // Necessário para debugPrint
import 'package:http/http.dart' as http;
// Corrija os caminhos de import conforme a estrutura do seu projeto
import '/models/stock_item.dart';
import '/models/store_model.dart';
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

  // --- Helper para Tratar Respostas HTTP ---
  dynamic _handleResponse(http.Response response, {bool expectBody = true}) {
    final int statusCode = response.statusCode;
    // Log mais útil: URL e Status
    debugPrint("API Response: $statusCode <- ${response.request?.method} ${response.request?.url}");
     // Log do corpo apenas se houver erro ou em debug extremo
     // if (statusCode < 200 || statusCode >= 300) {
     //    debugPrint("API Response Body: ${response.body}");
     // }

    if (statusCode >= 200 && statusCode < 300) {
      // Sucesso (2xx)
      if (!expectBody || response.body.isEmpty) {
        return null; // OK para DELETE (204) ou respostas sem corpo
      }
      try {
        // Tenta decodificar JSON
        return jsonDecode(response.body);
      } catch (e) {
        // Se a resposta deveria ter corpo mas não é JSON válido
        debugPrint("API Error: Falha ao decodificar JSON. Body: ${response.body}");
        throw Exception("Resposta inválida do servidor (não JSON).");
      }
    } else {
      // Erros (4xx, 5xx)
      String message = "Erro desconhecido ($statusCode)"; // Mensagem padrão
      try {
        // Tenta extrair a mensagem de erro do corpo JSON (se houver)
        var decodedBody = jsonDecode(response.body);
        message = decodedBody['message'] ?? (decodedBody['error'] ?? message);
      } catch (_) {
         // Se o corpo não for JSON ou não tiver 'message'/'error', usa o corpo como mensagem (se não for muito longo)
          message = response.body.length < 200 ? response.body : message;
      }

      // Log do erro
      debugPrint("API Error $statusCode: $message");

       // Tratar 401/403 especificamente se necessário (ex: deslogar usuário)
       // if (statusCode == 401 || statusCode == 403) { ... }

      // Lança uma exceção com a mensagem tratada
      throw Exception(message);
    }
  }

  // --- Helper para Tratar Erros de Conexão/Timeout/Formato ---
  Exception _handleError(Object error) {
    if (error is SocketException) {
      debugPrint("Erro de Rede (SocketException): $error");
      return Exception("Erro de conexão. Verifique sua internet e o endereço da API.");
    } else if (error is TimeoutException) {
      debugPrint("Timeout: $error");
      return Exception("Tempo limite da requisição excedido.");
    } else if (error is http.ClientException) {
      debugPrint("Erro de Cliente HTTP: $error");
      return Exception("Erro de comunicação com o servidor.");
    }
    // Se já for uma Exception (provavelmente vinda de _handleResponse), repassa
    else if (error is Exception) {
      return error;
    }
    // Outros erros inesperados
    else {
      debugPrint("Erro desconhecido na API: $error");
      return Exception("Ocorreu um erro inesperado: $error");
    }
  }
} // Fim da classe ApiService