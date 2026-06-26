// ============================================
// WIDGET: TARJETA DE CLASE EN EL GRID
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/schedule.dart';

/// Tarjeta que representa un bloque de clase dentro del ScheduleGrid.
/// El padre es responsable de dimensionar y posicionar el widget;
/// ClassCard adapta su contenido según el espacio disponible.
///
/// [isConflict] añade un borde rojo para señalizar superposición.
class ClassCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap;
  final bool isConflict;

  const ClassCard({
    super.key,
    required this.schedule,
    this.onTap,
    this.isConflict = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = schedule.colorMateria;
    final bgColor   = baseColor.withValues(alpha: 0.13);
    final border    = isConflict
        ? Border.all(color: AppTheme.error, width: 1.5)
        : Border(left: BorderSide(color: baseColor, width: 4));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: border,
          boxShadow: AppTheme.softShadow,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 52;
            return _CardContent(
              schedule: schedule,
              isCompact: isCompact,
              isConflict: isConflict,
              accentColor: baseColor,
            );
          },
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Schedule schedule;
  final bool isCompact;
  final bool isConflict;
  final Color accentColor;

  const _CardContent({
    required this.schedule,
    required this.isCompact,
    required this.isConflict,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isCompact ? 4 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre de materia + icono de conflicto
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.materiaNombre ?? 'Sin materia',
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                    height: 1.2,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isConflict)
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: AppTheme.error,
                ),
            ],
          ),

          if (!isCompact) ...[
            // Aula
            if (schedule.aula != null && schedule.aula!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.room_outlined,
                    size: 10,
                    color: AppTheme.greyText,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      schedule.aula!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.greyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Rango horario
            const SizedBox(height: 2),
            Text(
              schedule.rangoHorario,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.greyText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
