// ============================================
// PANTALLA: DETALLE DE CLASE
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import 'schedule_form_screen.dart';

class ClassDetailScreen extends StatelessWidget {
  final Schedule schedule;

  const ClassDetailScreen({super.key, required this.schedule});

  static const Map<String, String> _dayLabels = {
    'lunes':     'Lunes',
    'martes':    'Martes',
    'miercoles': 'Miércoles',
    'jueves':    'Jueves',
    'viernes':   'Viernes',
    'sabado':    'Sábado',
    'domingo':   'Domingo',
  };

  @override
  Widget build(BuildContext context) {
    final color = schedule.colorMateria;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, color),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildInfoSection(context),
                const SizedBox(height: AppSizes.paddingXL),
                _buildActions(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar con color de materia ──────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context, Color color) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: color,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToEdit(context),
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: 'Editar',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.75)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    schedule.materiaNombre ?? 'Sin materia',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (schedule.materiaProfesor != null &&
                      schedule.materiaProfesor!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      schedule.materiaProfesor!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sección de información ───────────────────────────────────────────────

  Widget _buildInfoSection(BuildContext context) {
    final dayLabel = _dayLabels[schedule.dia] ?? schedule.dia;
    final duracion = schedule.duracionMinutos;
    final hours    = duracion ~/ 60;
    final mins     = duracion % 60;
    final durStr   = hours > 0
        ? (mins > 0 ? '${hours}h ${mins}min' : '${hours}h')
        : '${mins}min';

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Día',
            value: dayLabel,
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Horario',
            value: schedule.rangoHorario,
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.timelapse_rounded,
            label: 'Duración',
            value: durStr,
          ),
          if (schedule.aula != null && schedule.aula!.isNotEmpty) ...[
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.meeting_room_outlined,
              label: 'Aula',
              value: schedule.aula!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppTheme.borderGrey,
      indent: 56,
    );
  }

  // ── Botones de acción ────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEdit(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar clase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar clase'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navegación y acciones ────────────────────────────────────────────────

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(schedule: schedule),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text(
          '¿Eliminar "${schedule.materiaNombre ?? 'esta clase'}" del '
          '${_dayLabels[schedule.dia] ?? schedule.dia}?\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ScheduleProvider>().deleteSchedule(schedule.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }
}
