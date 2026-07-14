// ============================================
// WIDGETS: GRÁFICAS DE CALIFICACIONES (fl_chart)
// ============================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';

/// Línea de tendencia de las notas (valor) a lo largo del tiempo, ordenadas
/// por fecha de evaluación. Solo se grafican las calificaciones con fecha.
class GradeLineChart extends StatelessWidget {
  final List<Grade> grades;
  final double height;

  const GradeLineChart({
    super.key,
    required this.grades,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final withDate = grades.where((g) => g.fechaEvaluacion != null).toList()
      ..sort((a, b) => a.fechaEvaluacion!.compareTo(b.fechaEvaluacion!));

    if (withDate.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Se necesitan al menos 2 calificaciones con fecha\n'
            'para mostrar la tendencia',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.greyText),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < withDate.length; i++)
        FlSpot(i.toDouble(), withDate[i].valor),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppTheme.borderGrey,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppTheme.greyText),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 3.0,
                color: AppTheme.warning,
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryGreen,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Grade.colorForValor(spot.y),
                    strokeWidth: 2,
                    strokeColor: AppTheme.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Promedio de nota agrupado por tipo de evaluación (parcial, taller, etc.)
class GradeBarChart extends StatelessWidget {
  final List<Grade> grades;
  final double height;

  const GradeBarChart({
    super.key,
    required this.grades,
    this.height = 200,
  });

  Map<String, double> _averagesByType() {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final g in grades) {
      sums[g.tipo] = (sums[g.tipo] ?? 0) + g.valor;
      counts[g.tipo] = (counts[g.tipo] ?? 0) + 1;
    }
    return {
      for (final tipo in sums.keys) tipo: sums[tipo]! / counts[tipo]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final averages = _averagesByType();

    if (averages.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No hay calificaciones para agrupar',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.greyText),
          ),
        ),
      );
    }

    final tipos = averages.keys.toList();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppTheme.borderGrey,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppTheme.greyText),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= tipos.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      Grade.labelForTipo(tipos[index]),
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppTheme.greyText),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < tipos.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: averages[tipos[i]]!,
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                    color: Grade.colorForValor(averages[tipos[i]]!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
