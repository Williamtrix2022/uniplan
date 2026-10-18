// ============================================
// PROVIDER DE MATERIAS
// ============================================

import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';

class SubjectProvider extends ChangeNotifier {
  final SubjectService _service = SubjectService();

  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await refresh();
    _isInitialized = true;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final subjects = await _service.getSubjects();
      _subjects = subjects..sort((a, b) => a.nombre.compareTo(b.nombre));
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Subject> createSubject({
    required String nombre,
    String? codigo,
    String? profesor,
    int? semestre,
    int? creditos,
    String? horario,
    String? color,
  }) async {
    final created = await _service.createSubject(
      nombre: nombre,
      codigo: codigo,
      profesor: profesor,
      semestre: semestre,
      creditos: creditos,
      horario: horario,
      color: color,
    );
    _subjects = [..._subjects, created]
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();
    return created;
  }

  Future<void> deleteSubject(int subjectId) async {
    await _service.deleteSubject(subjectId);
    _subjects = _subjects.where((s) => s.id != subjectId).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
