// ============================================
// PROVIDER DE HORARIOS
// ============================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule.dart';
import '../services/schedule_service.dart';

class ScheduleProvider extends ChangeNotifier {
  static const _cacheKey = 'cached_schedules';

  final ScheduleService _service = ScheduleService();

  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Set<int> _conflictIds = {};

  // ── Getters ──────────────────────────────────────────────────────────────

  List<Schedule> get schedules    => _schedules;
  bool           get isLoading    => _isLoading;
  String?        get error        => _error;
  bool           get isInitialized => _isInitialized;
  Set<int>       get conflictIds  => _conflictIds;
  bool           get hasConflicts => _conflictIds.isNotEmpty;

  /// Horarios agrupados por día, ordenados por hora de inicio.
  /// Listo para consumir directamente desde WeekView o ScheduleGrid.
  Map<String, List<Schedule>> get schedulesByDay {
    final map = <String, List<Schedule>>{};
    for (final s in _schedules) {
      map.putIfAbsent(s.dia, () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    }
    return map;
  }

  /// Horarios de un día específico.
  List<Schedule> schedulesForDay(String dia) =>
      schedulesByDay[dia] ?? [];

  // ── Inicialización ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await loadWeekSchedule(useCache: true);

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Carga de datos ───────────────────────────────────────────────────────

  Future<void> loadWeekSchedule({bool useCache = false}) async {
    if (!useCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (useCache) {
        final cached = await _loadCache();
        if (cached.isNotEmpty) {
          _schedules = cached;
          _conflictIds = _computeConflictIds(_schedules);
          notifyListeners();
        }
      }

      _schedules   = await _service.getWeekSchedule();
      _conflictIds = _computeConflictIds(_schedules);
      _error       = null;
      await _saveCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadWeekSchedule(useCache: false);

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Crea un bloque de horario.
  /// Lanza [ScheduleConflictException] si hay superposición y force=false.
  /// La pantalla debe capturar la excepción para mostrar el diálogo.
  Future<void> createSchedule(Schedule schedule, {bool force = false}) async {
    final created = await _service.createSchedule(schedule, force: force);
    _schedules.add(created);
    _conflictIds = _computeConflictIds(_schedules);
    await _saveCache();
    notifyListeners();
  }

  /// Actualiza un bloque de horario.
  /// Lanza [ScheduleConflictException] si hay superposición y force=false.
  Future<void> updateSchedule(
    int id,
    Schedule schedule, {
    bool force = false,
  }) async {
    final updated = await _service.updateSchedule(id, schedule, force: force);
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _schedules[index] = updated;
      _conflictIds = _computeConflictIds(_schedules);
      await _saveCache();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(int id) async {
    await _service.deleteSchedule(id);
    _schedules.removeWhere((s) => s.id == id);
    _conflictIds = _computeConflictIds(_schedules);
    await _saveCache();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Detección de conflictos (lado cliente) ───────────────────────────────
  //
  // Dos bloques se superponen si comparten el mismo día y sus intervalos
  // de tiempo se cruzan: inicio_A < fin_B AND fin_A > inicio_B.
  // La comparación de strings "HH:MM:SS" funciona correctamente porque
  // el formato tiene longitud fija y orden lexicográfico = orden temporal.

  Set<int> _computeConflictIds(List<Schedule> schedules) {
    final conflicts = <int>{};
    for (int i = 0; i < schedules.length; i++) {
      for (int j = i + 1; j < schedules.length; j++) {
        final a = schedules[i];
        final b = schedules[j];
        if (a.dia == b.dia &&
            a.horaInicio.compareTo(b.horaFin) < 0 &&
            a.horaFin.compareTo(b.horaInicio) > 0) {
          conflicts.add(a.id);
          conflicts.add(b.id);
        }
      }
    }
    return conflicts;
  }

  // ── Caché ─────────────────────────────────────────────────────────────────

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _schedules.map((s) => s.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(list));
  }

  Future<List<Schedule>> _loadCache() async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((json) => Schedule.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
