// ============================================
// PANTALLA DE PERFIL - DISEÑO M3 ACTUALIZADO
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/common/user_avatar.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'pomodoro_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../legal/terms_screen.dart';
import 'help_screen.dart';
import 'theme_settings_screen.dart';

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
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
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
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: context.colors.surfaceContainerHighest,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            UserAvatar(name: _userName, size: 40),
            const SizedBox(width: 12),
            // Título "Agenda"
            Text(
              'Agenda',
              style: TextStyle(
                color: context.colors.primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: context.colors.darkText),
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
              color: context.colors.primaryGreen,
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
              UserAvatar(
                name: nombre,
                size: 96,
                fallbackInitial: 'U',
                borderColor: context.colors.surface,
                borderWidth: 4,
                boxShadow: AppTheme.cardShadow,
              ),
              // Badge verified
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.colors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
                child: Icon(
                  Icons.verified,
                  size: 18,
                  color: context.colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nombre
          Text(
            nombre,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            correo,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Chip de carrera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Text(
              carrera,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.colors.darkText,
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: context.colors.onSurfaceVariant,
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
    final totalSesiones = pomodoro['sesiones_completadas'] ?? 0;
    final minutosEstudiados = pomodoro['total_minutos'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt,
            value: '$completadas/$totalTareas',
            label: 'Tareas',
            color: context.colors.primaryFixed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            value: '$totalSesiones',
            label: 'Pomodoros',
            color: context.colors.tertiaryFixed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '${minutosEstudiados}m',
            label: 'Estudiados',
            color: context.colors.secondaryFixed,
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
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
            child: Icon(icon, size: 20, color: context.colors.darkText),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.colors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.timer,
            iconColor: context.colors.primaryGreen,
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
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: context.colors.primaryGreen,
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
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            iconColor: context.colors.primaryGreen,
            title: 'Notificaciones',
            subtitle: 'Gestiona tus notificaciones',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.palette_outlined,
            iconColor: context.colors.primaryGreen,
            title: 'Temas',
            subtitle: 'Personaliza la apariencia',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.help_outline,
            iconColor: context.colors.primaryGreen,
            title: 'Ayuda',
            subtitle: 'Preguntas frecuentes y soporte',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
          ),
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.description_outlined,
            iconColor: context.colors.primaryGreen,
            title: 'Términos y condiciones',
            subtitle: 'Política de datos y uso del servicio',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              );
            },
          ),
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
          _buildMenuItem(
            icon: Icons.info_outline,
            iconColor: context.colors.primaryGreen,
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
                  const Text(
                    'Desarrollado por Jhon Quiceno',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          Divider(height: 1, color: context.colors.surfaceContainerHighest),
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
                      color: context.colors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: context.colors.error,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.onSurfaceVariant,
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
                color: context.colors.surfaceContainer,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
