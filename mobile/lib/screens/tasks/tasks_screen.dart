// ============================================
// PANTALLA DE TAREAS
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/tasks/task_filter.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleTaskComplete(Task task) async {
    final provider = context.read<TaskProvider>();
    try {
      await provider.toggleTask(task);
      if (!mounted) return;
      final completed = !task.completada;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(completed ? 'Tarea completada' : 'Tarea marcada pendiente'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
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

    if (confirmed != true) return;
    if (!mounted) return;

    final provider = context.read<TaskProvider>();
    try {
      await provider.deleteTask(task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea eliminada'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true && mounted) {
      await context.read<TaskProvider>().refresh();
    }
  }

  void _showFilterBottomSheet(TaskProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      builder: (context) {
        return TaskFilter(
          status: provider.statusFilter,
          priority: provider.priorityFilter,
          subjectId: provider.subjectFilter,
          sortOption: provider.sortOption,
          subjects: provider.subjects,
          onStatusChanged: provider.setStatusFilter,
          onPriorityChanged: provider.setPriorityFilter,
          onSubjectChanged: provider.setSubjectFilter,
          onSortChanged: provider.setSortOption,
          onClear: () {
            provider.clearFilters();
            _searchController.clear();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  List<Task> _tasksByTab(List<Task> tasks, int tabIndex) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    DateTime normalize(DateTime date) => DateTime(date.year, date.month, date.day);

    switch (tabIndex) {
      case 0:
        return tasks;
      case 1:
        return tasks.where((task) {
          final due = normalize(task.fechaEntrega);
          return !due.isBefore(tomorrow) && !due.isAfter(weekEnd);
        }).toList();
      case 2:
        return tasks.where((task) => task.esProyecto).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final filteredTasks = provider.filteredTasks;
        final todayTasks = _tasksByTab(filteredTasks, 0);
        final weekTasks = _tasksByTab(filteredTasks, 1);
        final projectTasks = _tasksByTab(filteredTasks, 2);

        return Scaffold(
          backgroundColor: AppTheme.white,
          appBar: AppBar(
            title: const Text('Mis Tareas'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterBottomSheet(provider),
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
                Tab(text: 'Todas'),
                Tab(text: 'Semana'),
                Tab(text: 'Proyecto'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar por título, descripción o materia',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    filled: true,
                    fillColor: AppTheme.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading && provider.tasks.isEmpty
                    ? _buildSkeletonList()
                    : RefreshIndicator(
                        onRefresh: provider.refresh,
                        color: AppTheme.primaryGreen,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTaskList(
                              todayTasks,
                              'No tienes tareas',
                            ),
                            _buildTaskList(
                              weekTasks,
                              'No hay tareas esta semana',
                            ),
                            _buildTaskList(
                              projectTasks,
                              'No hay tareas de proyecto o alta prioridad',
                            ),
                          ],
                        ),
                      ),
              ),
            ],
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
      },
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

    final listKey = ValueKey(
      '${_tabController.index}-${tasks.length}-${_searchController.text}',
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: ListView.builder(
        key: listKey,
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 180 + (index * 25)),
            tween: Tween(begin: 0.95, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: value, child: child),
            ),
            child: _buildTaskCard(task),
          );
        },
      ),
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
      onDismissed: (direction) => _deleteTask(task),
      child: GestureDetector(
        onTap: () => _openTaskForm(task: task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
              GestureDetector(
                onTap: () => _toggleTaskComplete(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.completada ? AppTheme.primaryGreen : priorityColor,
                      width: 2,
                    ),
                    color: task.completada ? AppTheme.primaryGreen : Colors.transparent,
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
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.completada ? AppTheme.greyText : AppTheme.darkText,
                        decoration:
                            task.completada ? TextDecoration.lineThrough : null,
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
                          Flexible(
                            child: Container(
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
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
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
                        Flexible(
                          child: Text(
                            DateFormat('dd MMM', 'es_ES').format(task.fechaEntrega),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? AppTheme.error : AppTheme.greyText,
                              fontWeight:
                                  isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.borderGrey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 180,
                    color: AppTheme.borderGrey,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 140,
                    color: AppTheme.borderGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
