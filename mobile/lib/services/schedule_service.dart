// ============================================
// SERVICIO DE HORARIOS
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/schedule.dart';
import 'api_service.dart';

// Excepción especial para conflictos de horario (HTTP 409).
// Lleva la lista de bloques que se superponen para mostrarlos en la UI.
class ScheduleConflictException implements Exception {
  final String message;
  final List<Schedule> conflicts;

  ScheduleConflictException(this.message, this.conflicts);

  @override
  String toString() => message;
}

class ScheduleService {
  final ApiService _apiService = ApiService();

  // Obtener todos los horarios (filtros opcionales)
  Future<List<Schedule>> getSchedules({String? dia, int? idMateria}) async {
    try {
      String endpoint = ApiConfig.schedules;

      final params = <String>[];
      if (dia != null) params.add('dia=$dia');
      if (idMateria != null) params.add('id_materia=$idMateria');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Schedule.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener horario semanal completo ordenado lunes→domingo
  Future<List<Schedule>> getWeekSchedule() async {
    try {
      final response = await _apiService.get(ApiConfig.schedulesWeek);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Schedule.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener horario de un día específico
  Future<List<Schedule>> getScheduleByDay(String dia) async {
    try {
      final response = await _apiService.get('${ApiConfig.schedules}/day/$dia');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Schedule.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener un bloque por ID
  Future<Schedule?> getScheduleById(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.schedules}/$id');

      if (response['success'] == true) {
        return Schedule.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener conflictos del estudiante
  Future<List<Map<String, dynamic>>> getConflicts() async {
    try {
      final response = await _apiService.get(ApiConfig.schedulesConflicts);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Crear bloque de horario.
  // Lanza ScheduleConflictException si el servidor responde 409.
  // Pasar force:true para ignorar conflictos y guardar de todas formas.
  Future<Schedule> createSchedule(Schedule schedule, {bool force = false}) async {
    try {
      final body = {
        'id_materia':  schedule.idMateria,
        'dia':         schedule.dia,
        'hora_inicio': schedule.horaInicio,
        'hora_fin':    schedule.horaFin,
        'aula':        schedule.aula,
        if (force) 'force': true,
      };

      final response = await _postRaw(ApiConfig.schedules, body);
      return Schedule.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar bloque de horario.
  // Lanza ScheduleConflictException si el servidor responde 409.
  Future<Schedule> updateSchedule(int id, Schedule schedule, {bool force = false}) async {
    try {
      final body = {
        'id_materia':  schedule.idMateria,
        'dia':         schedule.dia,
        'hora_inicio': schedule.horaInicio,
        'hora_fin':    schedule.horaFin,
        'aula':        schedule.aula,
        if (force) 'force': true,
      };

      final response = await _putRaw('${ApiConfig.schedules}/$id', body);
      return Schedule.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar bloque
  Future<void> deleteSchedule(int id) async {
    try {
      await _apiService.delete('${ApiConfig.schedules}/$id');
    } catch (e) {
      rethrow;
    }
  }

  // ── HTTP raw para manejar 409 con datos de conflictos ────────────────────

  Future<Map<String, dynamic>> _postRaw(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _rawRequest('POST', endpoint, body);
  }

  Future<Map<String, dynamic>> _putRaw(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _rawRequest('PUT', endpoint, body);
  }

  Future<Map<String, dynamic>> _rawRequest(
    String method,
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url     = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = ApiConfig.getHeaders(token: _apiService.token);

    http.Response response;

    if (method == 'POST') {
      response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);
    } else {
      response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Error al procesar respuesta del servidor');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 409) {
      final message   = data['message'] ?? 'Conflicto de horario';
      final rawList   = data['conflicts'] as List<dynamic>? ?? [];
      final conflicts = rawList
          .map((json) => Schedule.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      throw ScheduleConflictException(message, conflicts);
    }

    throw ApiException(data['message'] ?? 'Error desconocido');
  }
}
