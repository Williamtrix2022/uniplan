// ============================================
// FORMULARIO DE CALIFICACIÓN (CREAR/EDITAR)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/grade.dart';
import '../../models/subject.dart';
import '../../providers/grade_provider.dart';
import '../../services/subject_service.dart';

class GradeFormScreen extends StatefulWidget {
  final Grade? grade;
  final int? initialSubjectId;

  const GradeFormScreen({super.key, this.grade, this.initialSubjectId});

  @override
  State<GradeFormScreen> createState() => _GradeFormScreenState();
}

class _GradeFormScreenState extends State<GradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubjectService _subjectService = SubjectService();

  late TextEditingController _valorController;
  late TextEditingController _porcentajeController;
  late TextEditingController _descripcionController;

  int? selectedSubjectId;
  String selectedTipo = 'parcial';
  DateTime? selectedDate;
  bool _isLoadingSubjects = false;
  List<Subject> _subjects = [];

  bool isLoading = false;
  bool get isEditing => widget.grade != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final grade = widget.grade!;
      _valorController =
          TextEditingController(text: grade.valor.toStringAsFixed(2));
      _porcentajeController =
          TextEditingController(text: grade.porcentaje.toStringAsFixed(0));
      _descripcionController =
          TextEditingController(text: grade.descripcion ?? '');
      selectedSubjectId = grade.idMateria;
      selectedTipo = grade.tipo;
      selectedDate = grade.fechaEvaluacion;
    } else {
      _valorController = TextEditingController();
      _porcentajeController = TextEditingController();
      _descripcionController = TextEditingController();
      selectedSubjectId = widget.initialSubjectId;
    }

    _loadSubjects();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _porcentajeController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoadingSubjects = true);

    try {
      final subjects = await _subjectService.getSubjects();
      if (mounted) {
        setState(() => _subjects = subjects);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando materias: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubjects = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: AppTheme.white,
              onSurface: AppTheme.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una materia'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final valor =
          double.parse(_valorController.text.trim().replaceAll(',', '.'));
      final porcentaje = double.parse(
          _porcentajeController.text.trim().replaceAll(',', '.'));

      final grade = Grade(
        id: isEditing ? widget.grade!.id : 0,
        idEstudiante: isEditing ? widget.grade!.idEstudiante : 0,
        idMateria: selectedSubjectId!,
        tipo: selectedTipo,
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        valor: valor,
        porcentaje: porcentaje,
        fechaEvaluacion: selectedDate,
      );

      final provider = context.read<GradeProvider>();
      if (isEditing) {
        await provider.updateGrade(widget.grade!.id, grade);
      } else {
        await provider.createGrade(grade);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Calificación actualizada' : 'Calificación creada',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSectionLabel(String text, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }

  BoxDecoration _selectorDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
          isEditing ? 'Editar calificación' : 'Nueva calificación',
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Materia', context),
                    const SizedBox(height: 8),
                    _buildSubjectSelector(context, textTheme),
                    const SizedBox(height: 32),
                    _buildSectionLabel('Tipo de evaluación', context),
                    const SizedBox(height: 8),
                    _buildTipoSelector(context, colorScheme),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Nota (0.0 - 5.0)', context),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 56,
                                child: TextFormField(
                                  controller: _valorController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _fieldDecoration(context,
                                      hintText: 'Ej. 4.20'),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Obligatorio';
                                    }
                                    final parsed = double.tryParse(
                                        value.trim().replaceAll(',', '.'));
                                    if (parsed == null) return 'Nota inválida';
                                    if (parsed < 0 || parsed > 5) {
                                      return 'Entre 0.0 y 5.0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Porcentaje (%)', context),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 56,
                                child: TextFormField(
                                  controller: _porcentajeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _fieldDecoration(context,
                                      hintText: 'Ej. 20'),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Obligatorio';
                                    }
                                    final parsed = double.tryParse(
                                        value.trim().replaceAll(',', '.'));
                                    if (parsed == null) return 'Valor inválido';
                                    if (parsed < 0 || parsed > 100) {
                                      return 'Entre 0 y 100';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionLabel('Descripción (opcional)', context),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descripcionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _fieldDecoration(
                        context,
                        hintText: 'Ej. Parcial 1er corte',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionLabel(
                      'Fecha de evaluación (opcional)',
                      context,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: _selectorDecoration(context),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppTheme.primaryGreen),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? DateFormat('MMMM d, yyyy', 'es_ES')
                                      .format(selectedDate!)
                                  : 'Sin fecha',
                              style: textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.darkText),
                            ),
                            if (selectedDate != null) ...[
                              const Spacer(),
                              IconButton(
                                onPressed: () =>
                                    setState(() => selectedDate = null),
                                icon: const Icon(Icons.close, size: 18),
                                color: AppTheme.greyText,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
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
                      onPressed: isLoading ? null : _saveGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppTheme.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Actualizar calificación'
                                  : 'Crear calificación',
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
                          borderRadius: BorderRadius.circular(12),
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

  Widget _buildSubjectSelector(BuildContext context, TextTheme textTheme) {
    if (_isLoadingSubjects) {
      return const LinearProgressIndicator(color: AppTheme.primaryGreen);
    }

    if (_subjects.isEmpty) {
      return Container(
        decoration: _selectorDecoration(context),
        padding: const EdgeInsets.all(16),
        child: Text(
          'No tienes materias registradas. Crea una desde Tareas primero.',
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.greyText),
        ),
      );
    }

    return Container(
      decoration: _selectorDecoration(context),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedSubjectId,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Selecciona una materia'),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          items: _subjects
              .map(
                (subject) => DropdownMenuItem<int?>(
                  value: subject.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      subject.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.darkText),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => selectedSubjectId = value),
        ),
      ),
    );
  }

  Widget _buildTipoSelector(BuildContext context, ColorScheme colorScheme) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: Grade.tipoLabels.entries
          .map((entry) =>
              _buildTipoChip(context, entry.value, entry.key, colorScheme))
          .toList(),
    );
  }

  Widget _buildTipoChip(
    BuildContext context,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    final isSelected = selectedTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => setState(() => selectedTipo = value),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.darkText,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
