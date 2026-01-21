// ============================================
// CONFIGURACIÓN DE API
// ============================================

class ApiConfig {
  // ========== URL BASE DE LA API ==========
  // IMPORTANTE: Elige UNA opción según tu dispositivo
  
  // OPCIÓN 1: Android Emulator (AVD)
  static const String baseUrl = 'http://192.168.1.11:3000';
  
  // OPCIÓN 2: iOS Simulator
  // static const String baseUrl = 'http://localhost:3000';
  
  // OPCIÓN 3: Dispositivo Físico (WiFi)
  // Reemplaza X.X.X.X con tu IP local (ver instrucciones abajo)
  // static const String baseUrl = 'http://192.168.1.5:3000';
  
  // OPCIÓN 4: Chrome/Edge (Web)
  // static const String baseUrl = 'http://localhost:3000';
  
  // PRODUCCIÓN (cuando despliegues):
  // static const String baseUrl = 'https://tu-api.render.com';

  // Endpoints
  static const String apiPrefix = '/api';
  
  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';
  static const String profile = '$apiPrefix/auth/profile';
  
  // Students
  static const String students = '$apiPrefix/students';
  
  // Subjects
  static const String subjects = '$apiPrefix/subjects';
  static const String subjectsStats = '$apiPrefix/subjects/stats';
  
  // Tasks
  static const String tasks = '$apiPrefix/tasks';
  static const String tasksUpcoming = '$apiPrefix/tasks/upcoming';
  static const String tasksStats = '$apiPrefix/tasks/stats';
  
  // Notes
  static const String notes = '$apiPrefix/notes';
  static const String notesFavorites = '$apiPrefix/notes/favorites';
  static const String notesRecent = '$apiPrefix/notes/recent';
  static const String notesStats = '$apiPrefix/notes/stats';
  
  // Pomodoro
  static const String pomodoro = '$apiPrefix/pomodoro';
  static const String pomodoroToday = '$apiPrefix/pomodoro/today';
  static const String pomodoroStats = '$apiPrefix/pomodoro/stats';
  
  // Calendar
  static const String calendar = '$apiPrefix/calendar';
  static const String calendarToday = '$apiPrefix/calendar/today';
  static const String calendarWeek = '$apiPrefix/calendar/week';
  static const String calendarMonth = '$apiPrefix/calendar/month';
  
  // Dashboard
  static const String dashboard = '$apiPrefix/dashboard';
  static const String dashboardWeekly = '$apiPrefix/dashboard/weekly';
  static const String dashboardToday = '$apiPrefix/dashboard/today';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}