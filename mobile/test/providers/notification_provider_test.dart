import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniplan/models/app_notification.dart';
import 'package:uniplan/models/calendar_event.dart';
import 'package:uniplan/models/notification_preferences.dart';
import 'package:uniplan/models/schedule.dart';
import 'package:uniplan/models/task.dart';
import 'package:uniplan/providers/notification_provider.dart';
import 'package:uniplan/services/local_notification_service.dart';
import 'package:uniplan/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

/// Fake en memoria de las dos llamadas estáticas de `LocalNotificationService`
/// que `rescheduleAll` invoca. Se inyecta en `NotificationProvider` (ver
/// constructor `cancelNotification`/`scheduleNotification`) para poder
/// verificar determinísticamente qué se programa/cancela sin tocar el
/// plugin real de `flutter_local_notifications` (que no tiene handler de
/// canal de plataforma en un test unitario).
class _FakeScheduler {
  final List<int> cancelledIds = [];
  final List<Map<String, dynamic>> scheduled = [];

  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channel,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'channel': channel,
    });
  }
}

Task _task({
  required int id,
  required DateTime fechaEntrega,
  bool completada = false,
}) =>
    Task(
      id: id,
      idEstudiante: 1,
      titulo: 'Tarea $id',
      fechaEntrega: fechaEntrega,
      completada: completada,
    );

Schedule _schedule({
  required int id,
  required String dia,
  required String horaInicio,
}) =>
    Schedule(
      id: id,
      idEstudiante: 1,
      idMateria: 1,
      dia: dia,
      horaInicio: horaInicio,
      horaFin: '10:00:00',
      fechaCreacion: DateTime(2026, 1, 1),
    );

CalendarEvent _event({
  required int id,
  required DateTime fecha,
  TimeOfDay? horaInicio,
  bool recordatorio = true,
  int minutosAntesRecordatorio = 30,
}) =>
    CalendarEvent(
      id: id,
      idEstudiante: 1,
      titulo: 'Evento $id',
      fecha: fecha,
      horaInicio: horaInicio,
      recordatorio: recordatorio,
      minutosAntesRecordatorio: minutosAntesRecordatorio,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(NotificationPreferences.defaults());
  });

  late MockNotificationService mockService;
  late NotificationProvider provider;

  List<AppNotification> sampleNotifications() => [
        AppNotification(
          id: 1,
          tipo: 'tarea',
          titulo: 'Tarea 1',
          mensaje: 'Mensaje 1',
          leida: false,
          fechaCreacion: DateTime(2026, 7, 15, 9, 0),
        ),
        AppNotification(
          id: 2,
          tipo: 'clase',
          titulo: 'Clase 1',
          mensaje: 'Mensaje 2',
          leida: false,
          fechaCreacion: DateTime(2026, 7, 15, 8, 0),
        ),
      ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockNotificationService();
    provider = NotificationProvider(service: mockService);

    when(() => mockService.getNotifications())
        .thenAnswer((_) async => sampleNotifications());
    when(() => mockService.getUnreadCount()).thenAnswer((_) async => 2);
    when(() => mockService.getPreferences())
        .thenAnswer((_) async => NotificationPreferences.defaults());
    when(() => mockService.markAsRead(any())).thenAnswer((_) async {});
    when(() => mockService.markAllAsRead()).thenAnswer((_) async {});
    when(() => mockService.deleteNotification(any())).thenAnswer((_) async {});
    when(() => mockService.updatePreferences(any()))
        .thenAnswer((invocation) async => invocation.positionalArguments[0]);

    var nextFeedId = 100;
    when(() => mockService.createNotification(
          tipo: any(named: 'tipo'),
          titulo: any(named: 'titulo'),
          mensaje: any(named: 'mensaje'),
          referenciaTipo: any(named: 'referenciaTipo'),
          referenciaId: any(named: 'referenciaId'),
          fechaProgramada: any(named: 'fechaProgramada'),
        )).thenAnswer((invocation) async => AppNotification(
          id: nextFeedId++,
          tipo: invocation.namedArguments[#tipo] as String,
          titulo: invocation.namedArguments[#titulo] as String,
          mensaje: invocation.namedArguments[#mensaje] as String,
          referenciaTipo: invocation.namedArguments[#referenciaTipo] as String?,
          referenciaId: invocation.namedArguments[#referenciaId] as int?,
          fechaProgramada:
              invocation.namedArguments[#fechaProgramada] as DateTime?,
          fechaCreacion: DateTime(2026, 7, 15),
        ));
  });

  group('load', () {
    test('populates the notifications list on success', () async {
      await provider.load();

      expect(provider.notifications.length, 2);
      expect(provider.error, isNull);
      verify(() => mockService.getNotifications()).called(1);
    });

    test('sets an error message when the service throws', () async {
      when(() => mockService.getNotifications())
          .thenThrow(Exception('network down'));

      await provider.load();

      expect(provider.notifications, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('network down'));
    });
  });

  group('markRead', () {
    test('decrements unreadCount and marks the notification as read',
        () async {
      await provider.load();
      await provider.loadUnreadCount();
      expect(provider.unreadCount, 2);

      await provider.markRead(1);

      expect(provider.unreadCount, 1);
      final updated = provider.notifications.firstWhere((n) => n.id == 1);
      expect(updated.leida, isTrue);
      verify(() => mockService.markAsRead(1)).called(1);
    });

    test('is a no-op when marking an already-read notification again',
        () async {
      await provider.load();
      await provider.loadUnreadCount();
      await provider.markRead(1); // no leída -> leída, 2 -> 1
      await provider.markRead(1); // ya leída, no debería hacer nada más

      expect(provider.unreadCount, 1);
      verify(() => mockService.markAsRead(1)).called(1);
    });

    test('reverts the optimistic update when the service call fails',
        () async {
      await provider.load();
      await provider.loadUnreadCount();

      when(() => mockService.markAsRead(1)).thenThrow(Exception('boom'));

      await provider.markRead(1);

      expect(provider.unreadCount, 2); // revertido
      final notification =
          provider.notifications.firstWhere((n) => n.id == 1);
      expect(notification.leida, isFalse); // revertido
      expect(provider.error, isNotNull);
    });
  });

  group('markAllRead', () {
    test('marks every notification as read and zeroes unreadCount',
        () async {
      await provider.load();
      await provider.loadUnreadCount();

      await provider.markAllRead();

      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((n) => n.leida), isTrue);
      verify(() => mockService.markAllAsRead()).called(1);
    });
  });

  group('delete', () {
    test('removes the notification and decrements unreadCount if unread',
        () async {
      await provider.load();
      await provider.loadUnreadCount();

      await provider.delete(1);

      expect(provider.notifications.any((n) => n.id == 1), isFalse);
      expect(provider.unreadCount, 1);
      verify(() => mockService.deleteNotification(1)).called(1);
    });
  });

  group('updatePreferences', () {
    test('reflects the new preferences and notifies listeners on success',
        () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final updated = NotificationPreferences.defaults()
          .copyWith(notifTareas: false, minutosAntesTarea: 15);

      await provider.updatePreferences(updated);

      expect(provider.preferences.notifTareas, isFalse);
      expect(provider.preferences.minutosAntesTarea, 15);
      expect(provider.error, isNull);
      expect(notifyCount, greaterThan(0));
      verify(() => mockService.updatePreferences(updated)).called(1);
    });

    test(
        'reverts to the previous preferences and rethrows when the service call fails',
        () async {
      final original = provider.preferences; // defaults, notifTareas: true
      final attempted = original.copyWith(notifTareas: false);

      when(() => mockService.updatePreferences(attempted))
          .thenThrow(Exception('network down'));

      await expectLater(
        () => provider.updatePreferences(attempted),
        throwsA(isException),
      );

      // Contrato real del código: en el catch se restaura `previous`, no se
      // queda con el valor optimista a medio aplicar.
      expect(provider.preferences.notifTareas, original.notifTareas);
      expect(provider.error, isNotNull);
    });
  });

  group('notificationsByFilterGroup', () {
    List<AppNotification> filterableNotifications() => [
          AppNotification(
            id: 1,
            tipo: 'tarea',
            titulo: 'Tarea 1',
            mensaje: 'Mensaje 1',
            fechaCreacion: DateTime(2026, 7, 15, 9, 0),
          ),
          AppNotification(
            id: 2,
            tipo: 'clase',
            titulo: 'Clase 1',
            mensaje: 'Mensaje 2',
            fechaCreacion: DateTime(2026, 7, 15, 8, 0),
          ),
          AppNotification(
            id: 3,
            tipo: 'sistema',
            titulo: 'Sistema 1',
            mensaje: 'Mensaje 3',
            fechaCreacion: DateTime(2026, 7, 15, 7, 0),
          ),
          AppNotification(
            id: 4,
            tipo: 'general',
            titulo: 'General 1',
            mensaje: 'Mensaje 4',
            fechaCreacion: DateTime(2026, 7, 15, 6, 0),
          ),
          AppNotification(
            id: 5,
            tipo: 'evento',
            titulo: 'Evento 1',
            mensaje: 'Mensaje 5',
            fechaCreacion: DateTime(2026, 7, 15, 5, 0),
          ),
        ];

    setUp(() async {
      when(() => mockService.getNotifications())
          .thenAnswer((_) async => filterableNotifications());
      await provider.load();
    });

    test('null group returns every notification', () {
      final result = provider.notificationsByFilterGroup(null);
      expect(result.map((n) => n.id).toSet(), {1, 2, 3, 4, 5});
    });

    test('"clase" group returns only clase notifications', () {
      final result = provider.notificationsByFilterGroup('clase');
      expect(result.map((n) => n.id).toList(), [2]);
    });

    test('"tarea" group returns only tarea notifications', () {
      final result = provider.notificationsByFilterGroup('tarea');
      expect(result.map((n) => n.id).toList(), [1]);
    });

    test('"evento" group returns only evento notifications', () {
      final result = provider.notificationsByFilterGroup('evento');
      expect(result.map((n) => n.id).toList(), [5]);
    });

    test('"otros" group returns sistema + general only, excluding '
        'clase, tarea AND evento (each has its own dedicated filter chip)', () {
      final result = provider.notificationsByFilterGroup('otros');
      expect(result.map((n) => n.id).toSet(), {3, 4});
      expect(result.any((n) => n.tipo == 'clase'), isFalse);
      expect(result.any((n) => n.tipo == 'tarea'), isFalse);
      expect(result.any((n) => n.tipo == 'evento'), isFalse);
    });

    test('results are sorted most-recent-first', () {
      final result = provider.notificationsByFilterGroup('otros');
      expect(result.map((n) => n.id).toList(), [3, 4]);
    });
  });

  group('rescheduleAll', () {
    final fixedNow = DateTime(2026, 7, 15, 8, 0); // miércoles 08:00

    late _FakeScheduler scheduler;
    late NotificationProvider schedulingProvider;

    setUp(() {
      scheduler = _FakeScheduler();
      schedulingProvider = NotificationProvider(
        service: mockService,
        cancelNotification: scheduler.cancel,
        scheduleNotification: scheduler.scheduleAt,
      );
    });

    test(
        'schedules reminders only for eligible tasks/classes, skipping past-due and completed tasks',
        () async {
      final dueSoonTask = _task(
        id: 10,
        // Vence mañana: "día antes" cae hoy 20:00, "mismo día" mañana 08:00.
        fechaEntrega: DateTime(2026, 7, 16),
      );
      final pastDueTask = _task(
        id: 11,
        fechaEntrega: DateTime(2026, 7, 10), // ambos avisos ya pasaron
      );
      final completedTask = _task(
        id: 12,
        fechaEntrega: DateTime(2026, 7, 20),
        completada: true,
      );
      final classSchedule = _schedule(
        id: 20,
        dia: 'miercoles',
        horaInicio: '09:00:00', // reminder (30 min before) at 08:30
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask, pastDueTask, completedTask],
        schedules: [classSchedule],
        now: fixedNow,
      );

      // Cancel-antes-de-reprogramar: se cancela SIEMPRE, sin importar si
      // luego se reprograma o no. Cada tarea cancela sus 2 ids posibles
      // (día antes + mismo día); las clases cancelan las 4 ids posibles
      // (una por ocurrencia semanal).
      expect(
        scheduler.cancelledIds,
        containsAll([
          LocalNotificationService.idFor('tarea_10_antes'),
          LocalNotificationService.idFor('tarea_10_mismodia'),
          LocalNotificationService.idFor('tarea_11_antes'),
          LocalNotificationService.idFor('tarea_11_mismodia'),
          LocalNotificationService.idFor('tarea_12_antes'),
          LocalNotificationService.idFor('tarea_12_mismodia'),
          LocalNotificationService.idFor('clase_20_0'),
          LocalNotificationService.idFor('clase_20_1'),
          LocalNotificationService.idFor('clase_20_2'),
          LocalNotificationService.idFor('clase_20_3'),
        ]),
      );

      // Los 2 avisos (día antes + mismo día) de la tarea próxima + las 4
      // ocurrencias semanales de la clase deberían reprogramarse.
      expect(scheduler.scheduled.length, 6);

      final beforeEntry = scheduler.scheduled.firstWhere((s) =>
          s['id'] == LocalNotificationService.idFor('tarea_10_antes'));
      expect(beforeEntry['scheduledDate'], DateTime(2026, 7, 15, 20, 0));
      expect(beforeEntry['channel'], LocalNotificationService.channelTareas);
      expect(beforeEntry['body'], contains('vence mañana'));

      final sameDayEntry = scheduler.scheduled.firstWhere((s) =>
          s['id'] == LocalNotificationService.idFor('tarea_10_mismodia'));
      expect(sameDayEntry['scheduledDate'], DateTime(2026, 7, 16, 8, 0));
      expect(sameDayEntry['channel'], LocalNotificationService.channelTareas);
      expect(sameDayEntry['body'], contains('vence hoy'));

      final classEntries = [0, 1, 2, 3]
          .map((i) => scheduler.scheduled.firstWhere((s) =>
              s['id'] == LocalNotificationService.idFor('clase_20_$i')))
          .toList();
      final expectedDates = [
        DateTime(2026, 7, 15, 8, 30),
        DateTime(2026, 7, 22, 8, 30),
        DateTime(2026, 7, 29, 8, 30),
        DateTime(2026, 8, 5, 8, 30),
      ];
      for (var i = 0; i < 4; i++) {
        expect(classEntries[i]['scheduledDate'], expectedDates[i]);
        expect(classEntries[i]['channel'], LocalNotificationService.channelClases);
      }
    });

    test(
        'schedules 4 distinct-id weekly occurrences per class but only creates '
        'one feed entry (for the nearest occurrence)', () async {
      await schedulingProvider.load(); // sin notificaciones previas en el feed
      final classSchedule = _schedule(
        id: 70,
        dia: 'miercoles',
        horaInicio: '09:00:00',
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: [classSchedule],
        now: fixedNow,
      );

      expect(scheduler.scheduled.length, 4);
      expect(
        scheduler.scheduled.map((s) => s['id']).toSet(),
        {
          LocalNotificationService.idFor('clase_70_0'),
          LocalNotificationService.idFor('clase_70_1'),
          LocalNotificationService.idFor('clase_70_2'),
          LocalNotificationService.idFor('clase_70_3'),
        },
      );

      verify(() => mockService.createNotification(
            tipo: 'clase',
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: 'clase',
            referenciaId: 70,
            fechaProgramada: any(named: 'fechaProgramada'),
          )).called(1);
    });

    test(
        'does not schedule any task reminder when notifTareas is off, but still cancels existing ones',
        () async {
      await schedulingProvider.updatePreferences(
        NotificationPreferences.defaults().copyWith(notifTareas: false),
      );

      final dueSoonTask = _task(
        id: 30,
        fechaEntrega: DateTime(2026, 7, 16),
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );

      expect(scheduler.cancelledIds, containsAll([
        LocalNotificationService.idFor('tarea_30_antes'),
        LocalNotificationService.idFor('tarea_30_mismodia'),
      ]));
      expect(scheduler.scheduled, isEmpty);
    });

    test('does not schedule any reminder for a completed task', () async {
      final completedTask = _task(
        id: 31,
        fechaEntrega: DateTime(2026, 7, 16),
        completada: true,
      );

      await schedulingProvider.rescheduleAll(
        tasks: [completedTask],
        schedules: const [],
        now: fixedNow,
      );

      expect(scheduler.cancelledIds, containsAll([
        LocalNotificationService.idFor('tarea_31_antes'),
        LocalNotificationService.idFor('tarea_31_mismodia'),
      ]));
      expect(scheduler.scheduled, isEmpty);
    });

    test('pushes a class reminder that falls inside quiet hours to the end of the window',
        () async {
      await schedulingProvider.updatePreferences(
        NotificationPreferences.defaults().copyWith(
          horaSilencioInicio: '08:00',
          horaSilencioFin: '09:00',
        ),
      );

      final classSchedule = _schedule(
        id: 40,
        dia: 'miercoles',
        horaInicio: '09:00:00', // reminder sin ajustar caería a las 08:30
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: [classSchedule],
        now: fixedNow,
      );

      // Las 4 ocurrencias semanales caen a las 08:30 de su respectivo día,
      // dentro de la ventana de silencio [08:00, 09:00) -> las 4 se empujan
      // al final de la ventana en vez de cancelarse.
      expect(scheduler.scheduled.length, 4);
      final nearest = scheduler.scheduled.firstWhere(
          (s) => s['id'] == LocalNotificationService.idFor('clase_40_0'));
      expect(nearest['scheduledDate'], DateTime(2026, 7, 15, 9, 0));
    });

    test(
        'persists a feed entry on the backend for a newly-scheduled reminder, '
        'but keeps it hidden locally until its scheduled time actually arrives',
        () async {
      await schedulingProvider.load(); // sin notificaciones previas en el feed
      final dueSoonTask = _task(
        id: 50,
        // Vence mañana: el aviso "día antes" cae hoy a las 20:00 (después
        // de fixedNow 08:00) — `computeReminderTime` garantiza que el
        // recordatorio siempre cae después de `now`, así que esto es el
        // caso general.
        fechaEntrega: DateTime(2026, 7, 16),
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );

      // El recordatorio SÍ se crea en el backend (el más próximo de los dos
      // avisos — "día antes", hoy 20:00 — representa la fila del feed)...
      verify(() => mockService.createNotification(
            tipo: 'tarea',
            titulo: any(named: 'titulo'),
            mensaje: 'Tarea 50 vence mañana',
            referenciaTipo: 'tarea',
            referenciaId: 50,
            fechaProgramada: DateTime(2026, 7, 15, 20, 0),
          )).called(1);

      // ...pero el backend (`getNotifications`/`getUnreadCount`) oculta toda
      // notificación cuya `fecha_programada` siga en el futuro. Mostrarla ya
      // en el feed local mentiría sobre lo que el backend realmente
      // devuelve: el siguiente `load()`/`refresh()` la haría desaparecer
      // hasta que de verdad llegara su hora — el bug reportado ("la
      // notificación de la tarea llegó, después se quitó, y se volvió a
      // mandar").
      expect(
        schedulingProvider.notifications
            .any((n) => n.referenciaTipo == 'tarea' && n.referenciaId == 50),
        isFalse,
      );
    });

    test(
        'the feed entry becomes visible on the next load() once its scheduled time arrives',
        () async {
      await schedulingProvider.load();
      final dueSoonTask = _task(
        id: 51,
        fechaEntrega: DateTime(2026, 7, 16),
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );
      expect(
        schedulingProvider.notifications
            .any((n) => n.referenciaTipo == 'tarea' && n.referenciaId == 51),
        isFalse,
      );

      // Simula que el backend ahora SÍ devuelve la notificación porque ya
      // llegó su `fecha_programada`.
      when(() => mockService.getNotifications()).thenAnswer((_) async => [
            AppNotification(
              id: 200,
              tipo: 'tarea',
              titulo: 'Tarea próxima a vencer',
              mensaje: 'Tarea 51',
              referenciaTipo: 'tarea',
              referenciaId: 51,
              fechaProgramada: DateTime(2026, 7, 15, 9, 0),
              fechaCreacion: DateTime(2026, 7, 15, 8, 0),
            ),
          ]);

      await schedulingProvider.refresh();

      expect(
        schedulingProvider.notifications
            .any((n) => n.referenciaTipo == 'tarea' && n.referenciaId == 51),
        isTrue,
      );
    });

    test(
        'does not create a duplicate feed entry when one already exists for the same reference',
        () async {
      when(() => mockService.getNotifications()).thenAnswer((_) async => [
            AppNotification(
              id: 1,
              tipo: 'tarea',
              titulo: 'Tarea próxima a vencer',
              mensaje: 'Tarea 60',
              leida: false,
              referenciaTipo: 'tarea',
              referenciaId: 60,
              fechaCreacion: DateTime(2026, 7, 15),
            ),
          ]);
      await schedulingProvider.load();

      final dueSoonTask = _task(
        id: 60,
        fechaEntrega: DateTime(2026, 7, 16), // vence mañana -> reminder válido
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );

      verifyNever(() => mockService.createNotification(
            tipo: any(named: 'tipo'),
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: any(named: 'referenciaTipo'),
            referenciaId: any(named: 'referenciaId'),
            fechaProgramada: any(named: 'fechaProgramada'),
          ));
      expect(schedulingProvider.notifications.length, 1);
    });

    test(
        "does not create a feed entry when the class's nearest occurrence isn't today",
        () async {
      await schedulingProvider.load(); // sin notificaciones previas en el feed
      final mondayClass = _schedule(
        id: 80,
        dia: 'lunes', // fixedNow es miércoles: la próxima ocurrencia es en días
        horaInicio: '09:00:00',
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: [mondayClass],
        now: fixedNow,
      );

      // Las 4 alarmas locales sí se programan (el SO las dispara igual el
      // día que corresponda)...
      expect(scheduler.scheduled.length, 4);
      // ...pero como la ocurrencia más próxima no es hoy, no debe aparecer en
      // el feed dentro de la app. Antes de este fix, cualquier clase con una
      // próxima ocurrencia futura (sin importar el día) generaba una fila acá
      // apenas se abría la app, mezclando clases de días distintos.
      verifyNever(() => mockService.createNotification(
            tipo: 'clase',
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: 'clase',
            referenciaId: 80,
            fechaProgramada: any(named: 'fechaProgramada'),
          ));
      expect(
        schedulingProvider.notifications
            .any((n) => n.referenciaTipo == 'clase' && n.referenciaId == 80),
        isFalse,
      );
    });

    test(
        'an already-read, same-day class feed entry survives rescheduleAll '
        'later that day instead of being deleted/recreated as unread — this '
        'was the reported bug: "notificaciones que ya había visto vuelven a '
        'salir" caused by treating "already due" the same as "stale"',
        () async {
      when(() => mockService.getNotifications()).thenAnswer((_) async => [
            AppNotification(
              id: 9,
              tipo: 'clase',
              titulo: 'Clase próxima a iniciar',
              mensaje: 'Cálculo · 09:00 - 10:00',
              leida: true, // el usuario ya la vio
              referenciaTipo: 'clase',
              referenciaId: 110,
              fechaProgramada: DateTime(2026, 7, 15, 8, 30), // hoy, ya pasó
              fechaCreacion: DateTime(2026, 7, 15, 8, 0),
            ),
          ]);
      await schedulingProvider.load();

      final wednesdayClass = _schedule(
        id: 110,
        dia: 'miercoles',
        horaInicio: '09:00:00', // mismo reminder de siempre: 08:30 hoy
      );

      // Simula reabrir la app más tarde el MISMO día (12:00), horas después
      // de que el recordatorio de las 08:30 ya pasara.
      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: [wednesdayClass],
        now: DateTime(2026, 7, 15, 12, 0),
      );

      verifyNever(() => mockService.deleteNotification(9));
      verifyNever(() => mockService.createNotification(
            tipo: any(named: 'tipo'),
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: any(named: 'referenciaTipo'),
            referenciaId: any(named: 'referenciaId'),
            fechaProgramada: any(named: 'fechaProgramada'),
          ));

      final entry = schedulingProvider.notifications.firstWhere(
          (n) => n.referenciaTipo == 'clase' && n.referenciaId == 110);
      expect(entry.id, 9);
      expect(entry.leida, isTrue);
    });

    test(
        'expires a stale class feed entry (from a previous week) instead of leaving it forever',
        () async {
      when(() => mockService.getNotifications()).thenAnswer((_) async => [
            AppNotification(
              id: 5,
              tipo: 'clase',
              titulo: 'Clase próxima a iniciar',
              mensaje: 'Cálculo · 09:00 - 10:00',
              leida: false,
              referenciaTipo: 'clase',
              referenciaId: 90,
              fechaProgramada: DateTime(2026, 7, 8, 8, 30), // semana pasada
              fechaCreacion: DateTime(2026, 7, 8),
            ),
          ]);
      await schedulingProvider.load();

      final wednesdayClass = _schedule(
        id: 90,
        dia: 'miercoles',
        horaInicio: '09:00:00',
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: [wednesdayClass],
        now: fixedNow,
      );

      // La fila vencida (de la semana pasada) se borra del backend...
      verify(() => mockService.deleteNotification(5)).called(1);
      // ...y se crea una fila nueva en el backend para la ocurrencia de hoy
      // (reminder a las 08:30, después de fixedNow 08:00 — todavía no
      // "llegó", así que el backend la mantiene oculta hasta esa hora, y el
      // cliente no la muestra optimistamente; ver el test de arriba sobre
      // por qué). Lo importante acá es que la vieja NO se queda pegada para
      // siempre junto a la nueva.
      verify(() => mockService.createNotification(
            tipo: 'clase',
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: 'clase',
            referenciaId: 90,
            fechaProgramada: any(named: 'fechaProgramada'),
          )).called(1);
      final classEntries = schedulingProvider.notifications
          .where((n) => n.referenciaTipo == 'clase' && n.referenciaId == 90)
          .toList();
      expect(classEntries, isEmpty);
    });

    test(
        'expires a stale task feed entry (already past due) instead of leaving '
        'it forever, and does not replace it since the task is now overdue',
        () async {
      when(() => mockService.getNotifications()).thenAnswer((_) async => [
            AppNotification(
              id: 6,
              tipo: 'tarea',
              titulo: 'Tarea próxima a vencer',
              mensaje: 'Entrega de laboratorio',
              leida: false,
              referenciaTipo: 'tarea',
              referenciaId: 95,
              fechaProgramada: DateTime(2026, 7, 1, 7, 0), // ya venció
              fechaCreacion: DateTime(2026, 7, 1),
            ),
          ]);
      await schedulingProvider.load();

      final overdueTask = _task(
        id: 95,
        fechaEntrega: DateTime(2026, 7, 10, 10, 0), // antes de fixedNow (15/7)
      );

      await schedulingProvider.rescheduleAll(
        tasks: [overdueTask],
        schedules: const [],
        now: fixedNow,
      );

      // La fila vieja ("Tarea próxima a vencer" de una tarea que ya venció
      // hace días) se borra del backend...
      verify(() => mockService.deleteNotification(6)).called(1);
      // ...y NO se reemplaza por una nueva: la tarea ya está vencida, así
      // que `computeReminderTime` no calcula ningún recordatorio nuevo para
      // ella (mismo motivo que el test "skipping past-due tasks" de arriba).
      verifyNever(() => mockService.createNotification(
            tipo: 'tarea',
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: 'tarea',
            referenciaId: 95,
            fechaProgramada: any(named: 'fechaProgramada'),
          ));
      final taskEntries = schedulingProvider.notifications
          .where((n) => n.referenciaTipo == 'tarea' && n.referenciaId == 95)
          .toList();
      expect(taskEntries, isEmpty);
    });

    test(
        'schedules a reminder for an event using its OWN minutosAntesRecordatorio '
        '(no global preference involved) and creates a feed entry once visible',
        () async {
      await schedulingProvider.load();
      final event = _event(
        id: 200,
        fecha: DateTime(2026, 7, 15),
        horaInicio: const TimeOfDay(hour: 9, minute: 0),
        recordatorio: true,
        minutosAntesRecordatorio: 15, // no es ninguno de los presets globales
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: const [],
        events: [event],
        now: fixedNow, // 08:00 -> reminder a las 08:45, todavía futuro
      );

      expect(scheduler.cancelledIds,
          contains(LocalNotificationService.idFor('evento_200')));
      final scheduled = scheduler.scheduled.single;
      expect(scheduled['id'], LocalNotificationService.idFor('evento_200'));
      expect(scheduled['scheduledDate'], DateTime(2026, 7, 15, 8, 45));
      expect(scheduled['channel'], LocalNotificationService.channelEventos);

      verify(() => mockService.createNotification(
            tipo: 'evento',
            titulo: any(named: 'titulo'),
            mensaje: 'Evento 200',
            referenciaTipo: 'evento',
            referenciaId: 200,
            fechaProgramada: DateTime(2026, 7, 15, 8, 45),
          )).called(1);
    });

    test('does not schedule anything for an event with recordatorio off',
        () async {
      final event = _event(
        id: 201,
        fecha: DateTime(2026, 7, 16),
        recordatorio: false,
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: const [],
        events: [event],
        now: fixedNow,
      );

      expect(scheduler.cancelledIds,
          contains(LocalNotificationService.idFor('evento_201')));
      expect(scheduler.scheduled, isEmpty);
      verifyNever(() => mockService.createNotification(
            tipo: any(named: 'tipo'),
            titulo: any(named: 'titulo'),
            mensaje: any(named: 'mensaje'),
            referenciaTipo: any(named: 'referenciaTipo'),
            referenciaId: any(named: 'referenciaId'),
            fechaProgramada: any(named: 'fechaProgramada'),
          ));
    });

    test(
        'defaults to 8:00 AM that day for an all-day event with no horaInicio',
        () async {
      final event = _event(
        id: 202,
        fecha: DateTime(2026, 7, 16), // mañana, sin hora -> objetivo 08:00
        horaInicio: null,
        minutosAntesRecordatorio: 30,
      );

      await schedulingProvider.rescheduleAll(
        tasks: const [],
        schedules: const [],
        events: [event],
        now: fixedNow,
      );

      final scheduled = scheduler.scheduled.single;
      expect(scheduled['scheduledDate'], DateTime(2026, 7, 16, 7, 30));
    });
  });

  group('notifGenerales filtering', () {
    List<AppNotification> mixedNotifications() => [
          AppNotification(
            id: 1,
            tipo: 'tarea',
            titulo: 'Tarea 1',
            mensaje: 'Mensaje 1',
            leida: false,
            fechaCreacion: DateTime(2026, 7, 15, 9, 0),
          ),
          AppNotification(
            id: 2,
            tipo: 'general',
            titulo: 'General 1',
            mensaje: 'Mensaje 2',
            leida: false,
            fechaCreacion: DateTime(2026, 7, 15, 8, 0),
          ),
          AppNotification(
            id: 3,
            tipo: 'sistema',
            titulo: 'Sistema 1',
            mensaje: 'Mensaje 3',
            leida: false,
            fechaCreacion: DateTime(2026, 7, 15, 7, 0),
          ),
        ];

    test('keeps general/sistema notifications when notifGenerales is on',
        () async {
      when(() => mockService.getNotifications())
          .thenAnswer((_) async => mixedNotifications());

      await provider.loadPreferences(); // defaults: notifGenerales true
      await provider.load();

      expect(provider.notifications.map((n) => n.id), containsAll([1, 2, 3]));
    });

    test('hides general/sistema notifications when notifGenerales is off',
        () async {
      when(() => mockService.getNotifications())
          .thenAnswer((_) async => mixedNotifications());
      when(() => mockService.getPreferences()).thenAnswer(
        (_) async => NotificationPreferences.defaults()
            .copyWith(notifGenerales: false),
      );

      await provider.loadPreferences();
      await provider.load();

      expect(provider.notifications.map((n) => n.id).toList(), [1]);
      expect(
        provider.notifications.any(
            (n) => n.tipo == 'general' || n.tipo == 'sistema'),
        isFalse,
      );
    });
  });
}
