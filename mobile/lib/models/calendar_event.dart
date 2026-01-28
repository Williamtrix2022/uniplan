// ============================================
// MODELO DE EVENTO DE CALENDARIO
// ============================================

import 'package:flutter/material.dart';

class CalendarEvent {
  final int? id;
  final int? idEstudiante;
  final int? idMateria;
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFin;
  final String tipo; // 'clase', 'examen', 'tarea', 'evento', 'otro'
  final String? ubicacion;
  final bool recordatorio;
  final int minutosAntesRecordatorio;
  final bool todoElDia;
  final String color;
  final String? materiaNombre;
  final String? materiaColor;

  CalendarEvent({
    this.id,
    this.idEstudiante,
    this.idMateria,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    this.horaInicio,
    this.horaFin,
    this.tipo = 'evento',
    this.ubicacion,
    this.recordatorio = false,
    this.minutosAntesRecordatorio = 30,
    this.todoElDia = false,
    this.color = '#2196F3',
    this.materiaNombre,
    this.materiaColor,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    }

    return CalendarEvent(
      id: json['id'],
      idEstudiante: json['id_estudiante'],
      idMateria: json['id_materia'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      horaInicio: parseTime(json['hora_inicio']),
      horaFin: parseTime(json['hora_fin']),
      tipo: json['tipo'] ?? 'evento',
      ubicacion: json['ubicacion'],
      recordatorio: json['recordatorio'] == 1 || json['recordatorio'] == true,
      minutosAntesRecordatorio: json['minutos_antes_recordatorio'] ?? 30,
      todoElDia: json['todo_el_dia'] == 1 || json['todo_el_dia'] == true,
      color: json['color'] ?? '#2196F3',
      materiaNombre: json['materia_nombre'],
      materiaColor: json['materia_color'],
    );
  }

  Map<String, dynamic> toJson() {
    String? timeToString(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      if (id != null) 'id': id,
      if (idEstudiante != null) 'id_estudiante': idEstudiante,
      'id_materia': idMateria,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora_inicio': timeToString(horaInicio),
      'hora_fin': timeToString(horaFin),
      'tipo': tipo,
      'ubicacion': ubicacion,
      'recordatorio': recordatorio,
      'minutos_antes_recordatorio': minutosAntesRecordatorio,
      'todo_el_dia': todoElDia,
      'color': color,
    };
  }

  Color getColor() {
    return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
  }

  String getTypeLabel() {
    switch (tipo) {
      case 'clase':
        return 'Clase';
      case 'examen':
        return 'Examen';
      case 'tarea':
        return 'Tarea';
      case 'evento':
        return 'Evento';
      case 'otro':
        return 'Otro';
      default:
        return 'Evento';
    }
  }

  CalendarEvent copyWith({
    int? id,
    int? idEstudiante,
    int? idMateria,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
    String? tipo,
    String? ubicacion,
    bool? recordatorio,
    int? minutosAntesRecordatorio,
    bool? todoElDia,
    String? color,
    String? materiaNombre,
    String? materiaColor,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      idMateria: idMateria ?? this.idMateria,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      tipo: tipo ?? this.tipo,
      ubicacion: ubicacion ?? this.ubicacion,
      recordatorio: recordatorio ?? this.recordatorio,
      minutosAntesRecordatorio: minutosAntesRecordatorio ?? this.minutosAntesRecordatorio,
      todoElDia: todoElDia ?? this.todoElDia,
      color: color ?? this.color,
      materiaNombre: materiaNombre ?? this.materiaNombre,
      materiaColor: materiaColor ?? this.materiaColor,
    );
  }
}