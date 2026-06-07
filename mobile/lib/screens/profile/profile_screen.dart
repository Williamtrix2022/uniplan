// ============================================
// PANTALLA DE PERFIL - DISEÑO M3 ACTUALIZADO
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'pomodoro_settings_screen.dart';
import '../home/home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../calendar/calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic> profileData = {};
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  int _selectedIndex = 3;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      final profile = await _authService.getProfile();
      final dashboard = await _dashboardService.getDashboard();

      setState(() {
        profileData = profile['data'] ?? {};
        stats = dashboard;
        _userName = profileData['nombre'] ?? '';
      });
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TasksScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
          (route) => false,
        );
        break;
      case 3:
        // Ya estamos en Profile, solo refrescar datos
        _loadProfileData();
        break;
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.surfaceContainerHighest,
          ),
        ),
        title: Row(
          children: [
            // Avatar circular 40x40 con inicial
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _userName.isNotEmpty
                    ? Text(
                        _userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
            // Título "Agenda"
            const Text(
              'Agenda',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.darkText),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) => _loadProfileData());
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Tarjeta de identidad
                    _buildIdentityCard(),

                    const SizedBox(height: 32),

                    // Sección Estadísticas
                    _buildSectionLabel('ESTADÍSTICAS'),
                    const SizedBox(height: 16),
                    _buildStats(),

                    const SizedBox(height: 32),

                    // Sección Configuración
                    _buildSectionLabel('CONFIGURACIÓN'),
                    const SizedBox(height: 16),
                    _buildSettingsSection(),

                    const SizedBox(height: 32),
                    _buildOtherOptions(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  Widget _buildIdentityCard() {
    final nombre = profileData['nombre'] ?? 'Usuario';
    final correo = profileData['correo'] ?? '';
    final carrera = profileData['carrera'] ?? 'Sin carrera';

    return Center(
      child: Column(
        children: [
          // Avatar con badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 4),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
              ),
              // Badge verified
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child: const Icon(
                  Icons.verified,
                  size: 18,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nombre
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            correo,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Chip de carrera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Text(
              carrera,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStats() {
    final resumen = stats['resumen'] ?? {};
    final tareas = resumen['tareas'] ?? {};
    final pomodoro = stats['pomodoro']?['semana'] ?? {};

    final totalTareas = tareas['total_tareas'] ?? 0;
    final completadas = tareas['completadas'] ?? 0;
    final totalSesiones = pomodoro['total_sesiones'] ?? 0;
    final minutosEstudiados = pomodoro['total_minutos'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt,
            value: '$completadas/$totalTareas',
            label: 'Tareas',
            color: AppTheme.primaryFixed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            value: '$totalSesiones',
            label: 'Pomodoros',
            color: AppTheme.tertiaryFixed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '${minutosEstudiados}m',
            label: 'Estudiados',
            color: AppTheme.secondaryFixed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.darkText),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.timer,
            iconColor: AppTheme.primaryGreen,
            title: 'Pomodoro Config',
            subtitle: 'Ajusta tiempos de trabajo y descanso',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PomodoroSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: AppTheme.primaryGreen,
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu contraseña desde tu perfil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            iconColor: AppTheme.primaryGreen,
            title: 'Notificaciones',
            subtitle: 'Gestiona tus notificaciones',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximamente'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.palette_outlined,
            iconColor: AppTheme.primaryGreen,
            title: 'Temas',
            subtitle: 'Personaliza la apariencia',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximamente'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.help_outline,
            iconColor: AppTheme.primaryGreen,
            title: 'Ayuda',
            subtitle: 'Preguntas frecuentes y soporte',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximamente'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.info_outline,
            iconColor: AppTheme.primaryGreen,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Uniplan',
                applicationVersion: '1.0.0',
                children: [
                  const Text(
                    'Aplicación para organización académica universitaria.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Desarrollado por William Moya Santana',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          // Cerrar sesión
          InkWell(
            onTap: _logout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: AppTheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cerrar sesión',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
