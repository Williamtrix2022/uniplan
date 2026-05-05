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
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

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

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Tarea actualizada' : 'Tarea creada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
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
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    bool creating = false;

    final Subject? createdSubject = await showDialog<Subject>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva materia'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      hintText: 'Ej. Matemáticas',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código (opcional)',
                      hintText: 'Ej. MAT-101',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: creating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('El nombre de la materia es obligatorio'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => creating = true);
                          try {
                            final created = await _subjectService.createSubject(
                              nombre: name,
                              codigo: codeController.text.trim().isEmpty
                                  ? null
                                  : codeController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(created);
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => creating = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error creando materia: ${e.toString()}'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();

    if (!mounted || createdSubject == null) return;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar tarea' : 'Nueva tarea'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              CustomTextField(
                label: 'Título de la tarea',
                hintText: 'Ej. Estudiar para el examen',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Descripción
              CustomTextField(
                label: 'Descripción (opcional)',
                hintText: 'Agrega más detalles...',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Materia asociada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Materia asociada',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showCreateSubjectDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar materia'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_subjects.isEmpty && !_isLoadingSubjects)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: const Text(
                    'No tienes materias creadas aún. Usa "Agregar materia".',
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                ),
              if (_isLoadingSubjects)
                const LinearProgressIndicator(color: AppTheme.primaryGreen)
              else
                DropdownButtonFormField<int?>(
                  initialValue: selectedSubjectId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin materia'),
                    ),
                    ..._subjects.map(
                      (subject) => DropdownMenuItem<int?>(
                        value: subject.id,
                        child: Text(subject.nombre),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedSubjectId = value);
                  },
                ),

              const SizedBox(height: 20),

              // Fecha de entrega
              const Text(
                'Fecha de entrega',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Prioridad
              const Text(
                'Prioridad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip('Baja', 'baja', AppTheme.success),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Media', 'media', AppTheme.warning),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Alta', 'alta', AppTheme.error),
                ],
              ),

              const SizedBox(height: 20),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marcar como proyecto'),
                subtitle: const Text('Las tareas de proyecto aparecen en la pestaña Proyecto'),
                value: selectedIsProject,
                activeThumbColor: AppTheme.primaryGreen,
                onChanged: (value) {
                  setState(() => selectedIsProject = value);
                },
              ),

              const SizedBox(height: 8),

              // Estado
              if (isEditing) ...[
                const Text(
                  'Estado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusChip('Pendiente', 'pendiente'),
                    _buildStatusChip('En progreso', 'en_progreso'),
                    _buildStatusChip('Completada', 'completada'),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: isEditing ? 'Actualizar tarea' : 'Crear tarea',
                onPressed: _saveTask,
                isLoading: isLoading,
              ),

              const SizedBox(height: 12),

              // Botón cancelar
              CustomButton(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final isSelected = selectedPriority == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.white : AppTheme.greyText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = selectedStatus == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => selectedStatus = value);
        }
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.lightGrey,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.darkText,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
