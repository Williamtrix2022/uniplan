// ============================================
// PANTALLA PRINCIPAL DE CALIFICACIONES
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';
import '../../providers/grade_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/grades/average_indicator.dart';
import '../../widgets/grades/grade_chart.dart';
import '../../widgets/grades/subject_grades_list.dart';
import '../profile/profile_screen.dart';
import 'grade_form_screen.dart';
import 'manage_subjects_screen.dart';
import 'subject_grades_screen.dart';

/// Resumen y tendencia de calificaciones. Ya no es un destino de primer nivel
/// del menú inferior (ver MJ-03/MJ-12 en docs/mvp/UNIPLAN_EVOLUCION.md) — se
/// alcanza desde "Materias" (`ManageSubjectsScreen`), que es ahora el tab.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final AuthService _authService = AuthService();
  late final Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _authService.getUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GradeProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GradeProvider>();
    final isLoading = provider.isLoading && !provider.isInitialized;

    return Scaffold(
      backgroundColor: context.colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            if (provider.error != null) _buildErrorBanner(provider),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: context.colors.primaryGreen),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      color: context.colors.primaryGreen,
                      child: provider.grades.isEmpty
                          ? _buildEmptyState(context)
                          : _buildContent(context, provider),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        backgroundColor: context.colors.primaryGreen,
        child: Icon(Icons.add, color: context.colors.white),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: context.colors.darkText,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (Navigator.canPop(context)) const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mis Notas',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.darkText,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigateToManageSubjects(context),
            icon: const Icon(Icons.school_outlined),
            color: context.colors.darkText,
            iconSize: 22,
            tooltip: 'Gestionar materias',
          ),
          const SizedBox(width: 4),
          FutureBuilder<String>(
            future: _userNameFuture,
            builder: (context, snapshot) {
              return UserAvatar(
                name: snapshot.data ?? '',
                size: 36,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(GradeProvider provider) {
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
        color: context.colors.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: GoogleFonts.inter(fontSize: 13, color: context.colors.error),
            ),
          ),
          GestureDetector(
            onTap: provider.clearError,
            child: Icon(Icons.close, color: context.colors.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingL,
            AppSizes.paddingL,
            AppSizes.paddingL,
            96,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grade_outlined,
                    size: 64,
                    color: context.colors.greyText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes calificaciones',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registra tu primera nota para ver tu progreso académico',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: context.colors.greyText),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva calificación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primaryGreen,
                      foregroundColor: context.colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _navigateToManageSubjects(context),
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: const Text('Gestionar materias'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.greyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, GradeProvider provider) {
    final summary = provider.summary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingL,
        AppSizes.paddingL,
        AppSizes.paddingL,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AverageIndicator(promedio: summary?.promedioGeneral),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis materias',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.darkText,
                ),
              ),
              TextButton.icon(
                onPressed: () => _navigateToManageSubjects(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Gestionar'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.greyText,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary != null && summary.materias.isNotEmpty)
            SubjectGradesList(
              materias: summary.materias,
              onTap: (materia) => _navigateToSubject(context, materia),
            )
          else
            Text(
              'No hay materias con calificaciones aún',
              style: GoogleFonts.inter(fontSize: 13, color: context.colors.greyText),
            ),
          const SizedBox(height: 24),
          Text(
            'Tendencia de notas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: GradeLineChart(grades: provider.grades),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _navigateToForm(BuildContext context) async {
    final provider = context.read<GradeProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GradeFormScreen()),
    );
    if (!mounted) return;
    if (result == true) provider.refresh();
  }

  Future<void> _navigateToManageSubjects(BuildContext context) async {
    final provider = context.read<GradeProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageSubjectsScreen()),
    );
    if (!mounted) return;
    provider.refresh();
  }

  Future<void> _navigateToSubject(
    BuildContext context,
    SubjectAverage materia,
  ) async {
    final provider = context.read<GradeProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectGradesScreen(
          idMateria: materia.idMateria,
          materiaNombre: materia.materiaNombre,
          materiaColor: materia.materiaColor,
        ),
      ),
    );
    if (!mounted) return;
    provider.refresh();
  }
}
