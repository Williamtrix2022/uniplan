// ============================================
// MODELO DE SESIÓN POMODORO
// ============================================

class PomodoroSession {
  final int? id;
  final int? idEstudiante;
  final int? idMateria;
  final int duracionTrabajo;
  final int duracionDescanso;
  final int ciclosCompletados;
  final int tiempoTotalEstudio;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool completada;
  final String? notas;
  final String? materiaNombre;
  final String? materiaColor;

  PomodoroSession({
    this.id,
    this.idEstudiante,
    this.idMateria,
    required this.duracionTrabajo,
    required this.duracionDescanso,
    this.ciclosCompletados = 0,
    this.tiempoTotalEstudio = 0,
    required this.fechaInicio,
    this.fechaFin,
    this.completada = false,
    this.notas,
    this.materiaNombre,
    this.materiaColor,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      idEstudiante: json['id_estudiante'],
      idMateria: json['id_materia'],
      duracionTrabajo: json['duracion_trabajo'] ?? 25,
      duracionDescanso: json['duracion_descanso'] ?? 5,
      ciclosCompletados: json['ciclos_completados'] ?? 0,
      tiempoTotalEstudio: json['tiempo_total_estudio'] ?? 0,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin']) 
          : null,
      completada: json['completada'] == 1 || json['completada'] == true,
      notas: json['notas'],
      materiaNombre: json['materia_nombre'],
      materiaColor: json['materia_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idEstudiante != null) 'id_estudiante': idEstudiante,
      'id_materia': idMateria,
      'duracion_trabajo': duracionTrabajo,
      'duracion_descanso': duracionDescanso,
      'ciclos_completados': ciclosCompletados,
      'tiempo_total_estudio': tiempoTotalEstudio,
      'fecha_inicio': fechaInicio.toIso8601String(),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String(),
      'completada': completada,
      'notas': notas,
    };
  }

  PomodoroSession copyWith({
    int? id,
    int? idEstudiante,
    int? idMateria,
    int? duracionTrabajo,
    int? duracionDescanso,
    int? ciclosCompletados,
    int? tiempoTotalEstudio,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? completada,
    String? notas,
    String? materiaNombre,
    String? materiaColor,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      idMateria: idMateria ?? this.idMateria,
      duracionTrabajo: duracionTrabajo ?? this.duracionTrabajo,
      duracionDescanso: duracionDescanso ?? this.duracionDescanso,
      ciclosCompletados: ciclosCompletados ?? this.ciclosCompletados,
      tiempoTotalEstudio: tiempoTotalEstudio ?? this.tiempoTotalEstudio,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      completada: completada ?? this.completada,
      notas: notas ?? this.notas,
      materiaNombre: materiaNombre ?? this.materiaNombre,
      materiaColor: materiaColor ?? this.materiaColor,
    );
  }
}