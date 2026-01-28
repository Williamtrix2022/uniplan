// ============================================
// HOME SCREEN - DASHBOARD PRINCIPAL
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/task.dart';
import '../tasks/tasks_screen.dart';
import '../tasks/task_form_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../calendar/calendar_screen.dart';

import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final DashboardService _dashboardService = DashboardService();

  String userName = '';
  List<Task> todayTasks = [];
  int pomodorosThisWeek = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Cargar nombre del usuario
      userName = await _authService.getUserName();

      // Cargar tareas del día
      final allTasks = await _taskService.getTasks(estado: 'pendiente');
      final today = DateTime.now();
      todayTasks = allTasks.where((task) {
        return task.fechaEntrega.year == today.year &&
            task.fechaEntrega.month == today.month &&
            task.fechaEntrega.day == today.day;
      }).toList();

      // Cargar estadísticas de pomodoro
      try {
        final dashboardData = await _dashboardService.getDashboard();
        final pomodoroData = dashboardData['pomodoro'];
        if (pomodoroData != null && pomodoroData['semana'] != null) {
          pomodorosThisWeek = pomodoroData['semana']['total_sesiones'] ?? 0;
        }
      } catch (e) {
        pomodorosThisWeek = 0;
      }
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE', 'es_ES').format(now);
    final day = now.day;
    final month = DateFormat('MMMM', 'es_ES').format(now);

    return '${weekday[0].toUpperCase()}${weekday.substring(1)}, $day de $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),

                      const SizedBox(height: 32),

                      // Pomodoro Timer Card
                      _buildPomodoroCard(),

                      const SizedBox(height: 24),

                      // Racha actual
                      _buildStreakCard(),

                      const SizedBox(height: 32),

                      // Título de tareas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hoy',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TasksScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Ver todo →',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Lista de tareas
                      _buildTasksList(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${userName.split(' ')[0]}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getFormattedDate(),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            // TODO: Notificaciones
          },
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 28,
          color: AppTheme.darkText,
        ),
      ],
    );
  }

  Widget _buildPomodoroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      child: Column(
        children: [
          // Timer circular
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de progreso
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: 1.0,
                      color: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.white,
                    ),
                  ),
                ),

                // Tiempo y texto
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '25:00',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'FOCUS SESSION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.greyText,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón Start
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PomodoroScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Botón Configuración
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: IconButton(
                  onPressed: () {
                    // TODO: Configurar Pomodoro
                  },
                  icon: const Icon(Icons.settings_outlined),
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Colors.orangeAccent,
                  Colors.deepOrange,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Racha actual',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pomodorosThisWeek pomodoros esta semana',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (todayTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppTheme.greyText.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ninguna tarea para hoy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Disfruta tu día!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: todayTasks.map((task) => _buildTaskCard(task)).toList(),
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = Color(
        int.parse(task.getPriorityColor().substring(1), radix: 16) +
            0xFF000000);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppTheme.borderGrey, width: 1),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () async {
              try {
                await _taskService.completeTask(task.id);
                _loadDashboardData();
              } catch (e) {
                print('Error completing task: $e');
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
              child: task.completada
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Info de la tarea
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (task.materiaNombre != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.materiaNombre!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      DateFormat('HH:mm').format(task.fechaEntrega),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icono de menú
          IconButton(
            onPressed: () {
              // TODO: Opciones de tarea
            },
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
            color: AppTheme.greyText,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppTheme.white,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.task_alt_outlined, 'Tasks', false),
            const SizedBox(width: 48), // Espacio para FAB
            _buildNavItem(Icons.calendar_today_outlined, 'Calendar', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
  return InkWell(
    onTap: () {
      if (label == 'Tasks') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TasksScreen(),
          ),
        ).then((_) => _loadDashboardData());
      } 
      else if (label == 'Calendar') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CalendarScreen(),
          ),
        ).then((_) => _loadDashboardData());
      }
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppTheme.primaryGreen : AppTheme.greyText,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? AppTheme.primaryGreen
                : AppTheme.greyText,
          ),
        ),
      ],
    ),
  );
}

}

// ============================================
// PAINTER PARA CÍRCULO DE PROGRESO
// ============================================
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Círculo de fondo
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius - 4, backgroundPaint);

    // Círculo de progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
