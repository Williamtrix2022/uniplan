// ============================================
// SERVICIO DE AUTENTICACIÓN
// ============================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // El token de sesión y los datos del usuario se guardan cifrados
  // (Keychain en iOS, EncryptedSharedPreferences en Android) en vez de
  // SharedPreferences en texto plano.
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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

  // ========== FORGOT PASSWORD ==========
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.forgotPassword,
        {
          'correo': email,
        },
      );

      if (response['success'] == true) {
        return response;
      }

      throw Exception(response['message'] ?? 'Error al solicitar recuperación');
    } catch (e) {
      rethrow;
    }
  }

  // ========== RESET PASSWORD ==========
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.resetPassword,
        {
          'correo': email,
          'token': token,
          'nuevaContrasena': newPassword,
        },
      );

      if (response['success'] == true) {
        return response;
      }

      throw Exception(response['message'] ?? 'Error al restablecer contraseña');
    } catch (e) {
      rethrow;
    }
  }

  // ========== CHANGE PASSWORD ==========
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.changePassword,
        body: {
          'contrasenaActual': currentPassword,
          'nuevaContrasena': newPassword,
        },
      );

      if (response['success'] == true) {
        return response;
      }

      throw Exception(response['message'] ?? 'Error al cambiar contraseña');
    } catch (e) {
      rethrow;
    }
  }

  // ========== ACTUALIZAR PERFIL ==========
  Future<Map<String, dynamic>> updateProfile({
    required int id,
    required String name,
    required String career,
    required String university,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.students}/$id',
        {
          'nombre': name,
          'carrera': career,
          'universidad': university,
        },
      );

      if (response['success'] == true) {
        return response;
      }

      throw Exception(response['message'] ?? 'Error al actualizar perfil');
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
    return token != null && token.trim().isNotEmpty;
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

  // ========== OBTENER NOMBRE DEL USUARIO ==========
  Future<String> getUserName() async {
    try {
      final response = await getProfile();
      if (response['success'] == true) {
        final data = response['data'];
        return data['nombre'] ?? 'Usuario';
      }
      return 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  // ========== GUARDAR TOKEN ==========
  Future<void> _saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // ========== OBTENER TOKEN ==========
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  // ========== ELIMINAR TOKEN ==========
  Future<void> _removeToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // ========== GUARDAR DATOS DE USUARIO ==========
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    await _secureStorage.write(key: _userKey, value: userData.toString());
  }

  // ========== OBTENER DATOS DE USUARIO ==========
  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = await _secureStorage.read(key: _userKey);

    if (userDataString != null) {
      // Aquí deberías parsear el string a Map
      // Por simplicidad, retornamos null por ahora
      return null;
    }
    return null;
  }

  // ========== ELIMINAR DATOS DE USUARIO ==========
  Future<void> _removeUserData() async {
    await _secureStorage.delete(key: _userKey);
  }

  // ========== CARGAR TOKEN AL INICIAR ==========
  Future<void> loadToken() async {
    await _migrateFromSharedPreferences();

    final token = await getToken();
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  // ========== MIGRACIÓN DESDE SHAREDPREFERENCES ==========
  // Versiones anteriores guardaban el token en SharedPreferences en texto
  // plano. Si todavía hay algo ahí, se pasa al storage cifrado y se borra
  // el original, para no cerrarle la sesión a quien ya estaba logueado.
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        final alreadyMigrated = await _secureStorage.read(key: _tokenKey);
        if (alreadyMigrated == null) {
          await _secureStorage.write(key: _tokenKey, value: legacyToken);
        }
      }

      if (prefs.containsKey(_tokenKey)) await prefs.remove(_tokenKey);
      if (prefs.containsKey(_userKey)) await prefs.remove(_userKey);
    } catch (_) {
      // Si la migración falla no se rompe el arranque: en el peor caso el
      // usuario vuelve a iniciar sesión.
    }
  }
}
