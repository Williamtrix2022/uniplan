// ============================================
// PANTALLA: CENTRO DE NOTIFICACIONES
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notifications/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _tipoFilter;

  static const List<MapEntry<String?, String>> _filters = [
    MapEntry(null, 'Todas'),
    MapEntry('tarea', 'Tareas'),
    MapEntry('clase', 'Clases'),
    MapEntry('sistema', 'Sistema'),
    MapEntry('general', 'General'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final isLoading = provider.isLoading && !provider.isInitialized;
    final items = provider.notificationsByTipo(_tipoFilter);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, provider),
            _buildFilterChips(),
            if (provider.error != null) _buildErrorBanner(provider),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      color: AppTheme.primaryGreen,
                      child: items.isEmpty
                          ? _buildEmptyState()
                          : _buildList(context, provider, items),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, NotificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.darkText,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notificaciones',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ),
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(
                'Marcar todas',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = _filters[index];
          final selected = _tipoFilter == entry.key;
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => setState(() => _tipoFilter = entry.key),
            selectedColor: AppTheme.primaryGreen,
            backgroundColor: AppTheme.lightGrey,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.white : AppTheme.darkText,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(NotificationProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.error),
            ),
          ),
          GestureDetector(
            onTap: provider.clearError,
            child: const Icon(Icons.close, color: AppTheme.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: AppTheme.greyText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí verás avisos de tareas, clases y del sistema',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.greyText),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    NotificationProvider provider,
    List<AppNotification> items,
  ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notification = items[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _handleTap(context, provider, notification),
          onDelete: () => provider.delete(notification.id),
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notification,
  ) async {
    if (!notification.leida) {
      await provider.markRead(notification.id);
    }
    if (!context.mounted) return;

    // La navegación profunda a la tarea/clase referenciada queda fuera de
    // alcance de este sprint; se confirma la acción con un snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification.mensaje),
        backgroundColor: AppTheme.info,
      ),
    );
  }
}
