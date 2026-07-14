// ============================================
// SERVICIO DE CALIFICACIONES
// ============================================

import '../config/api_config.dart';
import '../models/grade.dart';
import 'api_service.dart';

class GradeService {
  final ApiService _apiService = ApiService();

  // Obtener todas mis calificaciones
  Future<List<Grade>> getMyGrades() async {
    try {
      final response = await _apiService.get(ApiConfig.grades);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Grade.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener resumen del dashboard de calificaciones
  Future<GradesSummary> getSummary() async {
    try {
      final response = await _apiService.get(ApiConfig.gradesSummary);

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        return GradesSummary.fromJson(Map<String, dynamic>.from(data));
      }

      return GradesSummary();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener calificaciones de una materia
  Future<List<Grade>> getGradesBySubject(int idMateria) async {
    try {
      final response =
          await _apiService.get(ApiConfig.gradesBySubject(idMateria));

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Grade.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener proyección de aprobación de una materia
  Future<SubjectProjection> getProjection(int idMateria) async {
    try {
      final response =
          await _apiService.get(ApiConfig.gradesProjection(idMateria));

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        return SubjectProjection.fromJson(Map<String, dynamic>.from(data));
      }

      return SubjectProjection();
    } catch (e) {
      rethrow;
    }
  }

  // Crear calificación
  Future<Grade> createGrade(Grade grade) async {
    try {
      final response = await _apiService.post(ApiConfig.grades, _toBody(grade));

      if (response['success'] == true && response['data'] != null) {
        return Grade.fromJson(response['data']);
      }

      throw ApiException(
        response['message'] ?? 'No se pudo crear la calificación',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar calificación
  Future<Grade> updateGrade(int id, Grade grade) async {
    try {
      final response =
          await _apiService.put('${ApiConfig.grades}/$id', _toBody(grade));

      if (response['success'] == true && response['data'] != null) {
        return Grade.fromJson(response['data']);
      }

      throw ApiException(
        response['message'] ?? 'No se pudo actualizar la calificación',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar calificación (borrado lógico)
  Future<void> deleteGrade(int id) async {
    try {
      await _apiService.delete('${ApiConfig.grades}/$id');
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _toBody(Grade grade) {
    return {
      'id_materia': grade.idMateria,
      'tipo': grade.tipo,
      'descripcion': grade.descripcion,
      'valor': grade.valor,
      'porcentaje': grade.porcentaje,
      'fecha_evaluacion':
          grade.fechaEvaluacion?.toIso8601String().split('T').first,
    };
  }
}
