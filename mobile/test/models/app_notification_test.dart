import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    test('fromJson parses a full backend payload', () {
      final json = {
        'id': 7,
        'tipo': 'tarea',
        'titulo': 'Tarea próxima a vencer',
        'mensaje': 'Entrega de Cálculo II mañana',
        'leida': false,
        'referencia_tipo': 'tarea',
        'referencia_id': 42,
        'fecha_programada': '2026-07-16T09:00:00.000',
        'fecha_creacion': '2026-07-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 7);
      expect(notification.tipo, 'tarea');
      expect(notification.titulo, 'Tarea próxima a vencer');
      expect(notification.mensaje, 'Entrega de Cálculo II mañana');
      expect(notification.leida, isFalse);
      expect(notification.referenciaTipo, 'tarea');
      expect(notification.referenciaId, 42);
      expect(notification.fechaProgramada, DateTime.parse('2026-07-16T09:00:00.000'));
      expect(notification.fechaCreacion, DateTime.parse('2026-07-15T10:00:00.000'));
      expect(notification.tipoLabel, 'Tarea');
    });

    test('fromJson tolerates missing optional fields', () {
      final json = {
        'id': 1,
        'titulo': 'Aviso',
        'mensaje': 'Mensaje genérico',
        'fecha_creacion': '2026-07-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.tipo, 'general');
      expect(notification.leida, isFalse);
      expect(notification.referenciaTipo, isNull);
      expect(notification.referenciaId, isNull);
      expect(notification.fechaProgramada, isNull);
      expect(notification.tipoLabel, 'General');
    });

    test('fromJson accepts leida as 1/0 (MySQL boolean)', () {
      final json = {
        'id': 2,
        'tipo': 'clase',
        'titulo': 'x',
        'mensaje': 'y',
        'leida': 1,
        'fecha_creacion': '2026-07-15T10:00:00.000',
      };

      expect(AppNotification.fromJson(json).leida, isTrue);
    });

    test('toJson → fromJson round trip preserves all fields', () {
      final original = AppNotification(
        id: 10,
        tipo: 'clase',
        titulo: 'Clase próxima a iniciar',
        mensaje: 'Física I en 30 minutos',
        leida: true,
        referenciaTipo: 'clase',
        referenciaId: 5,
        fechaProgramada: DateTime(2026, 7, 16, 8, 30),
        fechaCreacion: DateTime(2026, 7, 15, 10, 0),
      );

      final roundTripped = AppNotification.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.tipo, original.tipo);
      expect(roundTripped.titulo, original.titulo);
      expect(roundTripped.mensaje, original.mensaje);
      expect(roundTripped.leida, original.leida);
      expect(roundTripped.referenciaTipo, original.referenciaTipo);
      expect(roundTripped.referenciaId, original.referenciaId);
      expect(roundTripped.fechaProgramada, original.fechaProgramada);
      expect(roundTripped.fechaCreacion, original.fechaCreacion);
    });

    test('copyWith overrides only the given fields', () {
      final original = AppNotification(
        id: 1,
        tipo: 'general',
        titulo: 'A',
        mensaje: 'B',
        fechaCreacion: DateTime(2026, 7, 15),
      );

      final updated = original.copyWith(leida: true);

      expect(updated.leida, isTrue);
      expect(updated.id, original.id);
      expect(updated.titulo, original.titulo);
    });
  });
}
