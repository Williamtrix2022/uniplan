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
import '../profile/profile_screen.dart';

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
  List<Task> dashboardTasks = [];
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

      // Cargar tareas ordenadas por fecha y prioridad
      final allTasks = await _taskService.getTasks();
      allTasks.sort((a, b) {
        final dateCompare = a.fechaEntrega.compareTo(b.fechaEntrega);
        if (dateCompare != 0) return dateCompare;

        int weight(String prioridad) {
          switch (prioridad) {
            case 'alta':
              return 3;
            case 'media':
              return 2;
            case 'baja':
              return 1;
            default:
              return 0;
          }
        }

        return weight(b.prioridad).compareTo(weight(a.prioridad));
      });
      final today = DateTime.now();
      final dayStart = DateTime(today.year, today.month, today.day);
      dashboardTasks = allTasks.where((task) {
        final due = DateTime(
          task.fechaEntrega.year,
          task.fechaEntrega.month,
          task.fechaEntrega.day,
        );
        final isCompleted = task.completada || task.estado == 'completada';
        final isOverdue = due.isBefore(dayStart);
        return !isCompleted && !isOverdue;
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
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
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
                            'Tareas',
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

                      const SizedBox(height: 24),
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
    final firstName = userName.trim().isNotEmpty
        ? userName.trim().split(' ').first
        : 'Usuario';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hola, $firstName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
    if (dashboardTasks.isEmpty) {
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
              'No tienes tareas activas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No hay pendientes vigentes por mostrar',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskFormScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: dashboardTasks.map((task) => _buildTaskCard(task)).toList(),
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = Color(
        int.parse(task.getPriorityColor().substring(1), radix: 16) +
            0xFF000000);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskFormScreen(task: task),
          ),
        ).then((_) => _loadDashboardData());
      },
      child: Container(
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
            Container(
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
                        Flexible(
                          child: Container(
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
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateFormat('dd MMM', 'es_ES').format(task.fechaEntrega)} · ${task.prioridad.toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.greyText),
              onSelected: (value) async {
                if (value == 'delete') {
                  try {
                    await _taskService.deleteTask(task.id);
                    if (!mounted) return;
                    _loadDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarea eliminada'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
        } else if (label == 'Calendar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CalendarScreen(),
            ),
          ).then((_) => _loadDashboardData());
        } else if (label == 'Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
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
              color: isActive ? AppTheme.primaryGreen : AppTheme.greyText,
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
