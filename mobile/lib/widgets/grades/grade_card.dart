// ============================================
// WIDGET: TARJETA DE CALIFICACIÓN
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';

class GradeCard extends StatelessWidget {
  final Grade grade;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GradeCard({
    super.key,
    required this.grade,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: AppTheme.softShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: grade.estadoColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusM),
                    bottomLeft: Radius.circular(AppSizes.radiusM),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                grade.tipoLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${grade.porcentaje.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          grade.descripcion?.isNotEmpty == true
                              ? grade.descripcion!
                              : grade.tipoLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (grade.fechaEvaluacion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy', 'es_ES')
                                .format(grade.fechaEvaluacion!),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    grade.valor.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: grade.estadoColor,
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.greyText),
                      onSelected: (value) {
                        if (value == 'delete') onDelete!();
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
}
