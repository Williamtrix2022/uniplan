// ============================================
// SERVICIO DE TAREAS
// ============================================

import '../config/api_config.dart';
import '../models/task.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService = ApiService();

  // Obtener todas las tareas
  Future<List<Task>> getTasks({String? estado, String? prioridad}) async {
    try {
      String endpoint = ApiConfig.tasks;
      
      // Agregar query parameters si existen
      if (estado != null || prioridad != null) {
        final params = <String>[];
        if (estado != null) params.add('estado=$estado');
        if (prioridad != null) params.add('prioridad=$prioridad');
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint);
      
      if (response['success'] == true) {
        final List<dynamic> tasksJson = response['data'] ?? [];
        return tasksJson.map((json) => Task.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Obtener tareas próximas
  Future<List<Task>> getUpcomingTasks() async {
    try {
      final response = await _apiService.get(ApiConfig.tasksUpcoming);
      
      if (response['success'] == true) {
        final List<dynamic> tasksJson = response['data'] ?? [];
        return tasksJson.map((json) => Task.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Crear tarea
  Future<Task> createTask(Task task) async {
    try {
      final response = await _apiService.post(
        ApiConfig.tasks,
        task.toJson(),
      );
      
      if (response['success'] == true) {
        return Task.fromJson(response['data']);
      }
      
      throw Exception('Error al crear tarea');
    } catch (e) {
      rethrow;
    }
  }

  // Completar tarea
  Future<Task> completeTask(int taskId) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.tasks}/$taskId/complete',
      );
      
      if (response['success'] == true) {
        return Task.fromJson(response['data']);
      }
      
      throw Exception('Error al completar tarea');
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar tarea
  Future<Task> updateTask(int taskId, Task task) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.tasks}/$taskId',
        task.toJson(),
      );
      
      if (response['success'] == true) {
        return Task.fromJson(response['data']);
      }
      
      throw Exception('Error al actualizar tarea');
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar tarea
  Future<void> deleteTask(int taskId) async {
    try {
      await _apiService.delete('${ApiConfig.tasks}/$taskId');
    } catch (e) {
      rethrow;
    }
  }
}