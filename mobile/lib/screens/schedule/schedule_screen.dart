// ============================================
// PANTALLA PRINCIPAL DE HORARIOS
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/schedule/week_view.dart';
import 'class_detail_screen.dart';
import 'schedule_day_view.dart';
import 'schedule_form_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().initialize();
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, provider),
            if (provider.error != null) _buildErrorBanner(provider),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                color: AppTheme.primaryGreen,
                child: WeekView(
                  schedules:    provider.schedules,
                  conflictIds:  provider.conflictIds,
                  isLoading:    provider.isLoading,
                  onScheduleTap: (schedule) => _navigateToDetail(schedule),
                  onDaySelected: (day)      => _navigateToDayView(day),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }

  // ── AppBar personalizado ─────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, ScheduleProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.darkText,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mi Horario',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ),
          // Indicador de conflictos en la AppBar
          if (provider.hasConflicts)
            IconButton(
              onPressed: () => _showConflictsInfo(context, provider),
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
              ),
              tooltip: 'Ver conflictos',
            ),
        ],
      ),
    );
  }

  // ── Banner de error ──────────────────────────────────────────────────────

  Widget _buildErrorBanner(ScheduleProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.error),
            ),
          ),
          GestureDetector(
            onTap: provider.clearError,
            child: const Icon(Icons.close, color: AppTheme.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Diálogo de conflictos ────────────────────────────────────────────────

  void _showConflictsInfo(BuildContext context, ScheduleProvider provider) {
    final count = provider.conflictIds.length ~/ 2;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text(
              'Conflictos de horario',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Tienes $count par${count != 1 ? 'es' : ''} de clase${count != 1 ? 's' : ''} '
          'con horarios superpuestos. Edita o elimina los bloques en conflicto '
          '(marcados con borde rojo en la cuadrícula).',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ── Navegación ───────────────────────────────────────────────────────────

  Future<void> _navigateToForm(BuildContext context, {schedule}) async {
    final provider = context.read<ScheduleProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(schedule: schedule),
      ),
    );
    if (!mounted) return;
    if (result == true) provider.refresh();
  }

  Future<void> _navigateToDetail(Schedule schedule) async {
    final provider = context.read<ScheduleProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassDetailScreen(schedule: schedule),
      ),
    );
    if (!mounted) return;
    if (result == true) provider.refresh();
  }

  Future<void> _navigateToDayView(String day) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScheduleDayView(dia: day)),
    );
  }
}
