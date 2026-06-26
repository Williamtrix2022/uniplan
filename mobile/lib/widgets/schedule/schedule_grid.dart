// ============================================
// WIDGET: CUADRÍCULA SEMANAL DE HORARIOS
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/schedule.dart';
import 'class_card.dart';
import 'time_slot.dart';

/// Cuadrícula interactiva que muestra el horario semanal.
///
/// Scroll vertical: contiene etiquetas de hora + bloques (mismo eje).
/// Scroll horizontal: los headers de días siguen al contenido de forma
/// pasiva (NeverScrollableScrollPhysics) sincronizados por listener.
///
/// Parámetros de layout:
/// - [hourHeight]   : píxeles por hora (default 64)
/// - [columnWidth]  : ancho por columna de día (default 110)
/// - [startHour]    : primera hora visible (default 6)
/// - [endHour]      : última hora visible, exclusiva (default 22)
/// - [showWeekend]  : muestra sábado y domingo (default false)
class ScheduleGrid extends StatefulWidget {
  final List<Schedule> schedules;
  final Set<int> conflictIds;
  final ValueChanged<Schedule> onScheduleTap;
  final double hourHeight;
  final double columnWidth;
  final int startHour;
  final int endHour;
  final bool showWeekend;

  const ScheduleGrid({
    super.key,
    required this.schedules,
    required this.onScheduleTap,
    this.conflictIds = const {},
    this.hourHeight = 64,
    this.columnWidth = 110,
    this.startHour = 6,
    this.endHour = 22,
    this.showWeekend = false,
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;
  late final ScrollController _headerController;

  static const List<String> _dayOrder = [
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo',
  ];

  static const Map<String, String> _dayLabels = {
    'lunes':     'Lunes',
    'martes':    'Martes',
    'miercoles': 'Miérc.',
    'jueves':    'Jueves',
    'viernes':   'Viernes',
    'sabado':    'Sábado',
    'domingo':   'Domingo',
  };

  // Días visibles según showWeekend y días con clases
  List<String> get _activeDays {
    final base = widget.showWeekend
        ? _dayOrder
        : _dayOrder.take(5).toList();

    // Si hay clases en fin de semana, agregarlo aunque showWeekend=false
    final extraDays = _dayOrder.skip(5).where((d) =>
        widget.schedules.any((s) => s.dia == d));

    return [...base, ...extraDays.where((d) => !base.contains(d))];
  }

  double get _totalHeight =>
      (widget.endHour - widget.startHour) * widget.hourHeight;

  double get _totalWidth =>
      _activeDays.length * widget.columnWidth;

  // Alto mínimo para que un bloque sea visible aunque dure muy poco
  static const double _minBlockHeight = 24;

  @override
  void initState() {
    super.initState();
    _verticalController   = ScrollController();
    _horizontalController = ScrollController();
    _headerController     = ScrollController();

    // El contenido horizontal es el driver; el header lo sigue
    _horizontalController.addListener(_syncHeader);
  }

  void _syncHeader() {
    if (!_headerController.hasClients) return;
    final offset = _horizontalController.offset
        .clamp(0.0, _headerController.position.maxScrollExtent);
    if (_headerController.offset != offset) {
      _headerController.jumpTo(offset);
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildDayHeaders(),
        const Divider(height: 1, color: AppTheme.borderGrey),
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalController,
            physics: const ClampingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeLabels(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Headers de días ──────────────────────────────────────────────────────

  Widget _buildDayHeaders() {
    return Row(
      children: [
        // Esquina vacía alineada con las etiquetas de hora
        const SizedBox(width: 44),
        Expanded(
          child: SingleChildScrollView(
            controller: _headerController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: _activeDays.map(_buildDayHeader).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader(String day) {
    final isToday = _isTodayDay(day);

    return SizedBox(
      width: widget.columnWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isToday
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isToday ? AppTheme.primaryGreen : AppTheme.borderGrey,
              width: isToday ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          _dayLabels[day] ?? day,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppTheme.primaryGreen : AppTheme.darkText,
          ),
        ),
      ),
    );
  }

  // ── Etiquetas de hora ────────────────────────────────────────────────────

  Widget _buildTimeLabels() {
    return Column(
      children: List.generate(
        widget.endHour - widget.startHour,
        (i) => TimeSlot(
          hour:       widget.startHour + i,
          hourHeight: widget.hourHeight,
        ),
      ),
    );
  }

  // ── Contenido principal: grid + bloques ──────────────────────────────────

  Widget _buildContent() {
    return SizedBox(
      width:  _totalWidth,
      height: _totalHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _buildGridLines(),
          ..._buildScheduleBlocks(),
          _buildCurrentTimeLine(),
        ],
      ),
    );
  }

  // Líneas horizontales (cada hora) y verticales (cada día)
  Widget _buildGridLines() {
    return CustomPaint(
      size: Size(_totalWidth, _totalHeight),
      painter: _GridPainter(
        hourHeight:   widget.hourHeight,
        columnWidth:  widget.columnWidth,
        totalHours:   widget.endHour - widget.startHour,
        totalColumns: _activeDays.length,
      ),
    );
  }

  // Bloques de clase posicionados absolutamente
  List<Widget> _buildScheduleBlocks() {
    final blocks = <Widget>[];

    for (final schedule in widget.schedules) {
      final dayIndex = _activeDays.indexOf(schedule.dia);
      if (dayIndex == -1) continue;

      final inicio = schedule.horaInicioTime;
      final startMinutes =
          (inicio.hour - widget.startHour) * 60 + inicio.minute;
      if (startMinutes < 0) continue; // fuera del rango visible

      final top    = startMinutes * widget.hourHeight / 60;
      final height = (schedule.duracionMinutos * widget.hourHeight / 60)
          .clamp(_minBlockHeight, _totalHeight - top);
      final left   = dayIndex * widget.columnWidth;

      blocks.add(
        Positioned(
          top:    top,
          left:   left,
          width:  widget.columnWidth,
          height: height,
          child: ClassCard(
            schedule:   schedule,
            isConflict: widget.conflictIds.contains(schedule.id),
            onTap:      () => widget.onScheduleTap(schedule),
          ),
        ),
      );
    }

    return blocks;
  }

  // Línea roja de hora actual (solo si el día de hoy está visible)
  Widget _buildCurrentTimeLine() {
    final now = DateTime.now();
    final todayKey = _getTodayKey();
    if (todayKey == null || !_activeDays.contains(todayKey)) {
      return const SizedBox.shrink();
    }

    final minutesFromStart =
        (now.hour - widget.startHour) * 60 + now.minute;
    if (minutesFromStart < 0 ||
        minutesFromStart > (widget.endHour - widget.startHour) * 60) {
      return const SizedBox.shrink();
    }

    final top  = minutesFromStart * widget.hourHeight / 60;
    final left = _activeDays.indexOf(todayKey) * widget.columnWidth;

    return Positioned(
      top:   top - 1,
      left:  left,
      width: widget.columnWidth,
      child: Row(
        children: [
          Container(
            width:  8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado vacío ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppTheme.greyText.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes clases registradas',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar tu primera clase',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const Map<int, String> _weekdayMap = {
    1: 'lunes', 2: 'martes', 3: 'miercoles',
    4: 'jueves', 5: 'viernes', 6: 'sabado', 7: 'domingo',
  };

  String? _getTodayKey() => _weekdayMap[DateTime.now().weekday];

  bool _isTodayDay(String day) => _getTodayKey() == day;
}

// ── CustomPainter para líneas del grid ───────────────────────────────────────

class _GridPainter extends CustomPainter {
  final double hourHeight;
  final double columnWidth;
  final int totalHours;
  final int totalColumns;

  const _GridPainter({
    required this.hourHeight,
    required this.columnWidth,
    required this.totalHours,
    required this.totalColumns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = AppTheme.borderGrey.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    final halfHourPaint = Paint()
      ..color = AppTheme.borderGrey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    final columnPaint = Paint()
      ..color = AppTheme.borderGrey.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    // Líneas horizontales (cada hora y media hora)
    for (int h = 0; h <= totalHours; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hourPaint);

      if (h < totalHours) {
        final yHalf = y + hourHeight / 2;
        canvas.drawLine(
          Offset(0, yHalf),
          Offset(size.width, yHalf),
          halfHourPaint,
        );
      }
    }

    // Líneas verticales (cada columna de día)
    for (int c = 1; c < totalColumns; c++) {
      final x = c * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), columnPaint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.hourHeight != hourHeight ||
      old.columnWidth != columnWidth ||
      old.totalHours != totalHours ||
      old.totalColumns != totalColumns;
}
