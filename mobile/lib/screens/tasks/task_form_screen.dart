// ============================================
// FORMULARIO DE TAREA (CREAR/EDITAR)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
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
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedPriority = 'media';
  String selectedStatus = 'pendiente';
  
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
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
    }
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
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        fechaEntrega: dateTime,
        prioridad: selectedPriority,
        estado: selectedStatus,
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