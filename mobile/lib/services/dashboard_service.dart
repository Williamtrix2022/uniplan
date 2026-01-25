// ============================================
// SERVICIO DE DASHBOARD
// ============================================

import '../config/api_config.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  // Obtener dashboard completo
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.get(ApiConfig.dashboard);
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      
      return {};
    } catch (e) {
      rethrow;
    }
  }

  // Obtener resumen de hoy
  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final response = await _apiService.get(ApiConfig.dashboardToday);
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      
      return {};
    } catch (e) {
      rethrow;
    }
  }

  // Obtener resumen semanal
  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final response = await _apiService.get(ApiConfig.dashboardWeekly);
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      
      return {};
    } catch (e) {
      rethrow;
    }
  }
}