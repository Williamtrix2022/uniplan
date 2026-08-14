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
            final density = _CardDensity.fromHeight(constraints.maxHeight);
            return _CardContent(
              schedule: schedule,
              density: density,
              isConflict: isConflict,
              accentColor: baseColor,
            );
          },
        ),
      ),
    );
  }
}

/// Nivel de detalle que puede mostrar la tarjeta según el alto disponible
/// (el alto lo fija el padre —`ScheduleGrid`— en función de la duración de
/// la clase para que el bloque se alinee con las líneas de hora; por eso acá
/// se adapta el CONTENIDO en vez de pedir más espacio).
///
/// Los umbrales incluyen margen de seguridad sobre el contenido real que
/// cada nivel necesita (medido con `GoogleFonts.inter`, `height: 1.2`):
/// - [onlyTitle]: título 1 línea + padding compacto ≈ 20px necesarios.
/// - [titleAndTime]: título 1 línea + horario + padding ≈ 42px necesarios.
/// - [full]: título HASTA 2 líneas + aula + horario + padding ≈ 73px
///   necesarios (el caso que producía el overflow: un título largo que
///   ocupaba 2 líneas no entraba en el umbral anterior de 52px).
enum _CardDensity {
  onlyTitle,
  titleAndTime,
  full;

  static _CardDensity fromHeight(double height) {
    if (height >= 78) return _CardDensity.full;
    if (height >= 44) return _CardDensity.titleAndTime;
    return _CardDensity.onlyTitle;
  }
}

class _CardContent extends StatelessWidget {
  final Schedule schedule;
  final _CardDensity density;
  final bool isConflict;
  final Color accentColor;

  const _CardContent({
    required this.schedule,
    required this.density,
    required this.isConflict,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOnlyTitle = density == _CardDensity.onlyTitle;
    final isFull = density == _CardDensity.full;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isOnlyTitle ? 4 : 6,
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
                    fontSize: isOnlyTitle ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                    height: 1.2,
                  ),
                  // Solo el nivel "full" tiene espacio garantizado para un
                  // título de 2 líneas — en los demás niveles se fuerza a 1
                  // línea (con ellipsis) para no exceder la altura del bloque.
                  maxLines: isFull ? 2 : 1,
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

          if (!isOnlyTitle) ...[
            // Aula — solo en el nivel "full", donde hay espacio garantizado
            // para el título (hasta 2 líneas) + aula + horario.
            if (isFull &&
                schedule.aula != null &&
                schedule.aula!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
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
