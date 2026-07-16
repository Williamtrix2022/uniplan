import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniplan/models/app_notification.dart';
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
        fechaEntrega: DateTime(2026, 7, 15, 10, 0), // reminder at 09:00
      );
      final pastDueTask = _task(
        id: 11,
        fechaEntrega: DateTime(2026, 7, 10, 10, 0), // reminder already passed
      );
      final completedTask = _task(
        id: 12,
        fechaEntrega: DateTime(2026, 7, 20, 10, 0),
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
      // luego se reprograma o no.
      expect(
        scheduler.cancelledIds,
        containsAll([
          LocalNotificationService.idFor('tarea_10'),
          LocalNotificationService.idFor('tarea_11'),
          LocalNotificationService.idFor('tarea_12'),
          LocalNotificationService.idFor('clase_20'),
        ]),
      );

      // Solo la tarea próxima a vencer y la clase deberían reprogramarse.
      expect(scheduler.scheduled.length, 2);

      final taskEntry = scheduler.scheduled
          .firstWhere((s) => s['id'] == LocalNotificationService.idFor('tarea_10'));
      expect(taskEntry['scheduledDate'], DateTime(2026, 7, 15, 9, 0));
      expect(taskEntry['channel'], LocalNotificationService.channelTareas);

      final classEntry = scheduler.scheduled.firstWhere(
          (s) => s['id'] == LocalNotificationService.idFor('clase_20'));
      expect(classEntry['scheduledDate'], DateTime(2026, 7, 15, 8, 30));
      expect(classEntry['channel'], LocalNotificationService.channelClases);
    });

    test(
        'does not schedule any task reminder when notifTareas is off, but still cancels existing ones',
        () async {
      await schedulingProvider.updatePreferences(
        NotificationPreferences.defaults().copyWith(notifTareas: false),
      );

      final dueSoonTask = _task(
        id: 30,
        fechaEntrega: DateTime(2026, 7, 15, 10, 0),
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );

      expect(scheduler.cancelledIds,
          contains(LocalNotificationService.idFor('tarea_30')));
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

      expect(scheduler.scheduled.length, 1);
      // 08:30 cae dentro de la ventana de silencio [08:00, 09:00) -> se
      // empuja al final de la ventana en vez de cancelarse.
      expect(scheduler.scheduled.first['scheduledDate'],
          DateTime(2026, 7, 15, 9, 0));
    });

    test(
        'creates a feed entry (bell / notification center) for a newly-scheduled reminder',
        () async {
      await schedulingProvider.load(); // sin notificaciones previas en el feed
      final dueSoonTask = _task(
        id: 50,
        fechaEntrega: DateTime(2026, 7, 15, 10, 0),
      );

      await schedulingProvider.rescheduleAll(
        tasks: [dueSoonTask],
        schedules: const [],
        now: fixedNow,
      );

      verify(() => mockService.createNotification(
            tipo: 'tarea',
            titulo: any(named: 'titulo'),
            mensaje: 'Tarea 50',
            referenciaTipo: 'tarea',
            referenciaId: 50,
            fechaProgramada: any(named: 'fechaProgramada'),
          )).called(1);
      expect(
        schedulingProvider.notifications
            .any((n) => n.referenciaTipo == 'tarea' && n.referenciaId == 50),
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
        fechaEntrega: DateTime(2026, 7, 15, 10, 0),
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
