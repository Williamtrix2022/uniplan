import '../config/api_config.dart';
import '../models/subject.dart';
import 'api_service.dart';

class SubjectService {
  final ApiService _apiService = ApiService();

  Future<List<Subject>> getSubjects() async {
    final response = await _apiService.get(ApiConfig.subjects);

    if (response['success'] == true) {
      final List<dynamic> subjectsJson = response['data'] ?? [];
      return subjectsJson.map((json) => Subject.fromJson(json)).toList();
    }

    return [];
  }

  Future<Subject> createSubject({
    required String nombre,
    String? codigo,
    String? profesor,
    int? semestre,
    int? creditos,
    String? horario,
    String? color,
  }) async {
    final response = await _apiService.post(
      ApiConfig.subjects,
      {
        'nombre': nombre,
        'codigo': codigo,
        'profesor': profesor,
        'semestre': semestre,
        'creditos': creditos,
        'horario': horario,
        'color': color,
      },
    );

    if (response['success'] == true && response['data'] != null) {
      return Subject.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'No se pudo crear la materia');
  }

  Future<void> deleteSubject(int subjectId) async {
    final response = await _apiService.delete('${ApiConfig.subjects}/$subjectId');
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'No se pudo eliminar la materia');
    }
  }
}
