// ============================================
// WIDGET: INDICADOR DE PROMEDIO GENERAL
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';
import 'progress_ring.dart';

/// Muestra el promedio general del estudiante dentro de un anillo de
/// progreso, coloreado según la franja de la nota (rojo/ámbar/verde).
class AverageIndicator extends StatelessWidget {
  final double? promedio;
  final double size;

  const AverageIndicator({
    super.key,
    required this.promedio,
    this.size = 140,
  });

  Color get _color {
    final valor = promedio;
    if (valor == null) return AppTheme.greyText;
    return Grade.colorForValor(valor);
  }

  @override
  Widget build(BuildContext context) {
    final valor = promedio;
    final progress = valor != null ? (valor / 5.0).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        ProgressRing(
          progress: progress,
          color: _color,
          backgroundColor: AppTheme.white,
          size: size,
          strokeWidth: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valor != null ? valor.toStringAsFixed(2) : '--',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'de 5.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.greyText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Promedio General',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }
}
