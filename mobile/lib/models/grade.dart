// ============================================
// MODELO DE CALIFICACIÓN
// ============================================

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/date_parsing.dart';

class Grade {
  final int id;
  final int idEstudiante;
  final int idMateria;
  final String tipo; // parcial | taller | quiz | proyecto | laboratorio | final | otro
  final String? descripcion;
  final double valor; // 0.0 - 5.0
  final bool valorInvalido; // true si `valor` no pudo parsearse (no es un 0.0 real)
  final double porcentaje; // 0 - 100
  final bool porcentajeInvalido; // true si `porcentaje` no pudo parsearse (no es un 0.0 real)
  final DateTime? fechaEvaluacion;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final String? materiaNombre;
  final String? materiaColor;

  Grade({
    required this.id,
    required this.idEstudiante,
    required this.idMateria,
    required this.tipo,
    this.descripcion,
    required this.valor,
    this.valorInvalido = false,
    required this.porcentaje,
    this.porcentajeInvalido = false,
    this.fechaEvaluacion,
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.materiaNombre,
    this.materiaColor,
  });

  // ── Catálogo de tipos de evaluación ──────────

  static const Map<String, String> tipoLabels = {
    'parcial': 'Parcial',
    'taller': 'Taller',
    'quiz': 'Quiz',
    'proyecto': 'Proyecto',
    'laboratorio': 'Laboratorio',
    'final': 'Final',
    'otro': 'Otro',
  };

  static String labelForTipo(String tipo) =>
      tipoLabels[tipo] ?? _capitalize(tipo);

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  // ── Getters de conveniencia ──────────────────

  /// true si la calificación alcanza el mínimo para aprobar (3.0).
  /// Si `valor` no pudo parsearse desde el backend, no se asume aprobado.
  bool get aprobado => !valorInvalido && valor >= 3.0;

  /// Color según la franja de la nota: rojo <3.0, ámbar 3.0-3.9, verde >=4.0.
  /// Si `valor` no pudo parsearse, se muestra en gris en vez de rojo (evita
  /// aparentar una nota reprobatoria real cuando el dato es inválido).
  Color get estadoColor =>
      valorInvalido ? AppTheme.greyText : colorForValor(valor);

  /// Etiqueta en español del tipo de evaluación
  String get tipoLabel => labelForTipo(tipo);

  /// Color de la materia asociada (fallback: verde Uniplan)
  Color get colorMateria => parseColorHex(materiaColor);

  /// Color por franja de nota reutilizable fuera de una instancia de Grade
  static Color colorForValor(double valor) {
    if (valor < 3.0) return AppTheme.error;
    if (valor < 4.0) return AppTheme.warning;
    return AppTheme.success;
  }

  // ── Serialización ────────────────────────────

  factory Grade.fromJson(Map<String, dynamic> json) {
    final rawValor = json['valor'];
    final parsedValor = double.tryParse(rawValor?.toString() ?? '');
    final rawPorcentaje = json['porcentaje'];
    final parsedPorcentaje = double.tryParse(rawPorcentaje?.toString() ?? '');

    return Grade(
      id:                 json['id'] ?? 0,
      idEstudiante:       json['id_estudiante'] ?? 0,
      idMateria:          json['id_materia'] ?? 0,
      tipo:               json['tipo'] ?? 'otro',
      descripcion:        json['descripcion'],
      valor:              parsedValor ?? 0.0,
      valorInvalido:      rawValor != null && parsedValor == null,
      porcentaje:         parsedPorcentaje ?? 0.0,
      porcentajeInvalido: rawPorcentaje != null && parsedPorcentaje == null,
      // `fecha_evaluacion` es una columna DATE (fecha de calendario, sin
      // hora) — se parsea con `tryParseDateOnly` para no desplazarla por
      // zona horaria (ver comentario en utils/date_parsing.dart). A
      // diferencia de `fecha_creacion`/`fecha_actualizacion` (TIMESTAMP,
      // instante real), acá la hora no tiene significado de negocio.
      fechaEvaluacion: tryParseDateOnly(json['fecha_evaluacion']),
      activo:             json['activo'] == 1 || json['activo'] == true,
      fechaCreacion:      json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'].toString())
          : null,
      materiaNombre:      json['materia_nombre'],
      materiaColor:       json['materia_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':                  id,
      'id_estudiante':       idEstudiante,
      'id_materia':          idMateria,
      'tipo':                tipo,
      'descripcion':         descripcion,
      'valor':               valor,
      'porcentaje':          porcentaje,
      'fecha_evaluacion':    fechaEvaluacion?.toIso8601String().split('T').first,
      'activo':              activo,
      'fecha_creacion':      fechaCreacion?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'materia_nombre':      materiaNombre,
      'materia_color':       materiaColor,
    };
  }

  Grade copyWith({
    int? id,
    int? idEstudiante,
    int? idMateria,
    String? tipo,
    String? descripcion,
    double? valor,
    bool? valorInvalido,
    double? porcentaje,
    bool? porcentajeInvalido,
    DateTime? fechaEvaluacion,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? materiaNombre,
    String? materiaColor,
  }) {
    return Grade(
      id:                 id                 ?? this.id,
      idEstudiante:       idEstudiante       ?? this.idEstudiante,
      idMateria:          idMateria          ?? this.idMateria,
      tipo:               tipo               ?? this.tipo,
      descripcion:        descripcion        ?? this.descripcion,
      valor:              valor              ?? this.valor,
      valorInvalido:      valorInvalido      ?? this.valorInvalido,
      porcentaje:         porcentaje         ?? this.porcentaje,
      porcentajeInvalido: porcentajeInvalido ?? this.porcentajeInvalido,
      fechaEvaluacion:    fechaEvaluacion    ?? this.fechaEvaluacion,
      activo:             activo             ?? this.activo,
      fechaCreacion:      fechaCreacion      ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      materiaNombre:      materiaNombre      ?? this.materiaNombre,
      materiaColor:       materiaColor       ?? this.materiaColor,
    );
  }

  // ── Helpers públicos ──────────────────────────

  /// Parsea "#RRGGBB" → Color; fallback verde Uniplan si es null o inválido.
  /// Público para que otros modelos/widgets de calificaciones lo reutilicen.
  static Color parseColorHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF4CAF50);
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF4CAF50);
    }
  }
}

/// Convierte valores que pueden venir como String (DECIMAL de MySQL), int
/// o double desde el backend, tolerando null.
double? parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

// ============================================
// PROMEDIO POR MATERIA (dashboard de resumen)
// ============================================

class SubjectAverage {
  final int idMateria;
  final String materiaNombre;
  final String? materiaColor;
  final double? promedio;
  final double porcentajeAcumulado;
  final String estado; // aprobado | en_riesgo | excelente

  SubjectAverage({
    required this.idMateria,
    required this.materiaNombre,
    this.materiaColor,
    this.promedio,
    this.porcentajeAcumulado = 0.0,
    this.estado = 'en_riesgo',
  });

  Color get colorMateria => Grade.parseColorHex(materiaColor);

  factory SubjectAverage.fromJson(Map<String, dynamic> json) {
    return SubjectAverage(
      idMateria: json['id_materia'] ?? json['idMateria'] ?? 0,
      materiaNombre:
          json['materia_nombre'] ?? json['materiaNombre'] ?? 'Sin materia',
      materiaColor: json['materia_color'] ?? json['materiaColor'],
      promedio: parseNullableDouble(json['promedio']),
      porcentajeAcumulado: parseNullableDouble(
            json['porcentaje_acumulado'] ?? json['porcentajeAcumulado'],
          ) ??
          0.0,
      estado: json['estado'] ?? 'en_riesgo',
    );
  }
}

// ============================================
// RESUMEN GENERAL DE CALIFICACIONES
// ============================================

class GradesSummary {
  final double? promedioGeneral;
  final List<SubjectAverage> materias;
  final int totalMaterias;

  GradesSummary({
    this.promedioGeneral,
    this.materias = const [],
    this.totalMaterias = 0,
  });

  factory GradesSummary.fromJson(Map<String, dynamic> json) {
    final materiasJson = json['materias'] as List<dynamic>? ?? [];
    final materias = materiasJson
        .map((m) => SubjectAverage.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return GradesSummary(
      promedioGeneral: parseNullableDouble(
        json['promedioGeneral'] ?? json['promedio_general'],
      ),
      materias: materias,
      totalMaterias:
          json['totalMaterias'] ?? json['total_materias'] ?? materias.length,
    );
  }
}

// ============================================
// PROYECCIÓN DE APROBACIÓN POR MATERIA
// ============================================

class SubjectProjection {
  final double? promedioActual;
  final double porcentajeAcumulado;
  final double porcentajeRestante;
  final double? notaNecesaria;

  /// Refleja tal cual el campo `aprobado` calculado por el backend: true
  /// cuando el promedio objetivo ya está garantizado (incluida la situación
  /// en la que `notaNecesaria <= 0` con evaluaciones aún pendientes). No se
  /// recalcula en el cliente para no divergir de la lógica del servidor.
  final bool aprobado;

  SubjectProjection({
    this.promedioActual,
    this.porcentajeAcumulado = 0.0,
    this.porcentajeRestante = 0.0,
    this.notaNecesaria,
    this.aprobado = false,
  });

  /// true si con las notas actuales ya no es posible aprobar
  /// matemáticamente (se necesitaría una nota mayor a 5.0)
  bool get esImposibleAprobar => notaNecesaria != null && notaNecesaria! > 5.0;

  /// true si ya se alcanzó (o está matemáticamente garantizado) el promedio
  /// mínimo de aprobación. Delegado al backend vía `aprobado` en vez de
  /// recalcularse aquí — evita el bug donde el cliente ignoraba el caso de
  /// "ya garantizado con evaluaciones pendientes".
  bool get yaAprobado => aprobado;

  factory SubjectProjection.fromJson(Map<String, dynamic> json) {
    return SubjectProjection(
      promedioActual: parseNullableDouble(
        json['promedioActual'] ?? json['promedio_actual'],
      ),
      porcentajeAcumulado: parseNullableDouble(
            json['porcentajeAcumulado'] ?? json['porcentaje_acumulado'],
          ) ??
          0.0,
      porcentajeRestante: parseNullableDouble(
            json['porcentajeRestante'] ?? json['porcentaje_restante'],
          ) ??
          0.0,
      notaNecesaria: parseNullableDouble(
        json['notaNecesaria'] ?? json['nota_necesaria'],
      ),
      aprobado: json['aprobado'] == true,
    );
  }
}
