// ============================================
// HOME SCREEN (VERSIÓN BÁSICA TEMPORAL)
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Bienvenido a Uniplan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Cerrar sesión
              await AuthService().logout();
              
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de éxito
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 50,
                color: AppTheme.primaryGreen,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Mensaje
            const Text(
              '¡Inicio de sesión exitoso!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Bienvenido a Uniplan',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 40,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Dashboard en construcción',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Próximamente implementaremos el dashboard completo con tareas, pomodoro y calendario',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}