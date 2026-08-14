// ============================================
// SERVICIO DE NOTIFICACIONES
// ============================================

import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../models/notification_preferences.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  // Obtener notificaciones del estudiante, con filtros opcionales
  Future<List<AppNotification>> getNotifications({
    String? tipo,
    bool? leida,
  }) async {
    try {
      final query = <String>[];
      if (tipo != null && tipo.isNotEmpty) query.add('tipo=$tipo');
      if (leida != null) query.add('leida=$leida');
      final suffix = query.isNotEmpty ? '?${query.join('&')}' : '';

      final response =
          await _apiService.get('${ApiConfig.notifications}$suffix');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener el conteo de notificaciones no leídas
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(ApiConfig.notificationsUnreadCount);

      if (response['success'] == true) {
        final data = response['data'];
        return (data['unread_count'] ?? 0) as int;
      }

      return 0;
    } catch (e) {
      rethrow;
    }
  }

  // Marcar una notificación como leída
  Future<void> markAsRead(int id) async {
    try {
      await _apiService.patch(ApiConfig.notificationRead(id));
    } catch (e) {
      rethrow;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      await _apiService.patch(ApiConfig.notificationsReadAll);
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(int id) async {
    try {
      await _apiService.delete('${ApiConfig.notifications}/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Obtener preferencias de notificaciones del estudiante
  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _apiService.get(ApiConfig.notificationsPreferences);

      if (response['success'] == true && response['data'] != null) {
        return NotificationPreferences.fromJson(
          Map<String, dynamic>.from(response['data']),
        );
      }

      return NotificationPreferences.defaults();
    } catch (e) {
      rethrow;
    }
  }

  // Crear una notificación en el feed (usada por el motor de recordatorios
  // locales para que la campanita / Centro de Notificaciones reflejen los
  // recordatorios que se programan en el dispositivo)
  Future<AppNotification> createNotification({
    required String tipo,
    required String titulo,
    String? mensaje,
    String? referenciaTipo,
    int? referenciaId,
    DateTime? fechaProgramada,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.notifications, {
        'tipo': tipo,
        'titulo': titulo,
        'mensaje': mensaje,
        'referencia_tipo': referenciaTipo,
        'referencia_id': referenciaId,
        'fecha_programada': fechaProgramada?.toIso8601String(),
      });

      if (response['success'] == true && response['data'] != null) {
        return AppNotification.fromJson(
          Map<String, dynamic>.from(response['data']),
        );
      }

      throw ApiException(
        response['message'] ?? 'No se pudo crear la notificación',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar preferencias de notificaciones
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final response = await _apiService.put(
        ApiConfig.notificationsPreferences,
        preferences.toJson(),
      );

      if (response['success'] == true && response['data'] != null) {
        return NotificationPreferences.fromJson(
          Map<String, dynamic>.from(response['data']),
        );
      }

      throw ApiException(
        response['message'] ?? 'No se pudieron actualizar las preferencias',
      );
    } catch (e) {
      rethrow;
    }
  }
}
