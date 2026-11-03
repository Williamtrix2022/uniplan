// ============================================
// SERVICIO DE REPORTES (PROBLEMAS Y SUGERENCIAS)
// ============================================

import '../config/api_config.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  Future<void> sendReport({
    required String modulo,
    required String mensaje,
  }) async {
    await _apiService.post(ApiConfig.reports, {
      'modulo': modulo,
      'mensaje': mensaje,
    });
  }
}
