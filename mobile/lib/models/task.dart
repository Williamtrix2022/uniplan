// ============================================
// MODELO DE TAREA
// ============================================

class Task {
  final int id;
  final int idEstudiante;
  final int? idMateria;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEntrega;
  final String prioridad; // 'baja', 'media', 'alta'
  final String estado; // 'pendiente', 'en_progreso', 'completada'
  final bool completada;
  final String? materiaNombre;
  final String? materiaColor;

  Task({
    required this.id,
    required this.idEstudiante,
    this.idMateria,
    required this.titulo,
    this.descripcion,
    required this.fechaEntrega,
    this.prioridad = 'media',
    this.estado = 'pendiente',
    this.completada = false,
    this.materiaNombre,
    this.materiaColor,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      idEstudiante: json['id_estudiante'] ?? 0,
      idMateria: json['id_materia'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      prioridad: json['prioridad'] ?? 'media',
      estado: json['estado'] ?? 'pendiente',
      completada: json['completada'] == 1 || json['completada'] == true,
      materiaNombre: json['materia_nombre'],
      materiaColor: json['materia_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_estudiante': idEstudiante,
      'id_materia': idMateria,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_entrega': fechaEntrega.toIso8601String().split('T')[0],
      'prioridad': prioridad,
      'estado': estado,
      'completada': completada,
    };
  }

  // Obtener color según prioridad
  String getPriorityColor() {
    switch (prioridad) {
      case 'alta':
        return '#EF4444';
      case 'media':
        return '#F59E0B';
      case 'baja':
        return '#10B981';
      default:
        return '#6B7280';
    }
  }

  // Copia con modificaciones
  Task copyWith({
    int? id,
    int? idEstudiante,
    int? idMateria,
    String? titulo,
    String? descripcion,
    DateTime? fechaEntrega,
    String? prioridad,
    String? estado,
    bool? completada,
    String? materiaNombre,
    String? materiaColor,
  }) {
    return Task(
      id: id ?? this.id,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      idMateria: idMateria ?? this.idMateria,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      completada: completada ?? this.completada,
      materiaNombre: materiaNombre ?? this.materiaNombre,
      materiaColor: materiaColor ?? this.materiaColor,
    );
  }
}