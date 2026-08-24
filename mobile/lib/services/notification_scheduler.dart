// ============================================
// LÓGICA PURA DE PROGRAMACIÓN DE RECORDATORIOS
// ============================================
//
// Este archivo NO hace I/O ni llama al plugin de notificaciones a propósito:
// es la lógica de negocio más importante del sprint y debe ser trivial de
// testear exhaustivamente. La programación real (llamadas a
// flutter_local_notifications) vive en `LocalNotificationService`, orquestada
// desde `NotificationProvider`.

/// Días de la semana tal como los usa `Schedule.dia` (español, minúsculas,
/// sin tilde en 'miercoles' — mismo formato que persiste el backend).
const Map<String, int> weekdayIndexEs = {
  'lunes': DateTime.monday,
  'martes': DateTime.tuesday,
  'miercoles': DateTime.wednesday,
  'jueves': DateTime.thursday,
  'viernes': DateTime.friday,
  'sabado': DateTime.saturday,
  'domingo': DateTime.sunday,
};

/// Calcula el instante en que se debería programar un recordatorio.
///
/// Devuelve `null` cuando NO se debe programar nada:
/// - el recordatorio calculado (`targetDateTime - minutesBefore`) ya pasó
///   (o es exactamente ahora) respecto a [now]. Esto ocurrirá con
///   frecuencia para tareas cuya fecha de entrega ya venció.
///
/// Comportamiento de horario de silencio (decisión de diseño explícita,
/// no un detalle accidental): si el recordatorio cae dentro de la ventana
/// de silencio, se EMPUJA al final de esa ventana en lugar de cancelarse.
/// El usuario igual recibe el recordatorio, solo que no mientras el
/// silencio está activo. La ventana es `[quietHoursStart, quietHoursEnd)`
/// (inicio inclusivo, fin exclusivo) y soporta cruzar medianoche
/// (p.ej. "22:00" a "07:00").
DateTime? computeReminderTime({
  required DateTime targetDateTime,
  required int minutesBefore,
  required DateTime now,
  String? quietHoursStart,
  String? quietHoursEnd,
}) {
  final reminder = targetDateTime.subtract(Duration(minutes: minutesBefore));

  if (!reminder.isAfter(now)) {
    return null;
  }

  if (quietHoursStart != null && quietHoursEnd != null) {
    return _pushOutsideQuietHours(reminder, quietHoursStart, quietHoursEnd);
  }

  return reminder;
}

DateTime _pushOutsideQuietHours(
  DateTime reminder,
  String quietHoursStart,
  String quietHoursEnd,
) {
  final startMinutes = _parseHHmmToMinutes(quietHoursStart);
  final endMinutes = _parseHHmmToMinutes(quietHoursEnd);
  if (startMinutes == null || endMinutes == null) return reminder;

  // Ventana degenerada (mismo valor de inicio y fin): se interpreta como
  // "sin horario de silencio efectivo" para evitar bloquear todo el día.
  if (startMinutes == endMinutes) return reminder;

  final reminderMinutes = reminder.hour * 60 + reminder.minute;
  final wraps = startMinutes > endMinutes;

  final inQuietWindow = wraps
      ? (reminderMinutes >= startMinutes || reminderMinutes < endMinutes)
      : (reminderMinutes >= startMinutes && reminderMinutes < endMinutes);

  if (!inQuietWindow) return reminder;

  final endHour = endMinutes ~/ 60;
  final endMinute = endMinutes % 60;

  if (!wraps) {
    // Ventana normal (no cruza medianoche): empuja al final, mismo día.
    return DateTime(
      reminder.year,
      reminder.month,
      reminder.day,
      endHour,
      endMinute,
    );
  }

  // Ventana cruza medianoche (p.ej. 22:00–07:00):
  // - si el recordatorio cae ANTES de medianoche (>= start), la ventana
  //   termina al día SIGUIENTE a la hora de fin.
  // - si cae DESPUÉS de medianoche (< end), la ventana ya empezó la noche
  //   anterior y termina el MISMO día a la hora de fin.
  if (reminderMinutes >= startMinutes) {
    final nextDay = reminder.add(const Duration(days: 1));
    return DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      endHour,
      endMinute,
    );
  }

  return DateTime(
    reminder.year,
    reminder.month,
    reminder.day,
    endHour,
    endMinute,
  );
}

int? _parseHHmmToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

/// Calcula la próxima ocurrencia de un bloque de horario semanal (clase)
/// a partir de [now]. `horarios` son recurrentes semanalmente, no fechas
/// puntuales, así que hay que proyectar el próximo día de la semana que
/// coincida con [dia] a la hora [horaInicio].
///
/// [dia] usa el mismo string en español que `Schedule.dia` (p.ej. 'lunes').
/// [horaInicio] acepta "HH:mm" o "HH:mm:ss" (formato que entrega el backend
/// desde una columna TIME de MySQL).
///
/// Si el bloque de hoy ya pasó, se devuelve la ocurrencia de la semana
/// siguiente. Devuelve `null` si [dia] u [horaInicio] no son reconocibles.
DateTime? nextWeeklyOccurrence({
  required String dia,
  required String horaInicio,
  required DateTime now,
}) {
  final targetWeekday = weekdayIndexEs[dia.toLowerCase()];
  if (targetWeekday == null) return null;

  final timeParts = horaInicio.split(':');
  if (timeParts.length < 2) return null;
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if (hour == null || minute == null) return null;

  final daysUntil = (targetWeekday - now.weekday) % 7;

  var candidate = DateTime(now.year, now.month, now.day, hour, minute)
      .add(Duration(days: daysUntil));

  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 7));
  }

  return candidate;
}

/// Calcula las próximas [count] ocurrencias semanales de un bloque de
/// horario, espaciadas 7 días entre sí a partir de la primera ocurrencia
/// (la que devolvería `nextWeeklyOccurrence`).
///
/// Existe para que `rescheduleAll` pueda programar varias semanas de
/// recordatorios de una sola vez — así la cobertura no depende de que el
/// usuario abra la app cada semana (ver comentario en `rescheduleAll`).
///
/// Mismo contrato de entrada inválida que `nextWeeklyOccurrence`: si [dia]
/// u [horaInicio] no son reconocibles, devuelve una lista vacía (aquí no
/// hay un único valor ausente que representar con `null`).
List<DateTime> nextWeeklyOccurrences({
  required String dia,
  required String horaInicio,
  required DateTime now,
  int count = 4,
}) {
  final first = nextWeeklyOccurrence(dia: dia, horaInicio: horaInicio, now: now);
  if (first == null) return [];

  return List<DateTime>.generate(
    count,
    (i) => first.add(Duration(days: 7 * i)),
  );
}
