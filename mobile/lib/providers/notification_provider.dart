// ============================================
// PROVIDER DE NOTIFICACIONES
// ============================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/calendar_event.dart';
import '../models/notification_preferences.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import '../services/local_notification_service.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';

/// Firma de `LocalNotificationService.cancel`, extraída para poder inyectar
/// un fake en tests (ver comentario en el constructor de [NotificationProvider]).
typedef CancelNotificationFn = Future<void> Function(int id);

/// Firma de `LocalNotificationService.scheduleAt`, extraída por el mismo
/// motivo que [CancelNotificationFn].
typedef ScheduleNotificationFn = Future<void> Function({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String channel,
});

class NotificationProvider extends ChangeNotifier {
  static const _cacheKey = 'cached_notifications';
  static const _preferencesCacheKey = 'cached_notification_preferences';

  /// Cuántas ocurrencias semanales futuras de cada clase se programan por
  /// corrida de `rescheduleAll` (ver comentario en el loop de clases).
  static const _classOccurrencesPerReschedule = 4;

  // El servicio (y las dos llamadas de programación local que usa
  // `rescheduleAll`) son inyectables — a diferencia de otros providers del
  // proyecto, que instancian/llaman su servicio directamente — para poder
  // reemplazarlos por fakes/mocks en tests unitarios sin tocar disco/red ni
  // el plugin real de notificaciones (`flutter_local_notifications`, que no
  // tiene handler de canal de plataforma en un entorno de test unitario).
  NotificationProvider({
    NotificationService? service,
    CancelNotificationFn? cancelNotification,
    ScheduleNotificationFn? scheduleNotification,
  })  : _service = service ?? NotificationService(),
        _cancelNotification =
            cancelNotification ?? LocalNotificationService.cancel,
        _scheduleNotification =
            scheduleNotification ?? LocalNotificationService.scheduleAt;

  final NotificationService _service;
  final CancelNotificationFn _cancelNotification;
  final ScheduleNotificationFn _scheduleNotification;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  NotificationPreferences _preferences = NotificationPreferences.defaults();

  bool _isLoading = false;
  bool _isPreferencesLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  NotificationPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isPreferencesLoading => _isPreferencesLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Notificaciones agrupadas para los chips de filtro de la pantalla de
  /// notificaciones, más recientes primero. [group] es uno de:
  /// - `null` (o vacío): todas las notificaciones.
  /// - `'clase'`: solo las de tipo `'clase'`.
  /// - `'tarea'`: solo las de tipo `'tarea'`.
  /// - `'evento'`: solo las de tipo `'evento'` (eventos de calendario).
  /// - `'otros'`: el resto — `'sistema'` + `'general'` — bajo un único
  ///   filtro de presentación de cajón de sastre. `'clase'`, `'tarea'` y
  ///   `'evento'` tienen su propio chip dedicado, así que quedan afuera de
  ///   este catch-all (antes las tareas caían acá también, mezclándose con
  ///   avisos del sistema sin que tuviera sentido para el usuario).
  ///
  /// Es puramente de UI: no cambia el campo `tipo` real de cada
  /// notificación ni cómo se crean/persisten — `AppNotification.tipoLabel`
  /// sigue mostrando el tipo granular original en cada tarjeta individual.
  List<AppNotification> notificationsByFilterGroup(String? group) {
    List<AppNotification> list;
    if (group == null || group.isEmpty) {
      list = List<AppNotification>.from(_notifications);
    } else if (group == 'otros') {
      list = _notifications
          .where((n) =>
              n.tipo != 'clase' && n.tipo != 'tarea' && n.tipo != 'evento')
          .toList();
    } else {
      list = _notifications.where((n) => n.tipo == group).toList();
    }
    list.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return list;
  }

  // ── Inicialización ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await load(useCache: true);
    await loadUnreadCount();
    await loadPreferences();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Carga de datos ───────────────────────────────────────────────────────

  Future<void> load({bool useCache = false}) async {
    if (!useCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (useCache) {
        final cached = await _loadCache();
        if (cached.isNotEmpty) {
          _notifications = _filterByPreferences(cached);
          notifyListeners();
        }
      }

      _notifications = _filterByPreferences(await _service.getNotifications());
      _error = null;
      await _saveCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadPreferences() async {
    _isPreferencesLoading = true;
    notifyListeners();

    try {
      final cached = await _loadPreferencesCache();
      if (cached != null) {
        _preferences = cached;
        notifyListeners();
      }

      _preferences = await _service.getPreferences();
      _error = null;
      await _savePreferencesCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPreferencesLoading = false;
      notifyListeners();
    }
  }

  /// Filtra las notificaciones de tipo 'general'/'sistema' del listado
  /// mostrado al usuario cuando `preferences.notifGenerales` está apagado.
  /// Filtro puramente de presentación (client-side): las notificaciones
  /// siguen existiendo en el backend, solo se ocultan de la UI mientras el
  /// toggle esté en `false`.
  List<AppNotification> _filterByPreferences(List<AppNotification> source) {
    if (_preferences.notifGenerales) return source;
    return source
        .where((n) => n.tipo != 'general' && n.tipo != 'sistema')
        .toList();
  }

  Future<void> refresh() async {
    await load(useCache: false);
    await loadUnreadCount();
  }

  // ── Acciones sobre notificaciones ────────────────────────────────────────

  Future<void> markRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;

    final original = _notifications[index];
    if (original.leida) return;

    _notifications[index] = original.copyWith(leida: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _service.markAsRead(id);
      _error = null;
      await _saveCache();
    } catch (e) {
      _notifications[index] = original;
      _unreadCount++;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final previousNotifications = List<AppNotification>.from(_notifications);
    final previousUnreadCount = _unreadCount;

    _notifications =
        _notifications.map((n) => n.copyWith(leida: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _service.markAllAsRead();
      _error = null;
      await _saveCache();
    } catch (e) {
      _notifications = previousNotifications;
      _unreadCount = previousUnreadCount;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    await _service.deleteNotification(id);

    final wasUnread =
        _notifications.any((n) => n.id == id && !n.leida);
    _notifications.removeWhere((n) => n.id == id);
    if (wasUnread && _unreadCount > 0) _unreadCount--;

    await _saveCache();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Preferencias ─────────────────────────────────────────────────────────

  /// Persiste [preferences] en el backend y actualiza el estado local.
  /// Si se proveen [tasks] y [schedules] (típicamente leídos desde
  /// `TaskProvider`/`ScheduleProvider` por la pantalla que llama a este
  /// método), reprograma todos los recordatorios locales para reflejar las
  /// nuevas preferencias (horario de silencio, toggles por tipo). [events]
  /// es opcional aparte porque no hay un `CalendarProvider` compartido en la
  /// app — si no se provee, simplemente no se tocan los recordatorios de
  /// eventos en este reschedule (no se pierden: el próximo `rescheduleAll`
  /// completo, típicamente desde Home, los vuelve a calcular).
  Future<void> updatePreferences(
    NotificationPreferences preferences, {
    List<Task>? tasks,
    List<Schedule>? schedules,
    List<CalendarEvent> events = const [],
  }) async {
    final previous = _preferences;
    _preferences = preferences;
    notifyListeners();

    try {
      _preferences = await _service.updatePreferences(preferences);
      _error = null;
      await _savePreferencesCache();

      if (tasks != null && schedules != null) {
        await rescheduleAll(tasks: tasks, schedules: schedules, events: events);
      }
    } catch (e) {
      _preferences = previous;
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // ── Orquestación de recordatorios locales ───────────────────────────────

  /// Recalcula y reprograma TODOS los recordatorios locales (tareas, clases
  /// y eventos de calendario) a partir de las preferencias actuales. Segura
  /// de llamar repetidamente: cada recordatorio usa un id determinístico
  /// (`LocalNotificationService.idFor`), por lo que reprogramar cancela y
  /// reemplaza en vez de duplicar.
  ///
  /// Nota: toda tarea pendiente (no completada) es candidata a recordatorio
  /// mientras `preferences.notifTareas` esté activo — el aviso ya no tiene
  /// un tiempo de antelación configurable en minutos: siempre es el día
  /// anterior (20:00) y el mismo día (8:00) de la fecha de entrega.
  ///
  /// Los eventos de calendario usan su PROPIO flag `recordatorio` y su
  /// PROPIO `minutosAntesRecordatorio` (columnas ya existentes en
  /// `eventos_calendario`, seteadas por evento desde `EventFormScreen`) en
  /// vez de una preferencia global como tareas/clases — cada evento ya
  /// decidía por sí solo si quería aviso y con cuánta anticipación; no hay
  /// necesidad de un toggle/tiempo global adicional para esto.
  ///
  /// [now] es inyectable para permitir tests deterministas (mismo motivo que
  /// `computeReminderTime`/`nextWeeklyOccurrence` en `notification_scheduler.dart`
  /// lo aceptan como parámetro). Si no se provee, se usa `DateTime.now()` —
  /// el comportamiento para callers existentes no cambia.
  Future<void> rescheduleAll({
    required List<Task> tasks,
    required List<Schedule> schedules,
    List<CalendarEvent> events = const [],
    DateTime? now,
  }) async {
    final prefs = _preferences;
    final effectiveNow = now ?? DateTime.now();
    var feedChanged = false;

    if (await _expireStaleFeedEntries(effectiveNow)) {
      feedChanged = true;
    }

    for (final task in tasks) {
      final beforeId = LocalNotificationService.idFor('tarea_${task.id}_antes');
      final sameDayId = LocalNotificationService.idFor('tarea_${task.id}_mismodia');
      await _cancelNotification(beforeId);
      await _cancelNotification(sameDayId);

      // El tiempo de antelación configurable (`minutosAntesTarea`) ya no se
      // usa a propósito: siempre se avisa el día anterior a las 20:00 y el
      // mismo día a las 8:00. `task.fechaEntrega` es solo fecha (sin hora,
      // por diseño — ver `date_parsing.dart`), así que estos son los únicos
      // dos puntos naturales para avisar. El switch `notifTareas` sigue
      // gateando esto — si el usuario lo apaga, no debe llegar NADA.
      if (!prefs.notifTareas || task.isCompleted) continue;

      final due = task.fechaEntrega;
      final dayBeforeTarget = DateTime(due.year, due.month, due.day - 1, 20, 0);
      final sameDayTarget = DateTime(due.year, due.month, due.day, 8, 0);

      // `minutesBefore: 0` reutiliza `computeReminderTime` tal cual: valida
      // que el objetivo siga en el futuro respecto a `now` y aplica el
      // horario de silencio, sin restarle minutos (ya es la hora exacta que
      // queremos).
      final beforeReminder = computeReminderTime(
        targetDateTime: dayBeforeTarget,
        minutesBefore: 0,
        now: effectiveNow,
        quietHoursStart: prefs.horaSilencioInicio,
        quietHoursEnd: prefs.horaSilencioFin,
      );
      final sameDayReminder = computeReminderTime(
        targetDateTime: sameDayTarget,
        minutesBefore: 0,
        now: effectiveNow,
        quietHoursStart: prefs.horaSilencioInicio,
        quietHoursEnd: prefs.horaSilencioFin,
      );

      if (beforeReminder != null) {
        await _scheduleNotification(
          id: beforeId,
          title: 'Tarea próxima a vencer',
          body: '${task.titulo} vence mañana',
          scheduledDate: beforeReminder,
          channel: LocalNotificationService.channelTareas,
        );
      }
      if (sameDayReminder != null) {
        await _scheduleNotification(
          id: sameDayId,
          title: 'Tarea próxima a vencer',
          body: '${task.titulo} vence hoy',
          scheduledDate: sameDayReminder,
          channel: LocalNotificationService.channelTareas,
        );
      }

      // Solo UNA entrada de feed por tarea (el más próximo de los dos
      // avisos) — mismo criterio que ya usan las clases con sus 4
      // ocurrencias semanales: varias alarmas del SO, una sola fila
      // representativa en la campanita.
      final nextReminder = [beforeReminder, sameDayReminder]
          .whereType<DateTime>()
          .fold<DateTime?>(null, (min, r) => min == null || r.isBefore(min) ? r : min);

      if (nextReminder != null) {
        final isSameDay = sameDayReminder != null && nextReminder == sameDayReminder;
        if (await _ensureFeedEntry(
          tipo: 'tarea',
          titulo: 'Tarea próxima a vencer',
          mensaje: isSameDay ? '${task.titulo} vence hoy' : '${task.titulo} vence mañana',
          referenciaTipo: 'tarea',
          referenciaId: task.id,
          fechaProgramada: nextReminder,
          now: effectiveNow,
        )) {
          feedChanged = true;
        }
      }
    }

    // Se programan hasta 4 ocurrencias semanales por clase (no solo la más
    // próxima) en cada corrida de `rescheduleAll` — como el reschedule solo
    // se dispara al abrir Home (ver `_scheduleNotificationReminders`), un
    // usuario que no abre la app por varias semanas seguiría sin recibir
    // recordatorios más allá de la primera clase. Con 4 semanas de alarmas
    // ya programadas de una vez, la cobertura dura ~1 mes entre aperturas
    // sin depender de infraestructura nueva (FCM/backend).
    for (final schedule in schedules) {
      final occurrenceIds = List<int>.generate(
        _classOccurrencesPerReschedule,
        (i) => LocalNotificationService.idFor('clase_${schedule.id}_$i'),
      );
      for (final id in occurrenceIds) {
        await _cancelNotification(id);
      }

      if (!prefs.notifClases) continue;

      final occurrences = nextWeeklyOccurrences(
        dia: schedule.dia,
        horaInicio: schedule.horaInicio,
        now: effectiveNow,
        count: _classOccurrencesPerReschedule,
      );

      final body = schedule.materiaNombre != null
          ? '${schedule.materiaNombre} · ${schedule.rangoHorario}'
          : 'Tienes una clase pronto';

      for (var i = 0; i < occurrences.length; i++) {
        final reminder = computeReminderTime(
          targetDateTime: occurrences[i],
          minutesBefore: prefs.minutosAntesClase,
          now: effectiveNow,
          quietHoursStart: prefs.horaSilencioInicio,
          quietHoursEnd: prefs.horaSilencioFin,
        );
        if (reminder == null) continue;

        await _scheduleNotification(
          id: occurrenceIds[i],
          title: 'Clase próxima a iniciar',
          body: body,
          scheduledDate: reminder,
          channel: LocalNotificationService.channelClases,
        );

        // Solo la ocurrencia más próxima (i == 0) refleja una entrada en el
        // feed persistido, y solo si esa ocurrencia es HOY — las otras 3 (y
        // cualquier ocurrencia futura que no sea hoy) son únicamente alarmas
        // del SO. Sin este filtro por día, cada clase de la semana entera
        // aparecía en el feed apenas se abría la app, sin importar si le
        // tocaba hoy o en varios días. `_expireStaleClassEntries` se encarga
        // de sacar la fila del día anterior.
        if (i == 0 &&
            _isSameCalendarDay(occurrences[i], effectiveNow) &&
            await _ensureFeedEntry(
              tipo: 'clase',
              titulo: 'Clase próxima a iniciar',
              mensaje: body,
              referenciaTipo: 'clase',
              referenciaId: schedule.id,
              fechaProgramada: reminder,
              now: effectiveNow,
            )) {
          feedChanged = true;
        }
      }
    }

    for (final event in events) {
      final eventId = event.id;
      if (eventId == null) continue;

      final id = LocalNotificationService.idFor('evento_$eventId');
      await _cancelNotification(id);

      // A diferencia de tareas/clases, acá NO hay un toggle global: cada
      // evento trae su propio `recordatorio` (bool) y su propio
      // `minutosAntesRecordatorio`, seteados en `EventFormScreen`.
      if (!event.recordatorio) continue;

      // `fecha` es solo fecha (columna DATE); `horaInicio` es una columna
      // TIME separada y puede ser null (evento de todo el día, o sin hora
      // definida) — en ese caso se avisa a las 8:00 de ese día por defecto,
      // mismo criterio que el aviso "mismo día" de las tareas.
      final target = DateTime(
        event.fecha.year,
        event.fecha.month,
        event.fecha.day,
        event.horaInicio?.hour ?? 8,
        event.horaInicio?.minute ?? 0,
      );

      final reminder = computeReminderTime(
        targetDateTime: target,
        minutesBefore: event.minutosAntesRecordatorio,
        now: effectiveNow,
        quietHoursStart: prefs.horaSilencioInicio,
        quietHoursEnd: prefs.horaSilencioFin,
      );
      if (reminder == null) continue;

      await _scheduleNotification(
        id: id,
        title: 'Evento próximo',
        body: event.titulo,
        scheduledDate: reminder,
        channel: LocalNotificationService.channelEventos,
      );

      if (await _ensureFeedEntry(
        tipo: 'evento',
        titulo: 'Evento próximo',
        mensaje: event.titulo,
        referenciaTipo: 'evento',
        referenciaId: eventId,
        fechaProgramada: reminder,
        now: effectiveNow,
      )) {
        feedChanged = true;
      }
    }

    if (feedChanged) notifyListeners();
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Saca del feed las entradas de tipo `'clase'`, `'tarea'` o `'evento'`
  /// que quedaron de un día ANTERIOR a [now] — no de "cualquier cosa cuya
  /// hora ya pasó".
  ///
  /// Esa distinción es a propósito y arregla un bug real: comparar solo
  /// contra la hora exacta (`fechaProgramada.isBefore(now)`, sin mirar el
  /// día) hacía que una notificación se volviera "vencida" apenas pasaban
  /// unos minutos de creada — y como esto corre en CADA `rescheduleAll`
  /// (cada apertura de la app, cada pull-to-refresh), la fila se borraba y
  /// se volvía a crear una y otra vez EL MISMO DÍA para la misma ocurrencia
  /// vigente, reseteando `leida` a false cada vez. Resultado: una
  /// notificación que el usuario ya había visto volvía a aparecer como no
  /// leída con solo reabrir la app. Filtrando por día, una entrada de HOY
  /// se deja tranquila (aunque su hora ya pasó) hasta que el calendario
  /// avance; recién ahí se la considera vencida de verdad.
  ///
  /// Sin este barrido tampoco alcanzaría: para clases es la otra mitad del
  /// fix de "no tiene en cuenta el día" (limpia la fila del día anterior
  /// cuando la próxima ocurrencia no es hoy y por lo tanto nada más la va a
  /// tocar); para tareas, limpia una tarea vencida hace días cuyos dos
  /// avisos (día antes / mismo día) ya pasaron. Las notificaciones de tipo
  /// `'sistema'`/`'general'` no se tocan acá — no tienen ventana de
  /// vigencia, las gestiona el usuario a mano. Best-effort: si el borrado
  /// remoto falla, igual se limpia del estado en memoria para no repetir el
  /// intento en cada `rescheduleAll`.
  Future<bool> _expireStaleFeedEntries(DateTime now) async {
    final stale = _notifications
        .where((n) =>
            (n.referenciaTipo == 'clase' ||
                n.referenciaTipo == 'tarea' ||
                n.referenciaTipo == 'evento') &&
            n.fechaProgramada != null &&
            n.fechaProgramada!.isBefore(now) &&
            !_isSameCalendarDay(n.fechaProgramada!, now))
        .toList();
    if (stale.isEmpty) return false;

    for (final entry in stale) {
      try {
        await _service.deleteNotification(entry.id);
      } catch (_) {
        // best-effort: seguimos limpiando localmente aunque falle el borrado remoto
      }
      if (!entry.leida && _unreadCount > 0) _unreadCount--;
    }
    _notifications.removeWhere((n) => stale.any((s) => s.id == n.id));
    await _saveCache();
    return true;
  }

  /// Refleja un recordatorio recién programado en el feed persistido (para
  /// que la campanita / Centro de Notificaciones lo muestren) — antes de
  /// esto, el recordatorio SOLO existía como notificación local del sistema
  /// operativo y nunca aparecía dentro de la app.
  ///
  /// No crea una entrada duplicada si ya existe una para la misma
  /// referencia (`referenciaTipo` + `referenciaId`) — no se actualiza si los
  /// datos cambiaron (p.ej. nuevo horario de anticipación), solo se evita
  /// duplicar; ver nota de diseño en el historial del cambio.
  ///
  /// Es best-effort: si la creación falla (p.ej. sin conexión), no interrumpe
  /// `rescheduleAll` — el recordatorio local ya quedó programado, que es lo
  /// que realmente importa para que el usuario reciba el aviso.
  ///
  /// La entrada se crea en el backend SIEMPRE, pero solo se agrega al estado
  /// visible en memoria si [fechaProgramada] ya llegó (no es posterior a
  /// [now]). El backend (`getNotifications`/`getUnreadCount`) oculta toda
  /// notificación cuya `fecha_programada` siga en el futuro — y como
  /// `computeReminderTime` garantiza que el recordatorio siempre cae después
  /// de `now`, mostrarla ya acá era mentirle al usuario: aparecía apenas se
  /// programaba y desaparecía en el siguiente `load()`/`refresh()` (porque
  /// el backend la seguía ocultando), para recién reaparecer cuando de
  /// verdad llegaba su hora. Este chequeo alinea al cliente con esa regla
  /// del backend y elimina ese parpadeo.
  ///
  /// Devuelve `true` si se agregó una notificación nueva al estado en
  /// memoria (para que el caller sepa si debe notificar a los listeners).
  Future<bool> _ensureFeedEntry({
    required String tipo,
    required String titulo,
    required String mensaje,
    required String referenciaTipo,
    required int referenciaId,
    required DateTime fechaProgramada,
    required DateTime now,
  }) async {
    final alreadyExists = _notifications.any((n) =>
        n.referenciaTipo == referenciaTipo && n.referenciaId == referenciaId);
    if (alreadyExists) return false;

    try {
      final created = await _service.createNotification(
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        referenciaTipo: referenciaTipo,
        referenciaId: referenciaId,
        fechaProgramada: fechaProgramada,
      );

      if (fechaProgramada.isAfter(now)) return false;

      _notifications = [created, ..._notifications];
      if (!created.leida) _unreadCount++;
      await _saveCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Caché ─────────────────────────────────────────────────────────────────

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(list));
  }

  Future<List<AppNotification>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((json) =>
              AppNotification.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePreferencesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferencesCacheKey,
      jsonEncode(_preferences.toJson()),
    );
  }

  Future<NotificationPreferences?> _loadPreferencesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_preferencesCacheKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
