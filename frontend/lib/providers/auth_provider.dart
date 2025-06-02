// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/services/api_service.dart'; // Ajuste o caminho

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _userData;
  bool _isAuthenticated = false;
  bool _isLoading = true; // Inicia como true para cobrir auto-login
  String? _authError;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  AuthProvider() {
    _tryAutoLogin();
  }

  void _setStateLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (loading) _authError = null;
    notifyListeners();
  }

  void _setAuthData(String? token, Map<String, dynamic>? userData) {
    _token = token;
    _userData = userData;
    _isAuthenticated = token != null;
    _authError = null;
    _apiService.setAuthToken(token);
    notifyListeners(); // Notifica que o estado de auth mudou
  }

  void _clearAuthData() {
    _token = null;
    _userData = null;
    _isAuthenticated = false;
    _apiService.setAuthToken(null);
    // Não precisa de 'await' aqui se não precisarmos esperar a deleção
    _storage.delete(key: 'jwt_token');
    _storage.delete(key: 'user_data');
    notifyListeners(); // Notifica sobre o logout
  }

  Future<void> _tryAutoLogin() async {
    // Não usa setStateLoading aqui para evitar piscar na tela inicial
    // O estado inicial _isLoading = true cobre isso.
    final storedToken = await _storage.read(key: 'jwt_token');
    final storedUserDataString = await _storage.read(key: 'user_data');
    bool loggedIn = false;

    if (storedToken != null && storedUserDataString != null) {
      try {
        // ★★★ IMPORTANTE: Aqui não usamos setState diretamente, então não precisa de 'mounted' ★★★
        // Apenas preparamos os dados para _setAuthData
        _token = storedToken;
        _userData = jsonDecode(storedUserDataString);
        _isAuthenticated = true;
        _apiService.setAuthToken(storedToken);
        loggedIn = true;
        debugPrint("Auto login: Dados carregados.");
      } catch (e) {
        debugPrint("Erro ao decodificar user_data do storage: $e");
        // Limpa dados inválidos (sem await necessário aqui)
        _clearAuthData(); // Isso vai notificar
      }
    } else {
       _isAuthenticated = false;
       debugPrint("Nenhum token/usuário armazenado para auto login.");
    }

    // Atualiza o estado de loading e notifica APENAS UMA VEZ no final
    _isLoading = false;
    if (!loggedIn && isAuthenticated) {
      _isAuthenticated = false; // Corrige estado se o parse falhou e limpou dados
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setStateLoading(true); // Notifica início do loading
    bool success = false; // Flag de sucesso
    try {
      final response = await _apiService.login(email, password); // await
      final token = response['token'];
      final userData = response['user'];

      if (token != null && userData != null) {
        // ★★★ IMPORTANTE: Não usamos setState aqui, não precisa de 'mounted' ★★★
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
        _setAuthData(token, userData); // Chama método que notifica
        success = true;
      } else {
        _authError = "Resposta inesperada do servidor.";
        _isAuthenticated = false;
        // Não precisa notificar aqui, finally fará isso
      }
    } catch (e) {
      _authError = e.toString();
      _isAuthenticated = false;
      // Não precisa notificar aqui, finally fará isso
    } finally {
      // Garante que loading termine e estado seja notificado uma vez
      _isLoading = false;
      notifyListeners();
    }
    return success; // Retorna o resultado
  }

  Future<bool> register(String name, String email, String password) async {
    _setStateLoading(true); // Notifica início do loading
    bool success = false;
    try {
      // Chama API, não espera token/user de volta neste fluxo
      await _apiService.register(name, email, password); // await
      _authError = null;
      // NÃO define _isAuthenticated = true aqui
      debugPrint("Registro na API bem-sucedido. Usuário precisa fazer login.");
      success = true; // Indica sucesso na API
    } catch (e) {
      _authError = e.toString();
      _isAuthenticated = false; // Garante deslogado
    } finally {
       // Garante que loading termine e estado seja notificado uma vez
      _isLoading = false;
      notifyListeners(); // Notifica sobre erro ou fim do loading
    }
    return success; // Retorna se a chamada API foi ok
  }

  Future<void> logout() async {
    // _setStateLoading(true); // Opcional
    _clearAuthData(); // Limpa dados e notifica
    // await _apiService.logout(); // Chamar API backend se existir
    // _setStateLoading(false); // Opcional
    debugPrint("Usuário deslogado.");
  }
}