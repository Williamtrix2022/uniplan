// ============================================
// HOME SCREEN - DASHBOARD PRINCIPAL
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/schedule_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/task.dart';
import '../../models/schedule.dart';
import '../tasks/tasks_screen.dart';
import '../tasks/task_form_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().initialize();
    });
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
          pomodorosThisWeek = pomodoroData['semana']['sesiones_completadas'] ?? 0;
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
                          Text(
                            'Tareas',
                            style: GoogleFonts.inter(
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
                            child: Text(
                              'Ver todo →',
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Lista de tareas
                      _buildTasksList(),

                      const SizedBox(height: 32),

                      // Sección Mi Horario
                      _buildScheduleSection(),

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
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hola, $firstName',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getFormattedDate(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
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
                  style: GoogleFonts.inter(
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
            Text(
              'No tienes tareas activas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay pendientes vigentes por mostrar',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
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
              label: Text(
                'Agregar tarea',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    final isOverdue =
        task.fechaEntrega.isBefore(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              )) &&
            !task.completada;
    final sideColor = _getTaskStatusColor(task, isOverdue);

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
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: Stack(
          children: [
            // Sidebar con color de estado
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusM),
                    bottomLeft: Radius.circular(AppSizes.radiusM),
                  ),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                    color: AppTheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    task.materiaNombre!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              DateFormat('dd MMM', 'es_ES')
                                  .format(task.fechaEntrega),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppTheme.greyText),
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
          ],
        ),
      ),
    );
  }

  Color _getTaskStatusColor(Task task, bool isOverdue) {
    if (isOverdue) return AppTheme.error;
    if (task.completada || task.estado == 'completada') {
      return AppTheme.onSurfaceVariant.withOpacity(0.4);
    }
    if (task.estado == 'en_progreso') return AppTheme.info;
    return AppTheme.primaryGreen;
  }

  // ── Sección Mi Horario ──────────────────────────────────────────────────

  static const Map<int, String> _weekdayKeys = {
    1: 'lunes', 2: 'martes', 3: 'miercoles',
    4: 'jueves', 5: 'viernes', 6: 'sabado', 7: 'domingo',
  };

  Widget _buildScheduleSection() {
    final provider   = context.watch<ScheduleProvider>();
    final todayKey   = _weekdayKeys[DateTime.now().weekday];
    final todayList  = todayKey != null
        ? provider.schedulesForDay(todayKey)
        : <Schedule>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mi Horario',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              ),
              child: Text(
                'Ver todo →',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.isLoading)
          _buildScheduleSkeleton()
        else if (todayList.isEmpty)
          _buildScheduleEmpty()
        else
          _buildScheduleList(todayList),
      ],
    );
  }

  Widget _buildScheduleSkeleton() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
    );
  }

  Widget _buildScheduleEmpty() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppTheme.lightGreen,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'No tienes clases hoy',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(List<Schedule> schedules) {
    final visible = schedules.take(3).toList();
    return Column(
      children: visible.map((s) => _buildScheduleItem(s)).toList(),
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: schedule.colorMateria,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.materiaNombre ?? 'Sin materia',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.rangoHorario +
                        (schedule.aula != null ? ' · ${schedule.aula}' : ''),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.greyText,
              size: 18,
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
            style: GoogleFonts.inter(
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
