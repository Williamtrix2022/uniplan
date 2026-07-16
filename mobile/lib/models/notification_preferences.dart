// ============================================
// MODELO DE PREFERENCIAS DE NOTIFICACIONES
// ============================================

class NotificationPreferences {
  final bool notifTareas;
  final bool notifClases;
  final bool notifGenerales;
  final int minutosAntesTarea;
  final int minutosAntesClase;
  final bool sonidoActivo;
  final String? horaSilencioInicio; // "HH:mm" o null (sin horario de silencio)
  final String? horaSilencioFin; // "HH:mm" o null

  NotificationPreferences({
    this.notifTareas = true,
    this.notifClases = true,
    this.notifGenerales = true,
    this.minutosAntesTarea = 60,
    this.minutosAntesClase = 30,
    this.sonidoActivo = true,
    this.horaSilencioInicio,
    this.horaSilencioFin,
  });

  /// Valores por defecto cuando el backend aún no tiene preferencias guardadas.
  factory NotificationPreferences.defaults() => NotificationPreferences();

  bool get tieneHorarioSilencio =>
      horaSilencioInicio != null && horaSilencioFin != null;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notifTareas: json['notif_tareas'] == null
          ? true
          : (json['notif_tareas'] == 1 || json['notif_tareas'] == true),
      notifClases: json['notif_clases'] == null
          ? true
          : (json['notif_clases'] == 1 || json['notif_clases'] == true),
      notifGenerales: json['notif_generales'] == null
          ? true
          : (json['notif_generales'] == 1 || json['notif_generales'] == true),
      minutosAntesTarea:
          _parseInt(json['minutos_antes_tarea']) ?? 60,
      minutosAntesClase:
          _parseInt(json['minutos_antes_clase']) ?? 30,
      sonidoActivo: json['sonido_activo'] == null
          ? true
          : (json['sonido_activo'] == 1 || json['sonido_activo'] == true),
      horaSilencioInicio: json['hora_silencio_inicio'],
      horaSilencioFin: json['hora_silencio_fin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notif_tareas': notifTareas,
      'notif_clases': notifClases,
      'notif_generales': notifGenerales,
      'minutos_antes_tarea': minutosAntesTarea,
      'minutos_antes_clase': minutosAntesClase,
      'sonido_activo': sonidoActivo,
      'hora_silencio_inicio': horaSilencioInicio,
      'hora_silencio_fin': horaSilencioFin,
    };
  }

  NotificationPreferences copyWith({
    bool? notifTareas,
    bool? notifClases,
    bool? notifGenerales,
    int? minutosAntesTarea,
    int? minutosAntesClase,
    bool? sonidoActivo,
    String? horaSilencioInicio,
    String? horaSilencioFin,
    bool clearHoraSilencio = false,
  }) {
    return NotificationPreferences(
      notifTareas: notifTareas ?? this.notifTareas,
      notifClases: notifClases ?? this.notifClases,
      notifGenerales: notifGenerales ?? this.notifGenerales,
      minutosAntesTarea: minutosAntesTarea ?? this.minutosAntesTarea,
      minutosAntesClase: minutosAntesClase ?? this.minutosAntesClase,
      sonidoActivo: sonidoActivo ?? this.sonidoActivo,
      horaSilencioInicio: clearHoraSilencio
          ? null
          : (horaSilencioInicio ?? this.horaSilencioInicio),
      horaSilencioFin: clearHoraSilencio
          ? null
          : (horaSilencioFin ?? this.horaSilencioFin),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
