// ============================================
// WIDGET: VISTA SEMANAL DE HORARIOS
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/schedule.dart';
import 'day_selector.dart';
import 'schedule_grid.dart';

/// Contenedor que integra [DaySelector] y [ScheduleGrid] en la vista semanal.
///
/// [onDaySelected] se invoca cuando el usuario toca un día en el selector,
/// permitiendo que la pantalla padre navegue a la vista de día si lo desea.
/// [onScheduleTap] se propaga al [ScheduleGrid] para abrir el detalle.
class WeekView extends StatefulWidget {
  final List<Schedule> schedules;
  final Set<int> conflictIds;
  final ValueChanged<Schedule> onScheduleTap;
  final ValueChanged<String>? onDaySelected;
  final bool showWeekend;
  final bool isLoading;

  const WeekView({
    super.key,
    required this.schedules,
    required this.onScheduleTap,
    this.conflictIds = const {},
    this.onDaySelected,
    this.showWeekend = false,
    this.isLoading = false,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  static const Map<int, String> _weekdayMap = {
    1: 'lunes', 2: 'martes', 3: 'miercoles',
    4: 'jueves', 5: 'viernes', 6: 'sabado', 7: 'domingo',
  };

  late String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _weekdayMap[DateTime.now().weekday];
  }

  void _handleDaySelected(String day) {
    setState(() => _selectedDay = day);
    widget.onDaySelected?.call(day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekHeader(),
        DaySelector(
          selectedDay: _selectedDay,
          onDaySelected: _handleDaySelected,
          showWeekend: widget.showWeekend,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.isLoading
              ? _buildLoadingSkeleton()
              : ScheduleGrid(
                  schedules:    widget.schedules,
                  conflictIds:  widget.conflictIds,
                  onScheduleTap: widget.onScheduleTap,
                  showWeekend:  widget.showWeekend,
                ),
        ),
      ],
    );
  }

  // ── Encabezado con rango de fechas de la semana actual ───────────────────

  Widget _buildWeekHeader() {
    final now       = DateTime.now();
    final monday    = now.subtract(Duration(days: now.weekday - 1));
    final friday    = monday.add(const Duration(days: 4));
    final rangeText = '${_fmtDate(monday)} – ${_fmtDate(friday)}';

    final hasConflicts = widget.conflictIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingM, AppSizes.paddingM, AppSizes.paddingM, 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario semanal',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rangeText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          // Badge de conflictos
          if (hasConflicts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.conflictIds.length ~/ 2} conflicto'
                    '${widget.conflictIds.length ~/ 2 != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Skeleton de carga ────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const List<String> _monthNames = [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_monthNames[d.month]}';
}
