// ============================================
// CONFIGURACIÓN DE API
// ============================================

class ApiConfig {
  // ========== URL BASE DE LA API ==========
  // Dev:  flutter run --dart-define=API_URL=http://192.168.1.76:3000
  // Prod: flutter build apk --dart-define=API_URL=https://tu-app.vercel.app
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.76:3000',
  );

  // Endpoints
  static const String apiPrefix = '/api';

  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';
  static const String profile = '$apiPrefix/auth/profile';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';
  static const String changePassword = '$apiPrefix/auth/change-password';

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
