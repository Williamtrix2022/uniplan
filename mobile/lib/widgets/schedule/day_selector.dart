// ============================================
// WIDGET: SELECTOR DE DÍA DE LA SEMANA
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

/// Fila horizontal de chips para seleccionar el día de la semana.
/// Resalta el día seleccionado con [AppTheme.primaryGreen] y
/// marca el día actual con un punto indicador.
///
/// [showWeekend] controla si se muestran sábado y domingo.
class DaySelector extends StatelessWidget {
  final String? selectedDay;
  final ValueChanged<String> onDaySelected;
  final bool showWeekend;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.showWeekend = true,
  });

  // Mapeo día clave → etiqueta abreviada en español
  static const List<_DayItem> _days = [
    _DayItem(key: 'lunes',     label: 'Lun', weekday: 1),
    _DayItem(key: 'martes',    label: 'Mar', weekday: 2),
    _DayItem(key: 'miercoles', label: 'Mié', weekday: 3),
    _DayItem(key: 'jueves',    label: 'Jue', weekday: 4),
    _DayItem(key: 'viernes',   label: 'Vie', weekday: 5),
    _DayItem(key: 'sabado',    label: 'Sáb', weekday: 6),
    _DayItem(key: 'domingo',   label: 'Dom', weekday: 7),
  ];

  String? get _todayKey {
    final wd = DateTime.now().weekday; // 1=lunes … 7=domingo
    return _days.firstWhere((d) => d.weekday == wd).key;
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = showWeekend
        ? _days
        : _days.where((d) => d.weekday <= 5).toList();
    final today = _todayKey;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        itemCount: visibleDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day       = visibleDays[index];
          final isSelected = day.key == selectedDay;
          final isToday    = day.key == today;

          return _DayChip(
            day:        day,
            isSelected: isSelected,
            isToday:    isToday,
            onTap:      () => onDaySelected(day.key),
          );
        },
      ),
    );
  }
}

// ── Chip individual ──────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  final _DayItem day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor   = isSelected ? AppTheme.primaryGreen : AppTheme.lightGrey;
    final textColor = isSelected ? AppTheme.white : AppTheme.darkText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: isSelected ? AppTheme.softShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // Indicador de día actual
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? (isSelected ? AppTheme.white : AppTheme.primaryGreen)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelo interno ───────────────────────────────────────────────────────────

class _DayItem {
  final String key;
  final String label;
  final int weekday;

  const _DayItem({
    required this.key,
    required this.label,
    required this.weekday,
  });
}
