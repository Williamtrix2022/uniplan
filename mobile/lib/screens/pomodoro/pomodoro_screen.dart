// ============================================
// PANTALLA DE POMODORO
// ============================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/pomodoro.dart';
import '../../models/task.dart';
import '../../services/pomodoro_preferences_service.dart';
import '../../services/pomodoro_service.dart';
import '../../services/task_service.dart';
import '../profile/pomodoro_settings_screen.dart';

enum PomodoroState { idle, working, resting, paused }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  final PomodoroService _pomodoroService = PomodoroService();
  final TaskService _taskService = TaskService();

  // Configuración (se sobreescribe con lo guardado en
  // PomodoroSettingsScreen apenas carga la pantalla — ver `_loadPreferences`)
  int workDuration = 25; // minutos
  int breakDuration = 5; // minutos
  int longBreakDuration = 15; // minutos
  int cyclesBeforeLongBreak = 4;
  bool autoStartBreaks = true;
  bool autoStartPomodoros = false;

  // Estado del timer
  PomodoroState currentState = PomodoroState.idle;
  int currentCycle = 0;
  int secondsRemaining = 25 * 60;
  int totalSeconds = 25 * 60;
  Timer? _timer;

  // Sesión actual
  PomodoroSession? currentSession;
  Task? selectedTask;
  List<Task> availableTasks = [];

  // Animación
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadTasks();
    _setupAnimation();
  }

  Future<void> _loadPreferences() async {
    final prefs = await PomodoroPreferencesService.load();
    if (!mounted) return;
    setState(() {
      workDuration = prefs.workDuration;
      breakDuration = prefs.shortBreak;
      longBreakDuration = prefs.longBreak;
      cyclesBeforeLongBreak = prefs.cyclesBeforeLongBreak;
      autoStartBreaks = prefs.autoStartBreaks;
      autoStartPomodoros = prefs.autoStartPomodoros;
      // Solo reflejar la nueva duración de trabajo en el reloj si todavía no
      // arrancó ninguna sesión — no queremos pisar un timer en curso.
      if (currentState == PomodoroState.idle) {
        secondsRemaining = workDuration * 60;
        totalSeconds = workDuration * 60;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadTasks() async {
    try {
      // Sin filtro `estado` en la request: el backend no soporta pedir
      // varios estados a la vez, así que se trae todo y se filtra acá —
      // antes solo pedía 'pendiente', por lo que una tarea marcada "en
      // progreso" desaparecía de este selector.
      final tasks = await _taskService.getTasks();
      final selectable = tasks
          .where((t) => !t.isCompleted)
          .toList()
        ..sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
      setState(() {
        availableTasks = selectable;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  void _startTimer() async {
    if (currentState == PomodoroState.idle) {
      if (selectedTask == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccioná una tarea antes de iniciar el Pomodoro'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Crear sesión en el backend
      try {
        final session = PomodoroSession(
          duracionTrabajo: workDuration,
          duracionDescanso: breakDuration,
          fechaInicio: DateTime.now(),
          idMateria: selectedTask?.idMateria,
        );

        currentSession = await _pomodoroService.createSession(session);
      } catch (e) {
        print('Error creating session: $e');
      }

      setState(() {
        currentState = PomodoroState.working;
        secondsRemaining = workDuration * 60;
        totalSeconds = workDuration * 60;
      });
    } else if (currentState == PomodoroState.paused) {
      setState(() {
        currentState = PomodoroState.working;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      currentState = PomodoroState.paused;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      currentState = PomodoroState.idle;
      currentCycle = 0;
      secondsRemaining = workDuration * 60;
      totalSeconds = workDuration * 60;
    });

    // Guardar sesión incompleta si existe
    if (currentSession != null) {
      _saveSession(completed: false);
    }
  }

  void _skipTimer() {
    _timer?.cancel();
    _onTimerComplete();
  }

  void _onTimerComplete() {
    _timer?.cancel();

    // Vibración
    HapticFeedback.heavyImpact();

    if (currentState == PomodoroState.working) {
      // Completar ciclo de trabajo
      setState(() {
        currentCycle++;
      });

      // Determinar tipo de descanso
      final isLongBreak = currentCycle % cyclesBeforeLongBreak == 0;
      final breakTime = isLongBreak ? longBreakDuration : breakDuration;

      setState(() {
        currentState = PomodoroState.resting;
        secondsRemaining = breakTime * 60;
        totalSeconds = breakTime * 60;
      });

      // Mostrar notificación
      _showBreakDialog(isLongBreak);

      // Auto-iniciar descanso, solo si el usuario lo activó en Automatización
      if (autoStartBreaks) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && currentState == PomodoroState.resting) {
            _startTimer();
          }
        });
      }
    } else if (currentState == PomodoroState.resting) {
      // Completar descanso
      final completedAllCycles = currentCycle >= cyclesBeforeLongBreak;

      setState(() {
        currentState = PomodoroState.idle;
        secondsRemaining = workDuration * 60;
        totalSeconds = workDuration * 60;
      });

      // Si completó todos los ciclos
      if (completedAllCycles) {
        _saveSession(completed: true);
        _showCompletionDialog();
        setState(() {
          currentCycle = 0;
        });
      }

      // Auto-iniciar el siguiente pomodoro, solo si el usuario lo activó en
      // Automatización — antes de este fix esta opción no hacía nada: el
      // timer siempre volvía a "idle" y esperaba a que el usuario tocara
      // "Iniciar" a mano, sin importar el valor del switch.
      if (autoStartPomodoros) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && currentState == PomodoroState.idle) {
            _startTimer();
          }
        });
      }
    }
  }

  Future<void> _saveSession({required bool completed}) async {
    if (currentSession == null) return;

    try {
      final totalMinutes = (currentCycle * workDuration);

      await _pomodoroService.completeSession(
        currentSession!.id!,
        ciclosCompletados: currentCycle,
        tiempoTotalEstudio: totalMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completed
                  ? '¡Sesión completada! $currentCycle pomodoros'
                  : 'Sesión guardada',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  void _showBreakDialog(bool isLongBreak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLongBreak ? '¡Descanso largo!' : '¡Tiempo de descanso!'),
        content: Text(
          isLongBreak
              ? 'Has completado $cyclesBeforeLongBreak pomodoros. Toma un descanso de $longBreakDuration minutos.'
              : 'Toma un descanso de $breakDuration minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicitaciones!'),
        content: Text(
          'Has completado $cyclesBeforeLongBreak ciclos de Pomodoro. ¡Excelente trabajo!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get progress => 1 - (secondsRemaining / totalSeconds);

  Color get currentColor {
    switch (currentState) {
      case PomodoroState.working:
        return AppTheme.primaryGreen;
      case PomodoroState.resting:
        return AppTheme.info;
      case PomodoroState.paused:
        return AppTheme.warning;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String get statusText {
    switch (currentState) {
      case PomodoroState.idle:
        return 'TIEMPO DE ENFOQUE';
      case PomodoroState.working:
        return 'ESTUDIANDO';
      case PomodoroState.resting:
        return 'DESCANSO';
      case PomodoroState.paused:
        return 'PAUSADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Pomodoro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PomodoroSettingsScreen(),
                ),
              ).then((_) => _loadPreferences());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Timer circular
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: currentState == PomodoroState.working
                      ? _pulseAnimation.value
                      : 1.0,
                  child: child,
                );
              },
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de progreso
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: CircularTimerPainter(
                        progress: progress,
                        color: currentColor,
                        backgroundColor: AppTheme.lightGreen,
                      ),
                    ),

                    // Tiempo y estado
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(secondsRemaining),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.greyText,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Contador de ciclos
            Text(
              'Pomodoro $currentCycle/$cyclesBeforeLongBreak',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),

            const SizedBox(height: 32),

            // Botones de control
            _buildControlButtons(),

            const SizedBox(height: 32),

            // Tarea actual
            if (selectedTask != null)
              _buildTaskCard()
            else
              _buildSelectTaskButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    if (currentState == PomodoroState.idle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón Start
          ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'Iniciar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Reiniciar
        _buildIconButton(
          icon: Icons.refresh,
          label: 'REINICIAR',
          onPressed: _resetTimer,
        ),

        const SizedBox(width: 16),

        // Botón Pause/Resume
        _buildIconButton(
          icon: currentState == PomodoroState.paused
              ? Icons.play_arrow
              : Icons.pause,
          label: currentState == PomodoroState.paused ? 'REANUDAR' : 'PAUSAR',
          onPressed:
              currentState == PomodoroState.paused ? _startTimer : _pauseTimer,
          isPrimary: true,
        ),

        const SizedBox(width: 16),

        // Botón Skip
        _buildIconButton(
          icon: Icons.skip_next,
          label: 'SALTAR',
          onPressed: _skipTimer,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primaryGreen : AppTheme.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isPrimary
                ? null
                : Border.all(color: AppTheme.borderGrey, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 32,
            color: isPrimary ? AppTheme.white : AppTheme.darkText,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.greyText,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarea actual',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedTask!.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                selectedTask = null;
              });
            },
            iconSize: 20,
            color: AppTheme.greyText,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTaskButton() {
    return InkWell(
      onTap: () async {
        final task = await showDialog<Task>(
          context: context,
          builder: (context) => _TaskSelectorDialog(tasks: availableTasks),
        );

        if (task != null) {
          setState(() {
            selectedTask = task;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border:
              Border.all(color: AppTheme.borderGrey, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_task, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text(
              'Seleccionar tarea',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PAINTER PARA CÍRCULO DE TIMER
// ============================================
class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularTimerPainter({
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
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Círculo de progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================
// DIÁLOGO SELECTOR DE TAREA
// ============================================
class _TaskSelectorDialog extends StatelessWidget {
  final List<Task> tasks;

  const _TaskSelectorDialog({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.task_alt, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Elegí una tarea',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.greyText,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: tasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 12, right: 8),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TaskSelectorTile(
                            task: task,
                            onTap: () => Navigator.pop(context, task),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppTheme.greyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay tareas pendientes',
            style: TextStyle(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Creá una tarea para poder arrancar un Pomodoro',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.greyText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TaskSelectorTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskSelectorTile({required this.task, required this.onTap});

  Color get _priorityColor {
    switch (task.prioridad) {
      case 'alta':
        return AppTheme.error;
      case 'baja':
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  bool get _isOverdue {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return task.fechaEntrega.isBefore(todayStart);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.lightGrey,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.materiaNombre != null) ...[
                          Flexible(
                            child: Text(
                              task.materiaNombre!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·',
                                style: TextStyle(color: AppTheme.greyText)),
                          ),
                        ],
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: _isOverdue ? AppTheme.error : AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM', 'es_ES').format(task.fechaEntrega),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _isOverdue ? AppTheme.error : AppTheme.greyText,
                            fontWeight: _isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.greyText, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
