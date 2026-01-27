// ============================================
// PANTALLA DE TAREAS
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  
  List<Task> allTasks = [];
  List<Task> todayTasks = [];
  List<Task> weekTasks = [];
  List<Task> upcomingTasks = [];
  List<Task> projectTasks = [];
  
  bool isLoading = true;
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);

    try {
      final tasks = await _taskService.getTasks();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekEnd = today.add(const Duration(days: 7));

      setState(() {
        allTasks = tasks;
        
        // Filtrar tareas de hoy
        todayTasks = tasks.where((task) {
          final taskDate = DateTime(
            task.fechaEntrega.year,
            task.fechaEntrega.month,
            task.fechaEntrega.day,
          );
          return taskDate.isAtSameMomentAs(today) && !task.completada;
        }).toList();

        // Filtrar tareas de la semana
        weekTasks = tasks.where((task) {
          final taskDate = DateTime(
            task.fechaEntrega.year,
            task.fechaEntrega.month,
            task.fechaEntrega.day,
          );
          return taskDate.isAfter(today) &&
                 taskDate.isBefore(weekEnd) &&
                 !task.completada;
        }).toList();

        // Filtrar tareas próximas (después de una semana)
        upcomingTasks = tasks.where((task) {
          final taskDate = DateTime(
            task.fechaEntrega.year,
            task.fechaEntrega.month,
            task.fechaEntrega.day,
          );
          return taskDate.isAfter(weekEnd) && !task.completada;
        }).toList();

        // Tareas tipo proyecto o de alta prioridad
        projectTasks = tasks.where((task) {
          return task.prioridad == 'alta' && !task.completada;
        }).toList();
      });
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    try {
      await _taskService.completeTask(task.id);
      _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea completada'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
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
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro de eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(task.id);
        _loadTasks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarea eliminada'),
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
      }
    }
  }

  void _openTaskForm({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Mostrar filtros
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Hoy'),
            Tab(text: 'Semana'),
            Tab(text: 'Próximamente'),
            Tab(text: 'Proyectos'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: AppTheme.primaryGreen,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(todayTasks, 'No tienes tareas para hoy'),
                  _buildTaskList(weekTasks, 'No hay tareas esta semana'),
                  _buildTaskList(upcomingTasks, 'No hay tareas próximas'),
                  _buildTaskList(projectTasks, 'No hay proyectos activos'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Nueva tarea',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: AppTheme.greyText.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(tasks[index]);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = Color(
      int.parse(task.getPriorityColor().substring(1), radix: 16) + 0xFF000000,
    );
    
    final isOverdue = task.fechaEntrega.isBefore(DateTime.now()) && !task.completada;

    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: AppTheme.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: const Text('¿Estás seguro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteTask(task);
      },
      child: GestureDetector(
        onTap: () => _openTaskForm(task: task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: isOverdue ? AppTheme.error.withOpacity(0.3) : AppTheme.borderGrey,
              width: isOverdue ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleTaskComplete(task),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.completada 
                          ? AppTheme.primaryGreen 
                          : priorityColor,
                      width: 2,
                    ),
                    color: task.completada 
                        ? AppTheme.primaryGreen 
                        : Colors.transparent,
                  ),
                  child: task.completada
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.white,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Barra de prioridad
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Info de la tarea
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.completada 
                            ? AppTheme.greyText 
                            : AppTheme.darkText,
                        decoration: task.completada 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    
                    if (task.descripcion != null && task.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        if (task.materiaNombre != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.materiaNombre!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isOverdue ? AppTheme.error : AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM', 'es_ES').format(task.fechaEntrega),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? AppTheme.error : AppTheme.greyText,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Vencida',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menú de opciones
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.greyText,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _openTaskForm(task: task);
                  } else if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}