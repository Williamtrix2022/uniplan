import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan/models/task.dart';

Task _task({bool completada = false, String estado = 'pendiente'}) => Task(
      id: 1,
      idEstudiante: 1,
      titulo: 'Tarea de prueba',
      fechaEntrega: DateTime(2026, 1, 1),
      completada: completada,
      estado: estado,
    );

void main() {
  group('Task.isCompleted', () {
    test('is true when completada is true, regardless of estado', () {
      expect(_task(completada: true, estado: 'pendiente').isCompleted, isTrue);
    });

    test('is true when estado is "completada", even if completada is false '
        '— this is the actual bug: editar el estado a Completada desde el '
        'formulario no toca la columna `completada`', () {
      expect(_task(completada: false, estado: 'completada').isCompleted, isTrue);
    });

    test('is false when neither completada nor estado indicate completion', () {
      expect(_task(completada: false, estado: 'pendiente').isCompleted, isFalse);
      expect(_task(completada: false, estado: 'en_progreso').isCompleted, isFalse);
    });
  });
}
