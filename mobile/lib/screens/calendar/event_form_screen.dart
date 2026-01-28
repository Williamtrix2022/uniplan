// ============================================
// FORMULARIO DE EVENTO (CREAR/EDITAR)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EventFormScreen extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime selectedDate;

  const EventFormScreen({
    super.key,
    this.event,
    required this.selectedDate,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CalendarService _calendarService = CalendarService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  String selectedType = 'evento';
  String selectedColor = '#2196F3';
  bool allDay = false;
  bool hasReminder = false;

  bool isLoading = false;
  bool get isEditing => widget.event != null;

  final Map<String, String> eventTypes = {
    'clase': 'Clase',
    'examen': 'Examen',
    'tarea': 'Tarea',
    'evento': 'Evento',
    'otro': 'Otro',
  };

  final Map<String, String> eventColors = {
    '#2196F3': 'Azul',
    '#4CAF50': 'Verde',
    '#F44336': 'Rojo',
    '#FF9800': 'Naranja',
    '#9C27B0': 'Morado',
    '#607D8B': 'Gris',
  };

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _titleController = TextEditingController(text: widget.event!.titulo);
      _descriptionController = TextEditingController(
        text: widget.event!.descripcion ?? '',
      );
      _locationController = TextEditingController(
        text: widget.event!.ubicacion ?? '',
      );
      selectedDate = widget.event!.fecha;
      selectedStartTime = widget.event!.horaInicio;
      selectedEndTime = widget.event!.horaFin;
      selectedType = widget.event!.tipo;
      selectedColor = widget.event!.color;
      allDay = widget.event!.todoElDia;
      hasReminder = widget.event!.recordatorio;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _locationController = TextEditingController();
      selectedDate = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (selectedStartTime ?? TimeOfDay.now())
          : (selectedEndTime ?? TimeOfDay.now()),
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
      setState(() {
        if (isStartTime) {
          selectedStartTime = picked;
        } else {
          selectedEndTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final event = CalendarEvent(
        id: isEditing ? widget.event!.id : null,
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        ubicacion: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        fecha: selectedDate,
        horaInicio: allDay ? null : selectedStartTime,
        horaFin: allDay ? null : selectedEndTime,
        tipo: selectedType,
        color: selectedColor,
        todoElDia: allDay,
        recordatorio: hasReminder,
      );

      if (isEditing) {
        await _calendarService.updateEvent(widget.event!.id!, event);
      } else {
        await _calendarService.createEvent(event);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Evento actualizado' : 'Evento creado',
            ),
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
        title: Text(isEditing ? 'Editar evento' : 'Nuevo evento'),
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
                label: 'Título del evento',
                hintText: 'Ej. Clase de Cálculo',
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
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Fecha
              const Text(
                'Fecha',
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
                        DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                            .format(selectedDate),
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

              // Todo el día
              Row(
                children: [
                  Checkbox(
                    value: allDay,
                    onChanged: (value) {
                      setState(() {
                        allDay = value ?? false;
                        if (allDay) {
                          selectedStartTime = null;
                          selectedEndTime = null;
                        }
                      });
                    },
                    activeColor: AppTheme.primaryGreen,
                  ),
                  const Text(
                    'Todo el día',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),

              // Horas (si no es todo el día)
              if (!allDay) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora inicio',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGrey,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusM),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedStartTime?.format(context) ??
                                        '--:--',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
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
                          const Text(
                            'Hora fin',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGrey,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusM),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedEndTime?.format(context) ?? '--:--',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Ubicación
              CustomTextField(
                label: 'Ubicación (opcional)',
                hintText: 'Ej. Aula 301',
                controller: _locationController,
              ),

              const SizedBox(height: 20),

              // Tipo de evento
              const Text(
                'Tipo de evento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: eventTypes.entries.map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: selectedType == entry.key,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = entry.key;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.lightGrey,
                    labelStyle: TextStyle(
                      color: selectedType == entry.key
                          ? AppTheme.white
                          : AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Color
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: eventColors.entries.map((entry) {
                  final color = Color(
                    int.parse(entry.key.substring(1), radix: 16) + 0xFF000000,
                  );
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = entry.key;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == entry.key
                            ? Border.all(
                                color: AppTheme.darkText,
                                width: 3,
                              )
                            : null,
                      ),
                      child: selectedColor == entry.key
                          ? const Icon(
                              Icons.check,
                              color: AppTheme.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Recordatorio
              Row(
                children: [
                  Checkbox(
                    value: hasReminder,
                    onChanged: (value) {
                      setState(() {
                        hasReminder = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryGreen,
                  ),
                  const Text(
                    'Recordarme 30 minutos antes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: isEditing ? 'Actualizar evento' : 'Crear evento',
                onPressed: _saveEvent,
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
}