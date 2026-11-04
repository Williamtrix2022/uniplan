// ============================================
// PANTALLA DE TAREAS - DISEÑO M3
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/user_avatar.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../grades/manage_subjects_screen.dart';
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
          filtered = filtered.where((task) => task.isCompleted).toList();
          break;
        case 'vencidas':
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          filtered = filtered.where((task) {
            if (task.isCompleted) return false;
            final due = DateTime(
              task.fechaEntrega.year,
              task.fechaEntrega.month,
              task.fechaEntrega.day,
            );
            return due.isBefore(today);
          }).toList();
          break;
        case 'en_progreso':
          filtered = filtered.where((task) {
            return !task.isCompleted && task.estado == 'en_progreso';
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

    // Orden: activas primero, después vencidas, y las completadas al final
    // — antes se mostraba tal cual el orden del backend (fecha ascendente
    // sin agrupar por estado), así que una tarea completada o vencida de
    // hace tiempo terminaba apareciendo ANTES que una tarea nueva por tener
    // una fecha de entrega más antigua. Dentro de cada grupo se sigue
    // ordenando por fecha de entrega.
    filtered.sort((a, b) {
      final groupCompare = _taskGroupWeight(a).compareTo(_taskGroupWeight(b));
      if (groupCompare != 0) return groupCompare;
      return a.fechaEntrega.compareTo(b.fechaEntrega);
    });

    _filteredTasks = filtered;
  }

  /// 0 = activa/próxima, 1 = vencida (sin completar), 2 = completada.
  int _taskGroupWeight(Task task) {
    if (task.isCompleted) return 2;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      task.fechaEntrega.year,
      task.fechaEntrega.month,
      task.fechaEntrega.day,
    );
    return due.isBefore(today) ? 1 : 0;
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
        SnackBar(
          content: const Text('Tarea eliminada'),
          backgroundColor: context.colors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  // `TaskProvider.toggleTask` es la fuente única de verdad para completar o
  // revertir una tarea (actualización optimista + reintento en el backend).
  // Esta pantalla mantiene su propia copia local para filtros/orden, así que
  // tras delegar en el provider recarga esa copia desde el backend.
  Future<void> _toggleTask(Task task) async {
    try {
      await context.read<TaskProvider>().toggleTask(task);
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
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
                    Text(
                      'Filtrar tareas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.darkText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.darkText,
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
                    _buildFilterOption(
                      'En progreso',
                      _filterEstado == 'en_progreso',
                      () {
                        setModalState(() {
                          _filterEstado = 'en_progreso';
                        });
                        setState(() {
                          _filterEstado = 'en_progreso';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Prioridad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.darkText,
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
                          backgroundColor: context.colors.surface,
                          foregroundColor: context.colors.onSurfaceVariant,
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
            color: isSelected ? context.colors.primaryContainer : context.colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? context.colors.primaryGreen : context.colors.outlineVariant,
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
                      ? context.colors.primaryGreen
                      : context.colors.onSurfaceVariant,
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: context.colors.primaryGreen, size: 18),
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
          MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
          (route) => false,
        );
        break;
    }
  }

  Color _getSideBarColor(Task task, bool isOverdue) {
    if (isOverdue) return context.colors.error;
    if (task.isCompleted) {
      return context.colors.onSurfaceVariant.withOpacity(0.4);
    }
    if (task.estado == 'en_progreso') return context.colors.info; // Azul

    return context.colors.primaryGreen; // Verde = pendiente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: context.colors.surfaceContainerHighest,
          ),
        ),
        title: Text(
          'Mis Tareas',
          style: TextStyle(
            color: context.colors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: context.colors.primaryGreen),
            onPressed: _showFilterModal,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: FutureBuilder<String>(
              future: _userNameFuture,
              builder: (context, snapshot) {
                return UserAvatar(
                  name: snapshot.data ?? '',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: context.colors.primaryGreen,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Tabs de navegación
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainer,
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
                                      ? context.colors.surface
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
                                        ? context.colors.primaryGreen
                                        : context.colors.onSurfaceVariant,
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
                                      ? context.colors.surface
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
                                        ? context.colors.primaryGreen
                                        : context.colors.onSurfaceVariant,
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
                                      ? context.colors.surface
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
                                        ? context.colors.primaryGreen
                                        : context.colors.onSurfaceVariant,
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
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: context.colors.outline,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: context.colors.outline),
                        filled: true,
                        fillColor: context.colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: context.colors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: context.colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: context.colors.primaryContainer, width: 2),
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
                              color: context.colors.onSurfaceVariant.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0
                                  ? 'No tienes tareas'
                                  : _selectedTab == 1
                                      ? 'No hay tareas esta semana'
                                      : 'No hay tareas de proyecto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colors.onSurfaceVariant,
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
                                  !task.isCompleted;
                          final sideBarColor =
                              _getSideBarColor(task, isOverdue);

                          return Dismissible(
                            key: Key(task.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: context.colors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(
                                Icons.delete,
                                color: context.colors.white,
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
                                          foregroundColor: context.colors.error),
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
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.colors.outlineVariant,
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
                                                        context.colors.errorContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'VENCIDA',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context.colors.error,
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
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2, right: 4),
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () =>
                                                      _toggleTask(task),
                                                  child: Icon(
                                                    task.isCompleted
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .radio_button_unchecked,
                                                    color: task.isCompleted
                                                        ? context.colors.primaryGreen
                                                        : AppTheme
                                                            .onSurfaceVariant,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
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
                                                        color: task.isCompleted
                                                            ? AppTheme
                                                                .onSurfaceVariant
                                                            : context.colors.darkText,
                                                        decoration:
                                                            task.isCompleted
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
                                                              ? context.colors.error
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
        backgroundColor: context.colors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        icon: Icon(Icons.add, color: context.colors.white),
        label: Text(
          'Nueva tarea',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.colors.white,
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
