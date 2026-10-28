// ============================================
// PANTALLA: MATERIAS (destino de primer nivel del menú inferior)
// ============================================
//
// Ver MJ-03/MJ-12 en docs/mvp/UNIPLAN_EVOLUCION.md: "Materias" reemplaza a
// "Notas" como tab de primer nivel; las calificaciones de cada materia viven
// dentro de ella (SubjectGradesScreen), no al revés.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/subject.dart';
import '../../providers/subject_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/user_avatar.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/tasks_screen.dart';
import 'grades_screen.dart';
import 'subject_grades_screen.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  int _selectedIndex = 3;
  final AuthService _authService = AuthService();
  late final Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _authService.getUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectProvider>().initialize();
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TasksScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
          (route) => false,
        );
        break;
      case 3:
        // Ya estamos en Materias, solo refrescar datos.
        context.read<SubjectProvider>().refresh();
        break;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  // ── Crear materia ────────────────────────────────────────────────────────

  Future<void> _showCreateSubjectDialog() async {
    final draft = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _CreateSubjectDialog(),
    );
    if (!mounted || draft == null) return;

    final name = draft['nombre']?.trim() ?? '';
    if (name.isEmpty) {
      _showSnack('El nombre de la materia es obligatorio', isError: true);
      return;
    }

    try {
      await context.read<SubjectProvider>().createSubject(
            nombre: name,
            codigo: draft['codigo'],
          );
      if (!mounted) return;
      _showSnack('Materia creada correctamente');
    } catch (e) {
      if (mounted) _showSnack('Error creando materia: $e', isError: true);
    }
  }

  // ── Eliminar materia ─────────────────────────────────────────────────────

  Future<void> _confirmAndDeleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text(
          'Se eliminará "${subject.nombre}" de forma permanente.\n\n'
          'Las tareas, notas y sesiones asociadas quedarán sin materia asignada.\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<SubjectProvider>().deleteSubject(subject.id);
      if (!mounted) return;
      _showSnack('Materia "${subject.nombre}" eliminada');
    } catch (e) {
      if (mounted) _showSnack('Error eliminando materia: $e', isError: true);
    }
  }

  void _openSubjectGrades(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectGradesScreen(
          idMateria: subject.id,
          materiaNombre: subject.nombre,
          materiaColor: subject.color,
        ),
      ),
    );
  }

  void _openGradesOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GradesScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubjectProvider>();
    final isLoading = provider.isLoading && !provider.isInitialized;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    hoverColor: AppTheme.surfaceContainerHighest,
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
              )
            : null,
        title: Text(
          'Mis materias',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openGradesOverview,
            icon: const Icon(Icons.insights_outlined),
            color: AppTheme.darkText,
            tooltip: 'Resumen y tendencia de notas',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: FutureBuilder<String>(
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
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: provider.refresh,
              color: AppTheme.primaryGreen,
              child: provider.subjects.isEmpty
                  ? _buildEmptyState()
                  : _buildSubjectsList(provider.subjects),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSubjectDialog,
        backgroundColor: AppTheme.primaryGreen,
        tooltip: 'Nueva materia',
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  Widget _buildEmptyState() {
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
                    Icons.school_outlined,
                    size: 64,
                    color: AppTheme.greyText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Todavía no tenés materias',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creá la primera con el botón "+" para empezar a '
                    'organizar tus tareas, clases y calificaciones',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: AppTheme.greyText),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsList(List<Subject> subjects) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingL,
        AppSizes.paddingL,
        AppSizes.paddingL,
        96,
      ),
      child: Column(
        children: subjects.map(_buildSubjectRow).toList(),
      ),
    );
  }

  Widget _buildSubjectRow(Subject subject) {
    Color subjectColor;
    try {
      final clean = subject.color.replaceFirst('#', '');
      subjectColor = Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      subjectColor = AppTheme.primaryGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        onTap: () => _openSubjectGrades(subject),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: subjectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.nombre,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (subject.codigo != null &&
                        subject.codigo!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subject.codigo!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.greyText),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.greyText),
              IconButton(
                onPressed: () => _confirmAndDeleteSubject(subject),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.error,
                style: IconButton.styleFrom(
                  hoverColor: AppTheme.errorContainer,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Diálogo "Nueva materia" ──────────────────────────────────────────────────

class _CreateSubjectDialog extends StatefulWidget {
  const _CreateSubjectDialog();

  @override
  State<_CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<_CreateSubjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop({
      'nombre': name,
      'codigo': _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva materia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              hintText: 'Ej. Matemáticas',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código (opcional)',
              hintText: 'Ej. MAT-101',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
