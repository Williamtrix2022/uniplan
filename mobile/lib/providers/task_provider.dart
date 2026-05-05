import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../services/subject_service.dart';
import '../services/task_service.dart';

enum TaskSortOption {
  dueDateAsc,
  dueDateDesc,
  priorityHigh,
  priorityLow,
  titleAsc,
}

class TaskProvider extends ChangeNotifier {
  static const _cacheKey = 'cached_tasks';

  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();

  List<Task> _tasks = [];
  List<Subject> _subjects = [];

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  String _searchQuery = '';
  String? _statusFilter;
  String? _priorityFilter;
  int? _subjectFilter;
  bool? _projectFilter;
  TaskSortOption _sortOption = TaskSortOption.dueDateAsc;

  List<Task> get tasks => _tasks;
  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  int? get subjectFilter => _subjectFilter;
  bool? get projectFilter => _projectFilter;
  TaskSortOption get sortOption => _sortOption;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadSubjects(),
      loadTasks(useCache: true),
    ]);

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSubjects() async {
    try {
      _subjects = await _subjectService.getSubjects();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadTasks({bool useCache = false}) async {
    if (!useCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (useCache) {
        final cachedTasks = await _loadCachedTasks();
        if (cachedTasks.isNotEmpty) {
          _tasks = cachedTasks;
          notifyListeners();
        }
      }

      _tasks = await _taskService.getTasks();
      _error = null;
      await _saveCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadTasks(useCache: false);
  }

  Future<void> createTask(Task task) async {
    final created = await _taskService.createTask(task);
    _tasks.add(created);
    await _saveCache();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final updated = await _taskService.updateTask(task.id, task);
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index >= 0) {
      _tasks[index] = updated;
      await _saveCache();
      notifyListeners();
    }
  }

  Future<void> deleteTask(int taskId) async {
    await _taskService.deleteTask(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveCache();
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    final targetCompleted = !task.completada;
    final optimistic = task.copyWith(
      completada: targetCompleted,
      estado: targetCompleted ? 'completada' : 'pendiente',
    );

    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;

    _tasks[index] = optimistic;
    notifyListeners();

    try {
      final updated = await _taskService.toggleTaskComplete(
        task.id,
        completada: targetCompleted,
      );
      _tasks[index] = updated;
      _error = null;
      await _saveCache();
    } catch (e) {
      _tasks[index] = task;
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setPriorityFilter(String? value) {
    _priorityFilter = value;
    notifyListeners();
  }

  void setSubjectFilter(int? value) {
    _subjectFilter = value;
    notifyListeners();
  }

  void setProjectFilter(bool? value) {
    _projectFilter = value;
    notifyListeners();
  }

  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _subjectFilter = null;
    _projectFilter = null;
    _searchQuery = '';
    _sortOption = TaskSortOption.dueDateAsc;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    var result = List<Task>.from(_tasks);

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      result = result.where((task) => task.estado == _statusFilter).toList();
    }

    if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
      result = result.where((task) => task.prioridad == _priorityFilter).toList();
    }

    if (_subjectFilter != null) {
      result = result.where((task) => task.idMateria == _subjectFilter).toList();
    }

    if (_projectFilter != null) {
      result = result.where((task) => task.esProyecto == _projectFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((task) {
        final title = task.titulo.toLowerCase();
        final description = (task.descripcion ?? '').toLowerCase();
        final subject = (task.materiaNombre ?? '').toLowerCase();
        return title.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            subject.contains(_searchQuery);
      }).toList();
    }

    result.sort(_sortComparator);
    return result;
  }

  Map<String, int> get stats {
    final total = _tasks.length;
    final completed = _tasks.where((task) => task.completada).length;
    final pending = _tasks.where((task) => !task.completada).length;
    final highPriority = _tasks.where((task) => task.prioridad == 'alta').length;

    return {
      'total': total,
      'completadas': completed,
      'pendientes': pending,
      'alta_prioridad': highPriority,
    };
  }

  int _sortComparator(Task a, Task b) {
    switch (_sortOption) {
      case TaskSortOption.dueDateAsc:
        return a.fechaEntrega.compareTo(b.fechaEntrega);
      case TaskSortOption.dueDateDesc:
        return b.fechaEntrega.compareTo(a.fechaEntrega);
      case TaskSortOption.priorityHigh:
        return _priorityWeight(b.prioridad).compareTo(_priorityWeight(a.prioridad));
      case TaskSortOption.priorityLow:
        return _priorityWeight(a.prioridad).compareTo(_priorityWeight(b.prioridad));
      case TaskSortOption.titleAsc:
        return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    }
  }

  int _priorityWeight(String priority) {
    switch (priority) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baja':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = _tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(taskList));
  }

  Future<List<Task>> _loadCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
