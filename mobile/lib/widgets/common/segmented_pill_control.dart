// ============================================
// WIDGET: SELECTOR DE PÍLDORAS SEGMENTADO REUTILIZABLE
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Selector tipo "segmented control" con píldoras, generalizado para N
/// etiquetas. Replica visualmente el patrón usado originalmente en
/// `tasks_screen.dart` (contenedor redondeado con fondo
/// [AppTheme.surfaceContainer] y píldoras seleccionables).
class SegmentedPillControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedPillControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? AppTheme.softShadow : null,
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
