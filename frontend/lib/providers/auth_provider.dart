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
  // Removido _isAuthenticated daqui, será derivado diretamente do token
  // bool _isAuthenticated = false;
  bool _isLoading = true; // Inicia como true para cobrir auto-login
  String? _authError;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  // isAuthenticated agora é um getter que verifica se o token existe
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  AuthProvider() {
    _tryAutoLogin();
  }

  // Método centralizado para atualizar o estado e notificar
  void _updateAuthState({
    String? token,
    Map<String, dynamic>? userData,
    bool isLoading = false, // Por padrão, não está carregando após uma atualização
    String? error,
  }) {
    _token = token;
    _userData = userData;
    _isLoading = isLoading;
    _authError = error;

    // Se houver token, atualiza o token no ApiService
    _apiService.setAuthToken(_token);

    notifyListeners(); // Notifica todas as mudanças de uma vez
    debugPrint("AuthProvider: Estado atualizado -> isAuthenticated: $isAuthenticated, isLoading: $_isLoading, error: $_authError, token: ${_token != null ? 'presente' : 'ausente'}");
  }


  Future<void> _tryAutoLogin() async {
    // O estado inicial _isLoading = true já cobre isso.
    // Não precisamos de setStateLoading aqui
    // _updateAuthState(isLoading: true); // Removido para evitar notificação inicial extra se não houver mudança

    final storedToken = await _storage.read(key: 'jwt_token');
    final storedUserDataString = await _storage.read(key: 'user_data');
    String? loadedToken;
    Map<String, dynamic>? loadedUserData;

    if (storedToken != null && storedUserDataString != null) {
      try {
        loadedToken = storedToken;
        loadedUserData = jsonDecode(storedUserDataString) as Map<String, dynamic>;
        debugPrint("Auto login: Dados carregados do storage.");
      } catch (e) {
        debugPrint("Erro ao decodificar user_data do storage: $e. Limpando storage.");
        await _storage.delete(key: 'jwt_token');
        await _storage.delete(key: 'user_data');
        // loadedToken e loadedUserData permanecem nulos
      }
    } else {
       debugPrint("Nenhum token/usuário armazenado para auto login.");
    }

    // Atualiza o estado uma vez no final, com isLoading: false
    _updateAuthState(
      token: loadedToken,
      userData: loadedUserData,
      isLoading: false, // Auto login terminou
      error: null
    );
  }

  Future<bool> login(String email, String password) async {
    _updateAuthState(isLoading: true, error: null); // Inicia o loading, limpa erro anterior

    try {
      final response = await _apiService.login(email, password);
      final apiToken = response['token'] as String?;
      final apiUserData = response['user'] as Map<String, dynamic>?;

      if (apiToken != null && apiUserData != null) {
        await _storage.write(key: 'jwt_token', value: apiToken);
        await _storage.write(key: 'user_data', value: jsonEncode(apiUserData));
        // Atualiza estado com sucesso, isLoading será false
        _updateAuthState(token: apiToken, userData: apiUserData, isLoading: false, error: null);
        return true;
      } else {
        // Atualiza estado com falha, isLoading será false
        _updateAuthState(isLoading: false, error: "Resposta inesperada do servidor (token ou usuário ausente).");
        return false;
      }
    } catch (e) {
      // Atualiza estado com falha, isLoading será false
      _updateAuthState(isLoading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _updateAuthState(isLoading: true, error: null);
    try {
      await _apiService.register(name, email, password);
      debugPrint("Registro na API bem-sucedido. Usuário precisa fazer login.");
      // Após registro bem-sucedido, não logamos o usuário automaticamente
      // O estado de autenticação não muda, mas o loading termina e erro é limpo.
      _updateAuthState(isLoading: false, error: null);
      return true;
    } catch (e) {
      _updateAuthState(isLoading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<void> logout() async {
    // Opcional: indicar loading durante o logout se houver chamadas async
    // _updateAuthState(isLoading: true);

    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_data');
    // Limpa o estado de autenticação e notifica
    _updateAuthState(token: null, userData: null, isLoading: false, error: null);
    // await _apiService.logout(); // Chamar API backend se existir
    debugPrint("Usuário deslogado.");
  }
}