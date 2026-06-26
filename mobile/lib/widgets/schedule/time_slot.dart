// ============================================
// WIDGET: ETIQUETA DE HORA (EJE Y DEL GRID)
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Etiqueta de hora para el eje vertical del ScheduleGrid.
/// Cada instancia ocupa exactamente [hourHeight] de alto y
/// muestra la hora en la parte superior del bloque.
class TimeSlot extends StatelessWidget {
  final int hour;
  final double hourHeight;

  const TimeSlot({
    super.key,
    required this.hour,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hourHeight,
      width: 44,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          '${hour.toString().padLeft(2, '0')}:00',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.greyText,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}
