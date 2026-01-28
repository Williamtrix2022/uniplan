// ============================================
// SERVICIO DE CALENDARIO
// ============================================

import '../config/api_config.dart';
import '../models/calendar_event.dart';
import 'api_service.dart';

class CalendarService {
  final ApiService _apiService = ApiService();

  // Obtener todos los eventos
  Future<List<CalendarEvent>> getEvents({
    String? tipo,
    int? idMateria,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      String endpoint = ApiConfig.calendar;

      final params = <String>[];
      if (tipo != null) params.add('tipo=$tipo');
      if (idMateria != null) params.add('id_materia=$idMateria');
      if (fechaInicio != null && fechaFin != null) {
        params.add('fecha_inicio=$fechaInicio');
        params.add('fecha_fin=$fechaFin');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> eventsJson = response['data'] ?? [];
        return eventsJson
            .map((json) => CalendarEvent.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener eventos de hoy
  Future<List<CalendarEvent>> getTodayEvents() async {
    try {
      final response = await _apiService.get(ApiConfig.calendarToday);

      if (response['success'] == true) {
        final List<dynamic> eventsJson = response['data'] ?? [];
        return eventsJson
            .map((json) => CalendarEvent.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener eventos de la semana
  Future<List<CalendarEvent>> getWeekEvents() async {
    try {
      final response = await _apiService.get(ApiConfig.calendarWeek);

      if (response['success'] == true) {
        final List<dynamic> eventsJson = response['data'] ?? [];
        return eventsJson
            .map((json) => CalendarEvent.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener eventos del mes
  Future<List<CalendarEvent>> getMonthEvents(int year, int month) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.calendarMonth}?year=$year&month=$month',
      );

      if (response['success'] == true) {
        final List<dynamic> eventsJson = response['data'] ?? [];
        return eventsJson
            .map((json) => CalendarEvent.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Crear evento
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final response = await _apiService.post(
        ApiConfig.calendar,
        event.toJson(),
      );

      if (response['success'] == true) {
        return CalendarEvent.fromJson(response['data']);
      }

      throw Exception('Error al crear evento');
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar evento
  Future<CalendarEvent> updateEvent(int eventId, CalendarEvent event) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.calendar}/$eventId',
        event.toJson(),
      );

      if (response['success'] == true) {
        return CalendarEvent.fromJson(response['data']);
      }

      throw Exception('Error al actualizar evento');
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar evento
  Future<void> deleteEvent(int eventId) async {
    try {
      await _apiService.delete('${ApiConfig.calendar}/$eventId');
    } catch (e) {
      rethrow;
    }
  }
}