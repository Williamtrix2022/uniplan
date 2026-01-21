// ============================================
// SERVICIO BASE DE API
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Setear token de autenticación
  void setToken(String token) {
    _token = token;
  }

  // Obtener token
  String? get token => _token;

  // Limpiar token (logout)
  void clearToken() {
    _token = null;
  }

  // ========== GET REQUEST ==========
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = ApiConfig.getHeaders(token: _token);

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== POST REQUEST ==========
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = ApiConfig.getHeaders(token: _token);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== PUT REQUEST ==========
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = ApiConfig.getHeaders(token: _token);

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== PATCH REQUEST ==========
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = ApiConfig.getHeaders(token: _token);

      final response = await http.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== DELETE REQUEST ==========
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = ApiConfig.getHeaders(token: _token);

      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== MANEJAR RESPUESTA ==========
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Decodificar JSON
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body);
    } catch (e) {
      throw ApiException('Error al procesar respuesta del servidor');
    }

    // Verificar código de estado
    if (statusCode >= 200 && statusCode < 300) {
      return data;
    } else if (statusCode == 401) {
      throw ApiException('No autorizado. Por favor inicia sesión nuevamente.');
    } else if (statusCode == 403) {
      throw ApiException('No tienes permisos para realizar esta acción.');
    } else if (statusCode == 404) {
      throw ApiException('Recurso no encontrado.');
    } else if (statusCode >= 500) {
      throw ApiException('Error del servidor. Intenta más tarde.');
    } else {
      final message = data['message'] ?? 'Error desconocido';
      throw ApiException(message);
    }
  }

  // ========== MANEJAR ERRORES ==========
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error.toString().contains('SocketException')) {
      return ApiException('Sin conexión a internet');
    } else if (error.toString().contains('TimeoutException')) {
      return ApiException('Tiempo de espera agotado');
    } else {
      return ApiException('Error de red: ${error.toString()}');
    }
  }
}

// ========== EXCEPCIÓN PERSONALIZADA ==========
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}