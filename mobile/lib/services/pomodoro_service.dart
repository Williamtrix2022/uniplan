// ============================================
// SERVICIO DE POMODORO
// ============================================

import '../config/api_config.dart';
import '../models/pomodoro.dart';
import 'api_service.dart';

class PomodoroService {
  final ApiService _apiService = ApiService();

  // Crear nueva sesión
  Future<PomodoroSession> createSession(PomodoroSession session) async {
    try {
      final response = await _apiService.post(
        ApiConfig.pomodoro,
        session.toJson(),
      );

      if (response['success'] == true) {
        return PomodoroSession.fromJson(response['data']);
      }

      throw Exception('Error al crear sesión');
    } catch (e) {
      rethrow;
    }
  }

  // Completar sesión
  Future<PomodoroSession> completeSession(
    int sessionId, {
    required int ciclosCompletados,
    required int tiempoTotalEstudio,
  }) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.pomodoro}/$sessionId/complete',
        body: {
          'ciclos_completados': ciclosCompletados,
          'tiempo_total_estudio': tiempoTotalEstudio,
        },
      );

      if (response['success'] == true) {
        return PomodoroSession.fromJson(response['data']);
      }

      throw Exception('Error al completar sesión');
    } catch (e) {
      rethrow;
    }
  }

  // Obtener sesiones de hoy
  Future<List<PomodoroSession>> getTodaySessions() async {
    try {
      final response = await _apiService.get(ApiConfig.pomodoroToday);

      if (response['success'] == true) {
        final List<dynamic> sessionsJson = response['data'] ?? [];
        return sessionsJson
            .map((json) => PomodoroSession.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getStats({String periodo = 'week'}) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.pomodoroStats}?periodo=$periodo',
      );

      if (response['success'] == true) {
        return response['data'] ?? {};
      }

      return {};
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar sesión
  Future<PomodoroSession> updateSession(
    int sessionId,
    PomodoroSession session,
  ) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.pomodoro}/$sessionId',
        session.toJson(),
      );

      if (response['success'] == true) {
        return PomodoroSession.fromJson(response['data']);
      }

      throw Exception('Error al actualizar sesión');
    } catch (e) {
      rethrow;
    }
  }
}