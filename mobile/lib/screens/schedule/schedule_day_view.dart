// ============================================
// PANTALLA: VISTA DE DÍA (lista de clases)
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import 'class_detail_screen.dart';
import 'schedule_form_screen.dart';

class ScheduleDayView extends StatelessWidget {
  final String dia;

  const ScheduleDayView({super.key, required this.dia});

  static const Map<String, String> _dayLabels = {
    'lunes':     'Lunes',
    'martes':    'Martes',
    'miercoles': 'Miércoles',
    'jueves':    'Jueves',
    'viernes':   'Viernes',
    'sabado':    'Sábado',
    'domingo':   'Domingo',
  };

  String get _dayLabel => _dayLabels[dia] ?? dia;

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ScheduleProvider>();
    final schedules = provider.schedulesForDay(dia);

    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              hoverColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabel,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.darkText,
              ),
            ),
            Text(
              '${schedules.length} clase${schedules.length != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.colors.greyText,
              ),
            ),
          ],
        ),
      ),
      body: schedules.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: provider.refresh,
              color: context.colors.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingM,
                  AppSizes.paddingM,
                  AppSizes.paddingM,
                  100,
                ),
                itemCount: schedules.length,
                itemBuilder: (context, index) =>
                    _buildClassItem(context, schedules[index], provider),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context, prefillDay: dia),
        backgroundColor: context.colors.primaryGreen,
        child: Icon(Icons.add, color: context.colors.white),
      ),
    );
  }

  // ── Item de clase ────────────────────────────────────────────────────────

  Widget _buildClassItem(
    BuildContext context,
    Schedule schedule,
    ScheduleProvider provider,
  ) {
    final isConflict = provider.conflictIds.contains(schedule.id);
    final color      = schedule.colorMateria;

    return GestureDetector(
      onTap: () => _navigateToDetail(context, schedule),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: isConflict
              ? Border.all(color: context.colors.error, width: 1.5)
              : Border.all(color: context.colors.outlineVariant),
          boxShadow: AppTheme.softShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Franja lateral de color
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusL),
                    bottomLeft: Radius.circular(AppSizes.radiusL),
                  ),
                ),
              ),

              // Columna de hora a la izquierda
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      schedule.horaInicioFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(width: 1, height: 12, color: context.colors.borderGrey),
                    const SizedBox(height: 2),
                    Text(
                      schedule.horaFinFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.colors.greyText,
                      ),
                    ),
                  ],
                ),
              ),

              // Separador vertical
              Container(width: 1, color: context.colors.borderGrey),

              // Contenido principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              schedule.materiaNombre ?? 'Sin materia',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.colors.darkText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isConflict)
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: context.colors.error,
                            ),
                        ],
                      ),
                      if (schedule.materiaProfesor != null &&
                          schedule.materiaProfesor!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          schedule.materiaProfesor!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.colors.greyText,
                          ),
                        ),
                      ],
                      if (schedule.aula != null &&
                          schedule.aula!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 12,
                              color: context.colors.greyText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.aula!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.colors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Píldora de duración
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _duracionLabel(schedule.duracionMinutos),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.greyText,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Estado vacío ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 72,
            color: context.colors.primaryGreen.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin clases el $_dayLabel',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.colors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar una clase',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Navegación ───────────────────────────────────────────────────────────

  Future<void> _navigateToDetail(BuildContext context, Schedule s) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClassDetailScreen(schedule: s)),
    );
    if (result == true && context.mounted) {
      context.read<ScheduleProvider>().refresh();
    }
  }

  Future<void> _navigateToForm(
    BuildContext context, {
    String? prefillDay,
  }) async {
    Schedule? prefilled;
    if (prefillDay != null) {
      prefilled = Schedule(
        id:           0,
        idEstudiante: 0,
        idMateria:    0,
        dia:          prefillDay,
        horaInicio:   '08:00:00',
        horaFin:      '10:00:00',
        fechaCreacion: DateTime.now(),
      );
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(schedule: prefilled),
      ),
    );
    if (result == true && context.mounted) {
      context.read<ScheduleProvider>().refresh();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _duracionLabel(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
