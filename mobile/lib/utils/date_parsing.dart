// ============================================
// UTILIDAD: PARSEO DE FECHAS DE CALENDARIO (columnas DATE)
// ============================================
//
// El backend serializa columnas MySQL `DATE` (sin componente de hora) como
// ISO-8601 con sufijo `Z` — p.ej. `"2026-07-15T00:00:00.000Z"` — porque
// mysql2 las entrega como `Date` de JS y `res.json()` llama a
// `Date.prototype.toJSON()` (siempre UTC).
//
// Si se parsea ese string con `DateTime.parse` normal, Dart lo interpreta
// como un instante UTC real. En una zona horaria detrás de UTC (Colombia,
// UTC-5), la medianoche UTC de una fecha es en realidad la noche ANTERIOR
// en hora local — así que una tarea/evento/nota con fecha "hoy" terminaba
// comparándose como si fuera "ayer", apareciendo vencida antes de tiempo y
// desalineando cualquier cálculo de recordatorio.
//
// `fecha_entrega` (tareas), `fecha` (eventos de calendario) y
// `fecha_evaluacion` (calificaciones) son fechas de calendario puras — la
// hora no tiene significado de negocio — así que se parsean tomando solo
// los componentes año-mes-día y construyendo un `DateTime` LOCAL a
// medianoche. Esto es distinto de columnas `TIMESTAMP`/`DATETIME` como
// `fecha_creacion` o las sesiones de Pomodoro, donde el instante real SÍ
// importa y `DateTime.parse`/`tryParse` normal sigue siendo correcto.

/// Parsea una fecha de calendario (columna `DATE`) como fecha LOCAL,
/// ignorando cualquier zona horaria presente en el string.
DateTime parseDateOnly(String value) {
  final datePart = value.split('T').first;
  final parts = datePart.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Variante nullable de [parseDateOnly] para campos `DATE` opcionales.
/// Devuelve `null` si [value] es `null` o no se puede parsear.
DateTime? tryParseDateOnly(dynamic value) {
  if (value == null) return null;
  try {
    return parseDateOnly(value.toString());
  } catch (_) {
    return null;
  }
}
