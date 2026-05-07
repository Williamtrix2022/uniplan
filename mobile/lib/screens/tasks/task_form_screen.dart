// ============================================
// FORMULARIO DE TAREA (CREAR/EDITAR)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subject.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
import '../../services/subject_service.dart';
import '../../services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedPriority = 'media';
  String selectedStatus = 'pendiente';
  bool selectedIsProject = false;
  int? selectedSubjectId;
  bool _isLoadingSubjects = false;
  List<Subject> _subjects = [];
  
  bool isLoading = false;
  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    
    if (isEditing) {
      _titleController = TextEditingController(text: widget.task!.titulo);
      _descriptionController = TextEditingController(text: widget.task!.descripcion ?? '');
      selectedDate = widget.task!.fechaEntrega;
      selectedPriority = widget.task!.prioridad;
      selectedStatus = widget.task!.estado;
      selectedIsProject = widget.task!.esProyecto;
      selectedSubjectId = widget.task!.idMateria;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
    }

    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
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

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Combinar fecha y hora
      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final task = Task(
        id: isEditing ? widget.task!.id : 0,
        idEstudiante: 0,
        idMateria: selectedSubjectId,
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        fechaEntrega: dateTime,
        prioridad: selectedPriority,
        estado: selectedStatus,
        esProyecto: selectedIsProject,
      );

      if (isEditing) {
        await _taskService.updateTask(widget.task!.id, task);
      } else {
        await _taskService.createTask(task);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Tarea actualizada' : 'Tarea creada'),
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

  Future<void> _loadSubjects() async {
    setState(() => _isLoadingSubjects = true);

    try {
      final subjects = await _subjectService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subjects;
        });
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

  Future<void> _showCreateSubjectDialog() async {
    final Map<String, String?>? draft = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _CreateSubjectDialog(),
    );

    if (!mounted || draft == null) return;

    final name = draft['nombre']?.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la materia es obligatorio'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      final createdSubject = await _subjectService.createSubject(
        nombre: name,
        codigo: draft['codigo'],
      );

      if (!mounted) return;

      setState(() {
        _subjects = [..._subjects, createdSubject]
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
        selectedSubjectId = createdSubject.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia creada correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando materia: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showManageSubjectsSheet() async {
    if (_subjects.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay materias para eliminar'),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    final int? selectedToDelete = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.8;
        final estimatedHeight = 130.0 + (_subjects.length * 64.0);
        final sheetHeight = estimatedHeight.clamp(220.0, maxHeight);

        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eliminar materia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Selecciona la materia que quieres eliminar permanentemente.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            subject.nombre,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle:
                              subject.codigo != null && subject.codigo!.isNotEmpty
                                  ? Text(
                                      subject.codigo!,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    )
                                  : null,
                          trailing:
                              const Icon(Icons.delete_outline, color: AppTheme.error),
                          onTap: () => Navigator.pop(sheetContext, subject.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selectedToDelete == null) return;
    await _confirmAndDeleteSubject(selectedToDelete);
  }

  Future<void> _confirmAndDeleteSubject(int subjectId) async {
    Subject? subject;
    for (final item in _subjects) {
      if (item.id == subjectId) {
        subject = item;
        break;
      }
    }
    if (subject == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text(
          'Se eliminará "${subject!.nombre}" de forma permanente.\\n\\n'
          'Las tareas, notas y sesiones asociadas quedarán sin materia asignada.\\n'
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
      await _subjectService.deleteSubject(subjectId);
      if (!mounted) return;

      setState(() {
        _subjects = _subjects.where((item) => item.id != subjectId).toList();
        if (selectedSubjectId == subjectId) {
          selectedSubjectId = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Materia "${subject.nombre}" eliminada'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando materia: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
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

  BoxDecoration _selectorDecoration(BuildContext context, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
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
          isEditing ? 'Editar tarea' : 'Nueva tarea',
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {},
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                hoverColor: colorScheme.surfaceContainerHighest,
              ),
              icon: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Título de la tarea', context),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _fieldDecoration(
                          context,
                          hintText: 'Ej. Estudiar para el examen',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El título es obligatorio';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionLabel('Descripción', context),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: _fieldDecoration(
                        context,
                        hintText: 'Agrega más detalles...',
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionLabel('Materia asociada', context),
                        if (_subjects.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _showManageSubjectsSheet,
                            child: const Text(
                              'ELIMINAR MATERIA',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_subjects.isEmpty && !_isLoadingSubjects)
                      GestureDetector(
                        onTap: _showCreateSubjectDialog,
                        child: Container(
                          decoration: _selectorDecoration(context),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: colorScheme.secondaryContainer,
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Agregar nueva materia',
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.darkText,
                                      ),
                                    ),
                                    Text(
                                      'Toca para crearla',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: AppTheme.greyText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_isLoadingSubjects)
                      const LinearProgressIndicator(color: AppTheme.primaryGreen)
                    else
                      Container(
                        decoration: _selectorDecoration(context),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: selectedSubjectId,
                            isExpanded: true,
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                'CAMBIAR',
                                style: TextStyle(
                                  color: AppTheme.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            selectedItemBuilder: (context) => [
                              _buildSelectedSubjectRow(
                                context,
                                'Sin materia',
                                'Sin código',
                              ),
                              ..._subjects.map(
                                (subject) => _buildSelectedSubjectRow(
                                  context,
                                  subject.nombre,
                                  subject.codigo?.isNotEmpty == true
                                      ? subject.codigo!
                                      : 'Sin código',
                                ),
                              ),
                            ],
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: _buildSelectedSubjectRow(
                                  context,
                                  'Sin materia',
                                  'Sin código',
                                ),
                              ),
                              ..._subjects.map(
                                (subject) => DropdownMenuItem<int?>(
                                  value: subject.id,
                                  child: _buildSelectedSubjectRow(
                                    context,
                                    subject.nombre,
                                    subject.codigo?.isNotEmpty == true
                                        ? subject.codigo!
                                        : 'Sin código',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(() => selectedSubjectId = value),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    _buildSectionLabel('Fecha de entrega', context),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: _selectorDecoration(context),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMMM d, yyyy', 'es_ES').format(selectedDate),
                              style: textTheme.bodyLarge?.copyWith(color: AppTheme.darkText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionLabel('Prioridad', context),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _buildPriorityItem(context, 'Baja', 'baja'),
                          _buildPriorityItem(context, 'Media', 'media'),
                          _buildPriorityItem(context, 'Alta', 'alta'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (isEditing) ...[
                      _buildSectionLabel('Estado', context),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildStatusChip(context, 'Pendiente', 'pendiente'),
                          _buildStatusChip(context, 'En progreso', 'en_progreso'),
                          _buildStatusChip(context, 'Completada', 'completada'),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    _buildSectionLabel('Marcar como proyecto', context),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, color: AppTheme.darkText),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marcar como proyecto',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Text(
                                  'Las tareas de proyecto aparecen en su pestaña',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: selectedIsProject,
                            activeTrackColor: AppTheme.primaryGreen,
                            onChanged: (value) => setState(() => selectedIsProject = value),
                          ),
                        ],
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
                      onPressed: isLoading ? null : _saveTask,
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
                              isEditing ? 'Actualizar tarea' : 'Crear tarea',
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

  Widget _buildSelectedSubjectRow(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: colorScheme.secondaryContainer,
          ),
          child: Icon(
            Icons.school_outlined,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: textTheme.labelMedium?.copyWith(color: AppTheme.greyText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityItem(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => setState(() => selectedStatus = value),
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
