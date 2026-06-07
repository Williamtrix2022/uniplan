// ============================================
// WIDGET BOTTOM NAVIGATION BAR REUTILIZABLE
// ============================================

import 'package:flutter/material.dart';
import '../config/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppTheme.surface,
      elevation: 12,
      currentIndex: currentIndex,
      onTap: onItemSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.greyText,
      selectedIconTheme: const IconThemeData(
        fill: 1.0,
      ),
      unselectedIconTheme: const IconThemeData(
        fill: 0.0,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_outlined),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_outlined),
          label: 'Perfil',
        ),
      ],
    );
  }
}
