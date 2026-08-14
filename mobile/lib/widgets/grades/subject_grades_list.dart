// ============================================
// WIDGET: LISTA DE MATERIAS CON PROMEDIO
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';

class SubjectGradesList extends StatelessWidget {
  final List<SubjectAverage> materias;
  final void Function(SubjectAverage materia)? onTap;

  const SubjectGradesList({
    super.key,
    required this.materias,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: materias.map((m) => _buildItem(context, m)).toList(),
    );
  }

  Widget _buildItem(BuildContext context, SubjectAverage materia) {
    final promedio = materia.promedio;
    final progress = promedio != null ? (promedio / 5.0).clamp(0.0, 1.0) : 0.0;
    final color = promedio != null ? Grade.colorForValor(promedio) : AppTheme.greyText;

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(materia) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: materia.colorMateria,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    materia.materiaNombre,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  promedio != null ? promedio.toStringAsFixed(2) : '--',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    color: AppTheme.greyText, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.lightGrey,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${materia.porcentajeAcumulado.toStringAsFixed(0)}% evaluado · '
              '${_estadoLabel(materia.estado)}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.greyText),
            ),
          ],
        ),
      ),
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'Aprobado';
      case 'excelente':
        return 'Excelente';
      case 'en_riesgo':
      default:
        return 'En riesgo';
    }
  }
}
