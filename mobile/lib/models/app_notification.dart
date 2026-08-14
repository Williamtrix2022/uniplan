// ============================================
// MODELO DE NOTIFICACIÓN
// ============================================

class AppNotification {
  final int id;
  final String tipo; // tarea | clase | sistema | general
  final String titulo;
  final String mensaje;
  final bool leida;
  final String? referenciaTipo; // 'tarea' | 'clase' | etc.
  final int? referenciaId;
  final DateTime? fechaProgramada;
  final DateTime fechaCreacion;

  AppNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.leida = false,
    this.referenciaTipo,
    this.referenciaId,
    this.fechaProgramada,
    required this.fechaCreacion,
  });

  // ── Catálogo de tipos ─────────────────────────

  static const Map<String, String> tipoLabels = {
    'tarea': 'Tarea',
    'clase': 'Clase',
    'sistema': 'Sistema',
    'general': 'General',
  };

  String get tipoLabel => tipoLabels[tipo] ?? 'General';

  // ── Serialización ─────────────────────────────

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? 'general',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      leida: json['leida'] == 1 || json['leida'] == true,
      referenciaTipo: json['referencia_tipo'],
      referenciaId: json['referencia_id'],
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.tryParse(json['fecha_programada'].toString())
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': leida,
      'referencia_tipo': referenciaTipo,
      'referencia_id': referenciaId,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? id,
    String? tipo,
    String? titulo,
    String? mensaje,
    bool? leida,
    String? referenciaTipo,
    int? referenciaId,
    DateTime? fechaProgramada,
    DateTime? fechaCreacion,
  }) {
    return AppNotification(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      leida: leida ?? this.leida,
      referenciaTipo: referenciaTipo ?? this.referenciaTipo,
      referenciaId: referenciaId ?? this.referenciaId,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
