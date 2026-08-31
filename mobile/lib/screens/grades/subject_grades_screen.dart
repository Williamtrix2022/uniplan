// ============================================
// PANTALLA: CALIFICACIONES DE UNA MATERIA
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';
import '../../providers/grade_provider.dart';
import '../../services/grade_service.dart';
import '../../widgets/grades/grade_card.dart';
import '../../widgets/grades/grade_chart.dart';
import 'grade_form_screen.dart';

class SubjectGradesScreen extends StatefulWidget {
  final int idMateria;
  final String materiaNombre;
  final String? materiaColor;

  const SubjectGradesScreen({
    super.key,
    required this.idMateria,
    required this.materiaNombre,
    this.materiaColor,
  });

  @override
  State<SubjectGradesScreen> createState() => _SubjectGradesScreenState();
}

class _SubjectGradesScreenState extends State<SubjectGradesScreen> {
  final GradeService _gradeService = GradeService();

  SubjectProjection? _projection;
  bool _isLoadingProjection = true;

  Color get _color => Grade.parseColorHex(widget.materiaColor);

  @override
  void initState() {
    super.initState();
    _loadProjection();
  }

  Future<void> _loadProjection() async {
    setState(() => _isLoadingProjection = true);
    try {
      final projection = await _gradeService.getProjection(widget.idMateria);
      if (mounted) setState(() => _projection = projection);
    } catch (_) {
      // Silencioso: la pantalla sigue siendo útil sin la proyección
    } finally {
      if (mounted) setState(() => _isLoadingProjection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GradeProvider>();
    final grades = provider.gradesBySubject(widget.idMateria);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<GradeProvider>().refresh();
          await _loadProjection();
        },
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.paddingL),
                  _buildProjectionCard(context),
                  const SizedBox(height: AppSizes.paddingL),
                  if (grades.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL),
                      child: Text(
                        'Notas por tipo de evaluación',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusM),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: GradeBarChart(grades: grades),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingL),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL),
                    child: Text(
                      'Evaluaciones',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL),
                    child: grades.isEmpty
                        ? _buildEmptyGrades(context)
                        : Column(
                            children: grades
                                .map(
                                  (g) => GradeCard(
                                    grade: g,
                                    onTap: () => _navigateToEdit(context, g),
                                    onDelete: () => _confirmDelete(context, g),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 96),
                ],
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

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _color,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon:
            const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_color, _color.withValues(alpha: 0.75)],
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
                    widget.materiaNombre,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectionCard(BuildContext context) {
    if (_isLoadingProjection) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        child: LinearProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    final projection = _projection;
    if (projection == null) return const SizedBox.shrink();

    final promedio = projection.promedioActual;
    final promedioColor =
        promedio != null ? Grade.colorForValor(promedio) : AppTheme.greyText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: AppTheme.lightGreen,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Promedio actual',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: AppTheme.greyText),
                ),
                const Spacer(),
                Text(
                  promedio != null ? promedio.toStringAsFixed(2) : '--',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: promedioColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (projection.porcentajeAcumulado / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppTheme.white,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${projection.porcentajeAcumulado.toStringAsFixed(0)}% evaluado · '
              '${projection.porcentajeRestante.toStringAsFixed(0)}% restante',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.greyText),
            ),
            const SizedBox(height: 12),
            Text(
              _projectionMessage(projection),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _projectionMessage(SubjectProjection projection) {
    if (projection.yaAprobado) {
      return '¡Ya aprobaste esta materia!';
    }
    if (projection.esImposibleAprobar) {
      return 'Con las notas actuales no es matemáticamente posible aprobar';
    }
    if (projection.notaNecesaria != null) {
      return 'Necesitás sacar ${projection.notaNecesaria!.toStringAsFixed(2)} '
          'en lo que resta para aprobar';
    }
    return 'Registra más calificaciones para ver tu proyección';
  }

  Widget _buildEmptyGrades(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        children: [
          Icon(
            Icons.grade_outlined,
            size: 48,
            color: AppTheme.greyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no hay calificaciones para esta materia',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToForm(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GradeFormScreen(initialSubjectId: widget.idMateria),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      await context.read<GradeProvider>().refresh();
      _loadProjection();
    }
  }

  Future<void> _navigateToEdit(BuildContext context, Grade grade) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GradeFormScreen(grade: grade)),
    );
    if (!context.mounted) return;
    if (result == true) {
      await context.read<GradeProvider>().refresh();
      _loadProjection();
    }
  }

  Future<void> _confirmDelete(BuildContext context, Grade grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar calificación'),
        content: const Text('¿Estás seguro de eliminar esta calificación?'),
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
      await context.read<GradeProvider>().deleteGrade(grade.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      _loadProjection();
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
