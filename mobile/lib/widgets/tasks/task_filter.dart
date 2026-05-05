import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/subject.dart';
import '../../providers/task_provider.dart';

class TaskFilter extends StatelessWidget {
  final String? status;
  final String? priority;
  final int? subjectId;
  final bool? projectFilter;
  final TaskSortOption sortOption;
  final List<Subject> subjects;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<bool?> onProjectFilterChanged;
  final ValueChanged<TaskSortOption> onSortChanged;
  final VoidCallback onClear;

  const TaskFilter({
    super.key,
    required this.status,
    required this.priority,
    required this.subjectId,
    required this.projectFilter,
    required this.sortOption,
    required this.subjects,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSubjectChanged,
    required this.onProjectFilterChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros de tareas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              DropdownMenuItem<String?>(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem<String?>(value: 'en_progreso', child: Text('En progreso')),
              DropdownMenuItem<String?>(value: 'completada', child: Text('Completada')),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: priority,
            decoration: const InputDecoration(
              labelText: 'Prioridad',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todas')),
              DropdownMenuItem<String?>(value: 'alta', child: Text('Alta')),
              DropdownMenuItem<String?>(value: 'media', child: Text('Media')),
              DropdownMenuItem<String?>(value: 'baja', child: Text('Baja')),
            ],
            onChanged: onPriorityChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: subjectId,
            decoration: const InputDecoration(
              labelText: 'Materia',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
              ...subjects.map(
                (subject) => DropdownMenuItem<int?>(
                  value: subject.id,
                  child: Text(subject.nombre),
                ),
              ),
            ],
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool?>(
            initialValue: projectFilter,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('Todas')),
              DropdownMenuItem<bool?>(value: true, child: Text('Solo proyectos')),
              DropdownMenuItem<bool?>(value: false, child: Text('Solo no proyectos')),
            ],
            onChanged: onProjectFilterChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskSortOption>(
            initialValue: sortOption,
            decoration: const InputDecoration(
              labelText: 'Orden',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: TaskSortOption.dueDateAsc,
                child: Text('Fecha (próxima primero)'),
              ),
              DropdownMenuItem(
                value: TaskSortOption.dueDateDesc,
                child: Text('Fecha (lejana primero)'),
              ),
              DropdownMenuItem(
                value: TaskSortOption.priorityHigh,
                child: Text('Prioridad (alta a baja)'),
              ),
              DropdownMenuItem(
                value: TaskSortOption.priorityLow,
                child: Text('Prioridad (baja a alta)'),
              ),
              DropdownMenuItem(
                value: TaskSortOption.titleAsc,
                child: Text('Título (A-Z)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
