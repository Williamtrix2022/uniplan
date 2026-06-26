// ============================================
// FORMULARIO DE CLASE (CREAR / EDITAR)
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/schedule.dart';
import '../../models/subject.dart';
import '../../providers/schedule_provider.dart';
import '../../services/schedule_service.dart';
import '../../services/subject_service.dart';
import '../../widgets/schedule/day_selector.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _aulaController = TextEditingController();
  final _subjectService = SubjectService();

  List<Subject> _subjects = [];
  bool _isLoadingSubjects = false;

  int? _selectedSubjectId;
  String? _selectedDay;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin    = const TimeOfDay(hour: 10, minute: 0);

  bool _isSaving = false;
  bool get _isEditing => widget.schedule != null;

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.schedule!;
      _selectedSubjectId = s.idMateria;
      _selectedDay       = s.dia;
      _horaInicio        = s.horaInicioTime;
      _horaFin           = s.horaFinTime;
      _aulaController.text = s.aula ?? '';
    }
    _loadSubjects();
  }

  @override
  void dispose() {
    _aulaController.dispose();
    super.dispose();
  }

  // ── Carga de materias ────────────────────────────────────────────────────

  Future<void> _loadSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final list = await _subjectService.getSubjects();
      if (mounted) setState(() => _subjects = list);
    } catch (e) {
      if (mounted) _showSnack('Error cargando materias: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _horaInicio : _horaFin;
    final picked  = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
            onPrimary: AppTheme.white,
            onSurface: AppTheme.darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _horaInicio = picked;
        // Si la nueva hora de inicio >= fin, ajustar fin
        final inicioMins = picked.hour * 60 + picked.minute;
        final finMins    = _horaFin.hour * 60 + _horaFin.minute;
        if (inicioMins >= finMins) {
          final newEnd = inicioMins + 60;
          _horaFin = TimeOfDay(hour: newEnd ~/ 60, minute: newEnd % 60);
        }
      } else {
        _horaFin = picked;
      }
    });
  }

  // ── Nueva materia (inline) ───────────────────────────────────────────────

  Future<void> _showCreateSubjectDialog() async {
    final draft = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _CreateSubjectDialog(),
    );
    if (!mounted || draft == null) return;

    final name = draft['nombre']?.trim() ?? '';
    if (name.isEmpty) {
      _showSnack('El nombre es obligatorio', isError: true);
      return;
    }

    try {
      final created = await _subjectService.createSubject(
        nombre: name,
        codigo: draft['codigo'],
      );
      if (!mounted) return;
      setState(() {
        _subjects = [..._subjects, created]
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
        _selectedSubjectId = created.id;
      });
      _showSnack('Materia creada');
    } catch (e) {
      if (mounted) _showSnack('Error creando materia: $e', isError: true);
    }
  }

  // ── Guardar ──────────────────────────────────────────────────────────────

  Future<void> _save({bool force = false}) async {
    // Validaciones
    if (_selectedSubjectId == null) {
      _showSnack('Selecciona una materia', isError: true);
      return;
    }
    if (_selectedDay == null) {
      _showSnack('Selecciona un día', isError: true);
      return;
    }
    final inicioMins = _horaInicio.hour * 60 + _horaInicio.minute;
    final finMins    = _horaFin.hour * 60 + _horaFin.minute;
    if (finMins <= inicioMins) {
      _showSnack('La hora de fin debe ser posterior a la de inicio', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final horaInicioStr =
        '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}:00';
    final horaFinStr =
        '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}:00';

    final draft = Schedule(
      id:            _isEditing ? widget.schedule!.id : 0,
      idEstudiante:  0,
      idMateria:     _selectedSubjectId!,
      dia:           _selectedDay!,
      horaInicio:    horaInicioStr,
      horaFin:       horaFinStr,
      aula:          _aulaController.text.trim().isEmpty
                         ? null
                         : _aulaController.text.trim(),
      fechaCreacion: DateTime.now(),
    );

    try {
      final provider = context.read<ScheduleProvider>();
      if (_isEditing) {
        await provider.updateSchedule(widget.schedule!.id, draft, force: force);
      } else {
        await provider.createSchedule(draft, force: force);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context, true);
      messenger?.showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Clase actualizada' : 'Clase agregada'),
        backgroundColor: AppTheme.success,
      ));
    } on ScheduleConflictException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      await _showConflictDialog(e);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  // ── Diálogo de conflictos ────────────────────────────────────────────────

  Future<void> _showConflictDialog(ScheduleConflictException e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text(
              'Conflicto de horario',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este bloque se superpone con:',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.greyText),
            ),
            const SizedBox(height: 8),
            ...e.conflicts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.colorMateria,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.materiaNombre ?? 'Clase',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            '${c.dia} · ${c.rangoHorario}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Deseas guardar igualmente?',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Guardar de todos modos'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _save(force: true);
    }
  }

  // ── Helpers UI ───────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.white,
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
              hoverColor: colorScheme.surfaceContainerHighest,
            ),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        title: Text(
          _isEditing ? 'Editar clase' : 'Nueva clase',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Materia ───────────────────────────────────────────
                  _buildSectionLabel('Materia'),
                  const SizedBox(height: 8),
                  _buildSubjectSelector(colorScheme),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ── Día ───────────────────────────────────────────────
                  _buildSectionLabel('Día de la semana'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: DaySelector(
                      selectedDay: _selectedDay,
                      onDaySelected: (day) => setState(() => _selectedDay = day),
                      showWeekend: true,
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ── Horario ───────────────────────────────────────────
                  _buildSectionLabel('Horario'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Inicio',
                          time: _horaInicio,
                          onTap: () => _pickTime(isStart: true),
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppTheme.greyText,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Fin',
                          time: _horaFin,
                          onTap: () => _pickTime(isStart: false),
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ── Aula ──────────────────────────────────────────────
                  _buildSectionLabel('Aula (opcional)'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _aulaController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Bloque A - 204',
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryGreen, width: 1.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.meeting_room_outlined,
                          color: AppTheme.greyText,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingL),
                ],
              ),
            ),
          ),

          // ── Botones fijos al fondo ────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppTheme.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Actualizar clase' : 'Crear clase',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets internos ─────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(ColorScheme colorScheme) {
    if (_isLoadingSubjects) {
      return const LinearProgressIndicator(color: AppTheme.primaryGreen);
    }

    if (_subjects.isEmpty) {
      return GestureDetector(
        onTap: _showCreateSubjectDialog,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.secondaryContainer,
                ),
                child: Icon(Icons.school_outlined,
                    color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar nueva materia',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      'Toca para crearla',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => _subjects.first,
    );
    _selectedSubjectId ??= selected.id;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSubjectId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          icon: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.greyText),
          ),
          selectedItemBuilder: (_) => _subjects
              .map((s) => _buildSubjectRow(s, colorScheme))
              .toList(),
          items: _subjects
              .map((s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: _buildSubjectRow(s, colorScheme),
                  ))
              .toList(),
          onChanged: (id) => setState(() => _selectedSubjectId = id),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(Subject subject, ColorScheme colorScheme) {
    Color subjectColor;
    try {
      final clean = subject.color.replaceFirst('#', '');
      subjectColor = Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      subjectColor = AppTheme.primaryGreen;
    }

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: subjectColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subject.nombre,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (subject.profesor != null && subject.profesor!.isNotEmpty)
          Text(
            subject.profesor!,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.greyText),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatTimeOfDay(time),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo inline "Nueva materia" ───────────────────────────────────────────

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
              hintText: 'Ej. Álgebra Lineal',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código (opcional)',
              hintText: 'Ej. MAT-201',
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
