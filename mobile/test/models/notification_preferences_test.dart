import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('defaults() matches the documented default values', () {
      final prefs = NotificationPreferences.defaults();

      expect(prefs.notifTareas, isTrue);
      expect(prefs.notifClases, isTrue);
      expect(prefs.notifGenerales, isTrue);
      expect(prefs.minutosAntesTarea, 60);
      expect(prefs.minutosAntesClase, 30);
      expect(prefs.sonidoActivo, isTrue);
      expect(prefs.horaSilencioInicio, isNull);
      expect(prefs.horaSilencioFin, isNull);
      expect(prefs.tieneHorarioSilencio, isFalse);
    });

    test('fromJson parses a full backend payload', () {
      final json = {
        'notif_tareas': false,
        'notif_clases': true,
        'notif_generales': false,
        'minutos_antes_tarea': 120,
        'minutos_antes_clase': 15,
        'sonido_activo': false,
        'hora_silencio_inicio': '22:00',
        'hora_silencio_fin': '07:00',
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.notifTareas, isFalse);
      expect(prefs.notifClases, isTrue);
      expect(prefs.notifGenerales, isFalse);
      expect(prefs.minutosAntesTarea, 120);
      expect(prefs.minutosAntesClase, 15);
      expect(prefs.sonidoActivo, isFalse);
      expect(prefs.horaSilencioInicio, '22:00');
      expect(prefs.horaSilencioFin, '07:00');
      expect(prefs.tieneHorarioSilencio, isTrue);
    });

    test('fromJson falls back to defaults for missing fields', () {
      final prefs = NotificationPreferences.fromJson(const {});

      expect(prefs.notifTareas, isTrue);
      expect(prefs.minutosAntesTarea, 60);
      expect(prefs.minutosAntesClase, 30);
      expect(prefs.horaSilencioInicio, isNull);
    });

    test('fromJson tolerates string-encoded integers (MySQL DECIMAL/INT)',
        () {
      final prefs = NotificationPreferences.fromJson(const {
        'minutos_antes_tarea': '90',
        'minutos_antes_clase': '10',
      });

      expect(prefs.minutosAntesTarea, 90);
      expect(prefs.minutosAntesClase, 10);
    });

    test('toJson → fromJson round trip preserves all fields', () {
      final original = NotificationPreferences(
        notifTareas: false,
        notifClases: false,
        notifGenerales: true,
        minutosAntesTarea: 45,
        minutosAntesClase: 20,
        sonidoActivo: false,
        horaSilencioInicio: '23:00',
        horaSilencioFin: '06:30',
      );

      final roundTripped =
          NotificationPreferences.fromJson(original.toJson());

      expect(roundTripped.notifTareas, original.notifTareas);
      expect(roundTripped.notifClases, original.notifClases);
      expect(roundTripped.notifGenerales, original.notifGenerales);
      expect(roundTripped.minutosAntesTarea, original.minutosAntesTarea);
      expect(roundTripped.minutosAntesClase, original.minutosAntesClase);
      expect(roundTripped.sonidoActivo, original.sonidoActivo);
      expect(roundTripped.horaSilencioInicio, original.horaSilencioInicio);
      expect(roundTripped.horaSilencioFin, original.horaSilencioFin);
    });

    test('copyWith(clearHoraSilencio: true) clears both quiet-hour fields',
        () {
      final withQuietHours = NotificationPreferences(
        horaSilencioInicio: '22:00',
        horaSilencioFin: '07:00',
      );

      final cleared =
          withQuietHours.copyWith(clearHoraSilencio: true);

      expect(cleared.horaSilencioInicio, isNull);
      expect(cleared.horaSilencioFin, isNull);
      expect(cleared.tieneHorarioSilencio, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final original = NotificationPreferences.defaults();
      final updated = original.copyWith(minutosAntesTarea: 15);

      expect(updated.minutosAntesTarea, 15);
      expect(updated.minutosAntesClase, original.minutosAntesClase);
      expect(updated.notifTareas, original.notifTareas);
    });
  });
}
