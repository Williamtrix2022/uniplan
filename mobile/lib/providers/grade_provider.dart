// ============================================
// PROVIDER DE CALIFICACIONES
// ============================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grade.dart';
import '../services/grade_service.dart';

class GradeProvider extends ChangeNotifier {
  static const _cacheKey = 'cached_grades';

  final GradeService _service = GradeService();

  List<Grade> _grades = [];
  GradesSummary? _summary;
  bool _isLoading = false;
  bool _isSummaryLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<Grade> get grades           => _grades;
  GradesSummary? get summary       => _summary;
  bool get isLoading               => _isLoading;
  bool get isSummaryLoading        => _isSummaryLoading;
  String? get error                => _error;
  bool get isInitialized           => _isInitialized;

  /// Calificaciones de una materia específica, ordenadas por fecha.
  List<Grade> gradesBySubject(int idMateria) {
    final list = _grades.where((g) => g.idMateria == idMateria).toList();
    list.sort((a, b) {
      final fechaA = a.fechaEvaluacion;
      final fechaB = b.fechaEvaluacion;
      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaA.compareTo(fechaB);
    });
    return list;
  }

  // ── Inicialización ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await load(useCache: true);
    await loadSummary();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Carga de datos ───────────────────────────────────────────────────────

  Future<void> load({bool useCache = false}) async {
    if (!useCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (useCache) {
        final cached = await _loadCache();
        if (cached.isNotEmpty) {
          _grades = cached;
          notifyListeners();
        }
      }

      _grades = await _service.getMyGrades();
      _error  = null;
      await _saveCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary() async {
    _isSummaryLoading = true;
    notifyListeners();

    try {
      _summary = await _service.getSummary();
      _error    = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load(useCache: false);
    await loadSummary();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> createGrade(Grade grade) async {
    final created = await _service.createGrade(grade);
    _grades.add(created);
    await _saveCache();
    notifyListeners();
    await loadSummary();
  }

  Future<void> updateGrade(int id, Grade grade) async {
    final updated = await _service.updateGrade(id, grade);
    final index = _grades.indexWhere((g) => g.id == id);
    if (index >= 0) {
      _grades[index] = updated;
      await _saveCache();
      notifyListeners();
    }
    await loadSummary();
  }

  Future<void> deleteGrade(int id) async {
    await _service.deleteGrade(id);
    _grades.removeWhere((g) => g.id == id);
    await _saveCache();
    notifyListeners();
    await loadSummary();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Caché ─────────────────────────────────────────────────────────────────

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _grades.map((g) => g.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(list));
  }

  Future<List<Grade>> _loadCache() async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((json) => Grade.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
