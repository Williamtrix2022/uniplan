// ============================================
// SELECTOR DE TEMA (CLARO / OSCURO / SISTEMA)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: AppBar(title: const Text('Temas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elige cómo quieres que se vea Uniplan.',
                style: TextStyle(fontSize: 14, color: context.colors.greyText),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.light_mode_outlined,
                title: 'Claro',
                selected: themeProvider.themeMode == ThemeMode.light,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              _ThemeOption(
                icon: Icons.dark_mode_outlined,
                title: 'Oscuro',
                selected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
              _ThemeOption(
                icon: Icons.brightness_auto_outlined,
                title: 'Según el sistema',
                selected: themeProvider.themeMode == ThemeMode.system,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? context.colors.primaryGreen : context.colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: context.colors.primaryGreen),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colors.darkText,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: context.colors.primaryGreen)
            : null,
        onTap: onTap,
      ),
    );
  }
}
