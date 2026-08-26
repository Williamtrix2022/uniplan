// ============================================
// MOTOR DE NOTIFICACIONES LOCALES (on-device)
// ============================================
//
// Toda la programación de recordatorios se hace 100% en el dispositivo con
// flutter_local_notifications — NO hay push/FCM. El backend corre en
// Vercel serverless (sin proceso persistente), así que no puede disparar
// notificaciones programadas; el dispositivo ya tiene los datos (fechas de
// entrega, horario de clases) para calcular los recordatorios localmente.

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // ── Canales de notificación ──────────────────────────────────────────────

  static const String channelTareas = 'tareas';
  static const String channelClases = 'clases';
  static const String channelEventos = 'eventos';
  static const String channelGeneral = 'general';

  static const AndroidNotificationChannel _tareasChannel =
      AndroidNotificationChannel(
    channelTareas,
    'Recordatorios de tareas',
    description: 'Avisos antes de la fecha de entrega de tus tareas',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _clasesChannel =
      AndroidNotificationChannel(
    channelClases,
    'Recordatorios de clases',
    description: 'Avisos antes de que inicie una clase de tu horario',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _eventosChannel =
      AndroidNotificationChannel(
    channelEventos,
    'Recordatorios de eventos',
    description: 'Avisos antes de un evento de tu calendario',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
    channelGeneral,
    'Notificaciones generales',
    description: 'Avisos generales de Uniplan',
  );

  // ── Inicialización ────────────────────────────────────────────────────────

  /// Inicializa el plugin, la base de datos de zonas horarias y los canales
  /// de Android. Segura de llamar más de una vez (no repite el trabajo).
  /// Debe invocarse antes de programar cualquier notificación — idealmente
  /// en `main()`, antes de `runApp`.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      // Si no se puede determinar la zona horaria del dispositivo, se sigue
      // con la UTC por defecto de `timezone` en vez de fallar el arranque.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_tareasChannel);
      await androidPlugin.createNotificationChannel(_clasesChannel);
      await androidPlugin.createNotificationChannel(_eventosChannel);
      await androidPlugin.createNotificationChannel(_generalChannel);
    }

    _isInitialized = true;
  }

  // ── Utilidad de IDs ───────────────────────────────────────────────────────

  /// Deriva un id determinístico de notificación a partir de una clave
  /// estable (p.ej. `'tarea_42'`, `'clase_7'`). Usar siempre este helper
  /// para que cancelar/reprogramar por la misma clave apunte al mismo id
  /// de notificación — así `rescheduleAll` nunca duplica avisos.
  static int idFor(String key) => key.hashCode & 0x7fffffff;

  // ── Programación ──────────────────────────────────────────────────────────

  /// Programa una notificación en [scheduledDate]. Si esa fecha ya pasó
  /// respecto al momento de la llamada, no se programa nada (silenciosamente
  /// — esto pasará seguido para tareas cuya fecha de entrega ya venció).
  ///
  /// Intenta usar una alarma exacta (`exactAllowWhileIdle`); si el sistema
  /// operativo no permite alarmas exactas en este momento (p.ej. el usuario
  /// revocó el permiso "Alarmas y recordatorios" en Android 12+), cae a
  /// modo inexacto en vez de lanzar una excepción.
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channel,
  }) async {
    if (!scheduledDate.isAfter(DateTime.now())) {
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final channelInfo = _channelFor(channel);

    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelInfo.id,
            channelInfo.name,
            channelDescription: channelInfo.description,
            importance: channelInfo.importance,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException {
      // No se debe crashear la app por no poder programar un recordatorio
      // (p.ej. el permiso fue revocado entre el chequeo y esta llamada).
    }
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  /// Solicita el permiso de notificaciones (Android 13+, `POST_NOTIFICATIONS`).
  /// Se debe invocar en un momento con contexto claro para el usuario — al
  /// abrir la pantalla de configuración de notificaciones, o justo tras el
  /// primer login exitoso — nunca a ciegas en el arranque de la app.
  static Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  static AndroidNotificationChannel _channelFor(String channel) {
    switch (channel) {
      case channelTareas:
        return _tareasChannel;
      case channelClases:
        return _clasesChannel;
      default:
        return _generalChannel;
    }
  }
}
