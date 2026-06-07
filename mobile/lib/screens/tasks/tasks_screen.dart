// ============================================
// PANTALLA DE TAREAS - DISEÑO M3
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  int _selectedIndex = 1;
  String _searchQuery = '';
  String _filterEstado = 'todos';
  String _filterPrioridad = 'todas';
  late final Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _authService.getUserName();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Task> filtered = _tasks;

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.titulo.toLowerCase().contains(_searchQuery) ||
            (task.descripcion?.toLowerCase().contains(_searchQuery) ?? false) ||
            (task.materiaNombre?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Filtro por estado
    if (_filterEstado != 'todos') {
      switch (_filterEstado) {
        case 'completadas':
          filtered = filtered.where((task) {
            return task.completada || task.estado == 'completada';
          }).toList();
          break;
        case 'vencidas':
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          filtered = filtered.where((task) {
            if (task.completada || task.estado == 'completada') return false;
            final due = DateTime(
              task.fechaEntrega.year,
              task.fechaEntrega.month,
              task.fechaEntrega.day,
            );
            return due.isBefore(today);
          }).toList();
          break;
      }
    }

    // Filtro por prioridad
    if (_filterPrioridad != 'todas') {
      filtered = filtered
          .where((task) => task.prioridad.toLowerCase() == _filterPrioridad)
          .toList();
    }

    // Filtro por pestaña
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    switch (_selectedTab) {
      case 0:
        break;
      case 1:
        filtered = filtered.where((task) {
          final due = DateTime(
            task.fechaEntrega.year,
            task.fechaEntrega.month,
            task.fechaEntrega.day,
          );
          return !due.isBefore(tomorrow) && !due.isAfter(weekEnd);
        }).toList();
        break;
      case 2:
        filtered = filtered.where((task) => task.esProyecto).toList();
        break;
    }

    _filteredTasks = filtered;
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tasks = await _taskService.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea eliminada'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrar tareas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      'Todas',
                      _filterEstado == 'todos',
                      () {
                        setModalState(() {
                          _filterEstado = 'todos';
                        });
                        setState(() {
                          _filterEstado = 'todos';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      'Completadas',
                      _filterEstado == 'completadas',
                      () {
                        setModalState(() {
                          _filterEstado = 'completadas';
                        });
                        setState(() {
                          _filterEstado = 'completadas';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      'Vencidas',
                      _filterEstado == 'vencidas',
                      () {
                        setModalState(() {
                          _filterEstado = 'vencidas';
                        });
                        setState(() {
                          _filterEstado = 'vencidas';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Prioridad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      'Todas Prioridad',
                      _filterPrioridad == 'todas',
                      () {
                        setModalState(() {
                          _filterPrioridad = 'todas';
                        });
                        setState(() {
                          _filterPrioridad = 'todas';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      'Alta',
                      _filterPrioridad == 'alta',
                      () {
                        setModalState(() {
                          _filterPrioridad = 'alta';
                        });
                        setState(() {
                          _filterPrioridad = 'alta';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      'Media',
                      _filterPrioridad == 'media',
                      () {
                        setModalState(() {
                          _filterPrioridad = 'media';
                        });
                        setState(() {
                          _filterPrioridad = 'media';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      'Baja',
                      _filterPrioridad == 'baja',
                      () {
                        setModalState(() {
                          _filterPrioridad = 'baja';
                        });
                        setState(() {
                          _filterPrioridad = 'baja';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            _filterEstado = 'todos';
                            _filterPrioridad = 'todas';
                          });
                          setState(() {
                            _filterEstado = 'todos';
                            _filterPrioridad = 'todas';
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          foregroundColor: AppTheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Limpiar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryContainer : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryGreen : AppTheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.onSurfaceVariant,
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: AppTheme.primaryGreen, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );
    if (result == true) {
      await _loadTasks();
    }
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
        break;
    }
  }

  Color _getSideBarColor(Task task, bool isOverdue) {
    if (isOverdue) return AppTheme.error;
    if (task.completada || task.estado == 'completada') {
      return AppTheme.onSurfaceVariant.withOpacity(0.4);
    }
    if (task.estado == 'en_progreso') return AppTheme.info; // Azul

    return AppTheme.primaryGreen; // Verde = pendiente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.surfaceContainerHighest,
          ),
        ),
        title: Row(
          children: [
            FutureBuilder<String>(
              future: _userNameFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.shrink(),
                  );
                }
                final name = snapshot.data!;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Mis Tareas',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryGreen),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Tabs de navegación
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                  _applyFilters();
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? AppTheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedTab == 0
                                      ? AppTheme.softShadow
                                      : null,
                                ),
                                child: Text(
                                  'Todas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? AppTheme.primaryGreen
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                  _applyFilters();
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? AppTheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedTab == 1
                                      ? AppTheme.softShadow
                                      : null,
                                ),
                                child: Text(
                                  'Semana',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 1
                                        ? AppTheme.primaryGreen
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 2;
                                  _applyFilters();
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 2
                                      ? AppTheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedTab == 2
                                      ? AppTheme.softShadow
                                      : null,
                                ),
                                child: Text(
                                  'Proyecto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 2
                                        ? AppTheme.primaryGreen
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Barra de búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por título, descripción o materia...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: AppTheme.outline),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryContainer, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 24),

                    // Lista de tareas
                    if (_filteredTasks.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 80,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0
                                  ? 'No tienes tareas'
                                  : _selectedTab == 1
                                      ? 'No hay tareas esta semana'
                                      : 'No hay tareas de proyecto',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _filteredTasks.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          final isOverdue =
                              task.fechaEntrega.isBefore(
                                    DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                    )) &&
                                  !task.completada;
                          final sideBarColor =
                              _getSideBarColor(task, isOverdue);

                          return Dismissible(
                            key: Key(task.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(12),
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.error),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) => _deleteTask(task),
                            child: GestureDetector(
                              onTap: () => _openTaskForm(task: task),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant,
                                    width: 1,
                                  ),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Stack(
                                  children: [
                                    // Barra lateral izquierda
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: sideBarColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Contenido
                                    Padding(
                                      padding: const EdgeInsets.all(16)
                                          .copyWith(left: 24),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Status badge (solo si vencida)
                                              if (isOverdue) ...[
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.errorContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: const Text(
                                                    'VENCIDA',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppTheme.error,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              // Materia
                                              Expanded(
                                                child: Text(
                                                  task.materiaNombre ??
                                                      'Sin materia',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      task.titulo,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: task.completada
                                                            ? AppTheme
                                                                .onSurfaceVariant
                                                            : AppTheme.darkText,
                                                        decoration:
                                                            task.completada
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null,
                                                      ),
                                                    ),
                                                    if (task.descripcion !=
                                                            null &&
                                                        task.descripcion!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        task.descripcion!,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 18,
                                                          color: isOverdue
                                                              ? AppTheme.error
                                                              : AppTheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            DateFormat('dd MMM',
                                                                    'es_ES')
                                                                .format(task
                                                                    .fechaEntrega),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isOverdue
                                                                  ? AppTheme
                                                                      .error
                                                                  : AppTheme
                                                                      .onSurfaceVariant,
                                                              fontWeight: isOverdue
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: AppTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Nueva tarea',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
