// ============================================
// WIDGET DE NAVEGACIÓN PRINCIPAL
// ============================================

import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/profile/profile_screen.dart';

class MainNavigationBar extends StatelessWidget {
  final int currentIndex;

  const MainNavigationBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const TasksScreen();
        break;
      case 2:
        nextScreen = const CalendarScreen();
        break;
      case 3:
        nextScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                colorScheme,
                textTheme,
                icon: Icons.dashboard,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
              _buildBottomNavItem(
                colorScheme,
                textTheme,
                icon: Icons.assignment,
                label: 'Tasks',
                isActive: currentIndex == 1,
                onTap: () => _onTap(context, 1),
              ),
              _buildBottomNavItem(
                colorScheme,
                textTheme,
                icon: Icons.calendar_month,
                label: 'Calendar',
                isActive: currentIndex == 2,
                onTap: () => _onTap(context, 2),
              ),
              _buildBottomNavItem(
                colorScheme,
                textTheme,
                icon: Icons.person,
                label: 'Perfil',
                isActive: currentIndex == 3,
                onTap: () => _onTap(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Alias para mantener compatibilidad con el nombre usado antes
  Widget _buildNavItem(ColorScheme colorScheme, TextTheme textTheme,
      {required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return _buildBottomNavItem(colorScheme, textTheme,
        icon: icon, label: label, isActive: isActive, onTap: onTap);
  }

  Widget _buildBottomNavItem(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fill: isActive ? 1.0 : 0.0,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
