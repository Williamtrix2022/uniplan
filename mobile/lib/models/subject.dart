class Subject {
  final int id;
  final int idEstudiante;
  final String nombre;
  final String? codigo;
  final String? profesor;
  final int? semestre;
  final int? creditos;
  final String? horario;
  final String color;

  Subject({
    required this.id,
    required this.idEstudiante,
    required this.nombre,
    this.codigo,
    this.profesor,
    this.semestre,
    this.creditos,
    this.horario,
    this.color = '#4CAF50',
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      idEstudiante: json['id_estudiante'] ?? 0,
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'],
      profesor: json['profesor'],
      semestre: json['semestre'],
      creditos: json['creditos'],
      horario: json['horario'],
      color: json['color'] ?? '#4CAF50',
    );
  }
}
