// ============================================
// SERVICIO DE AUTENTICACIÓN
// ============================================

import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // ========== LOGIN ==========
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {
          'correo': email,
          'contrasena': password,
        },
      );

      // Guardar token y datos del usuario
      if (response['success'] == true) {
        final token = response['token'];
        final userData = response['data'];

        await _saveToken(token);
        await _saveUserData(userData);
        _apiService.setToken(token);

        return response;
      } else {
        throw Exception(response['message'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========== REGISTER ==========
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? career,
    String? university,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        {
          'nombre': name,
          'correo': email,
          'contrasena': password,
          'carrera': career,
          'universidad': university ?? 'Universidad de Córdoba',
        },
      );

      // Guardar token y datos del usuario
      if (response['success'] == true) {
        final token = response['token'];
        final userData = response['data'];

        await _saveToken(token);
        await _saveUserData(userData);
        _apiService.setToken(token);

        return response;
      } else {
        throw Exception(response['message'] ?? 'Error al registrarse');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    await _removeToken();
    await _removeUserData();
    _apiService.clearToken();
  }

  // ========== VERIFICAR SI ESTÁ AUTENTICADO ==========
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // ========== OBTENER PERFIL ==========
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.profile);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ========== GUARDAR TOKEN ==========
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ========== OBTENER TOKEN ==========
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ========== ELIMINAR TOKEN ==========
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ========== GUARDAR DATOS DE USUARIO ==========
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }

  // ========== OBTENER DATOS DE USUARIO ==========
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    
    if (userDataString != null) {
      // Aquí deberías parsear el string a Map
      // Por simplicidad, retornamos null por ahora
      return null;
    }
    return null;
  }

  // ========== ELIMINAR DATOS DE USUARIO ==========
  Future<void> _removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ========== CARGAR TOKEN AL INICIAR ==========
  Future<void> loadToken() async {
    final token = await getToken();
    if (token != null) {
      _apiService.setToken(token);
    }
  }
}