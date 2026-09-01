// ============================================
// SERVICIO BASE DE API
// ============================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Cliente HTTP. Se puede reemplazar en tests con un MockClient.
  http.Client _client = http.Client();

  @visibleForTesting
  void setHttpClient(http.Client client) {
    _client = client;
  }

  // Callback que intenta refrescar la sesión (lo setea AuthService). Devuelve
  // true si consiguió un access token nuevo. Sin él, un 401 no se reintenta.
  Future<bool> Function()? _refreshCallback;

  // Single-flight: si ya hay un refresh en curso, todas las peticiones que
  // reciban 401 esperan el mismo Future en vez de disparar N refresh.
  Future<bool>? _refreshing;

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

  void setRefreshCallback(Future<bool> Function() callback) {
    _refreshCallback = callback;
  }

  // ========== VERBOS HTTP ==========
  Future<Map<String, dynamic>> get(String endpoint) =>
      _send('GET', endpoint);

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) =>
      _send('POST', endpoint, body: body);

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) =>
      _send('PUT', endpoint, body: body);

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) =>
      _send('PATCH', endpoint, body: body);

  Future<Map<String, dynamic>> delete(String endpoint) =>
      _send('DELETE', endpoint);

  // ========== ENVÍO CON REINTENTO POR 401 ==========
  Future<Map<String, dynamic>> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      var response = await _rawSend(method, url, body: body)
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 401 && _canRefresh(endpoint)) {
        final refreshed = await _runRefresh();
        if (refreshed) {
          response = await _rawSend(method, url, body: body)
              .timeout(ApiConfig.connectionTimeout);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> _rawSend(
    String method,
    Uri url, {
    Map<String, dynamic>? body,
  }) {
    final headers = ApiConfig.getHeaders(token: _token);
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        return _client.get(url, headers: headers);
      case 'POST':
        return _client.post(url, headers: headers, body: encoded);
      case 'PUT':
        return _client.put(url, headers: headers, body: encoded);
      case 'PATCH':
        return _client.patch(url, headers: headers, body: encoded);
      case 'DELETE':
        return _client.delete(url, headers: headers);
      default:
        throw ArgumentError('Método HTTP no soportado: $method');
    }
  }

  // El refresh y el login/registro nunca se reintentan (evita bucles).
  bool _canRefresh(String endpoint) {
    if (_refreshCallback == null) return false;
    return endpoint != ApiConfig.refresh &&
        endpoint != ApiConfig.login &&
        endpoint != ApiConfig.register;
  }

  Future<bool> _runRefresh() {
    _refreshing ??= _refreshCallback!().whenComplete(() => _refreshing = null);
    return _refreshing!;
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
      throw ApiException('No autorizado. Por favor inicia sesión nuevamente.',
          statusCode: statusCode);
    } else if (statusCode == 403) {
      throw ApiException('No tienes permisos para realizar esta acción.',
          statusCode: statusCode);
    } else if (statusCode == 404) {
      throw ApiException('Recurso no encontrado.', statusCode: statusCode);
    } else if (statusCode >= 500) {
      throw ApiException('Error del servidor. Intenta más tarde.',
          statusCode: statusCode);
    } else {
      final message = data['message'] ?? 'Error desconocido';
      throw ApiException(message, statusCode: statusCode);
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
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
