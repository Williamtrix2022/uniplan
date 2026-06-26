// ============================================
// MODELO DE HORARIO SEMANAL
// ============================================

import 'package:flutter/material.dart';

class Schedule {
  final int id;
  final int idEstudiante;
  final int idMateria;
  final String dia;
  final String horaInicio; // formato "HH:MM:SS" proveniente de MySQL TIME
  final String horaFin;    // formato "HH:MM:SS" proveniente de MySQL TIME
  final String? aula;
  final bool activo;
  final DateTime fechaCreacion;
  final String? materiaNombre;
  final String? materiaColor;
  final String? materiaProfesor;

  Schedule({
    required this.id,
    required this.idEstudiante,
    required this.idMateria,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    this.aula,
    this.activo = true,
    required this.fechaCreacion,
    this.materiaNombre,
    this.materiaColor,
    this.materiaProfesor,
  });

  // ── Getters de conveniencia ──────────────────

  /// Convierte "HH:MM:SS" a TimeOfDay para posicionar bloques en la grilla
  TimeOfDay get horaInicioTime => _parseTime(horaInicio);
  TimeOfDay get horaFinTime    => _parseTime(horaFin);

  /// Versión "HH:MM" sin segundos para mostrar en UI
  String get horaInicioFormatted => _formatTime(horaInicio);
  String get horaFinFormatted    => _formatTime(horaFin);

  /// Rango legible: "08:00 - 10:00"
  String get rangoHorario => '$horaInicioFormatted - $horaFinFormatted';

  /// Duración del bloque en minutos
  int get duracionMinutos {
    final inicio = horaInicioTime;
    final fin    = horaFinTime;
    return (fin.hour * 60 + fin.minute) - (inicio.hour * 60 + inicio.minute);
  }

  /// Color de la materia como Color de Flutter (fallback: verde Uniplan)
  Color get colorMateria => _parseColor(materiaColor);

  // ── Serialización ────────────────────────────

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id:              json['id'] ?? 0,
      idEstudiante:    json['id_estudiante'] ?? 0,
      idMateria:       json['id_materia'] ?? 0,
      dia:             json['dia'] ?? '',
      horaInicio:      json['hora_inicio'] ?? '00:00:00',
      horaFin:         json['hora_fin'] ?? '00:00:00',
      aula:            json['aula'],
      activo:          json['activo'] == 1 || json['activo'] == true,
      fechaCreacion:   DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      materiaNombre:   json['materia_nombre'],
      materiaColor:    json['materia_color'],
      materiaProfesor: json['materia_profesor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':              id,
      'id_estudiante':   idEstudiante,
      'id_materia':      idMateria,
      'dia':             dia,
      'hora_inicio':     horaInicio,
      'hora_fin':        horaFin,
      'aula':            aula,
      'activo':          activo,
      'fecha_creacion':  fechaCreacion.toIso8601String(),
      'materia_nombre':  materiaNombre,
      'materia_color':   materiaColor,
      'materia_profesor': materiaProfesor,
    };
  }

  Schedule copyWith({
    int? id,
    int? idEstudiante,
    int? idMateria,
    String? dia,
    String? horaInicio,
    String? horaFin,
    String? aula,
    bool? activo,
    DateTime? fechaCreacion,
    String? materiaNombre,
    String? materiaColor,
    String? materiaProfesor,
  }) {
    return Schedule(
      id:              id              ?? this.id,
      idEstudiante:    idEstudiante    ?? this.idEstudiante,
      idMateria:       idMateria       ?? this.idMateria,
      dia:             dia             ?? this.dia,
      horaInicio:      horaInicio      ?? this.horaInicio,
      horaFin:         horaFin         ?? this.horaFin,
      aula:            aula            ?? this.aula,
      activo:          activo          ?? this.activo,
      fechaCreacion:   fechaCreacion   ?? this.fechaCreacion,
      materiaNombre:   materiaNombre   ?? this.materiaNombre,
      materiaColor:    materiaColor    ?? this.materiaColor,
      materiaProfesor: materiaProfesor ?? this.materiaProfesor,
    );
  }

  // ── Helpers privados ─────────────────────────

  /// Parsea "HH:MM:SS" o "HH:MM" → TimeOfDay
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Devuelve "HH:MM" eliminando los segundos
  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  /// Parsea "#RRGGBB" → Color; fallback verde Uniplan si es null o inválido
  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF4CAF50);
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF4CAF50);
    }
  }
}
