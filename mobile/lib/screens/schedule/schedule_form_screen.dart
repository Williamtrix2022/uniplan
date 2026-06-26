// ============================================
// PANTALLA FORMULARIO DE CLASE
// Stub — implementación completa en T11
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/schedule.dart';

class ScheduleFormScreen extends StatelessWidget {
  /// null = crear nuevo bloque; non-null = editar existente
  final Schedule? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  Widget build(BuildContext context) {
    final isEditing = schedule != null;
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar clase' : 'Nueva clase'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
