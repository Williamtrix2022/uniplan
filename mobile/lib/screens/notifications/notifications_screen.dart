// ============================================
// PANTALLA: CENTRO DE NOTIFICACIONES
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/calendar_service.dart';
import '../../services/schedule_service.dart';
import '../../services/task_service.dart';
import '../../widgets/notifications/notification_card.dart';
import '../calendar/event_form_screen.dart';
import '../schedule/class_detail_screen.dart';
import '../tasks/task_form_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TaskService _taskService = TaskService();
  final ScheduleService _scheduleService = ScheduleService();
  final CalendarService _calendarService = CalendarService();

  String? _tipoFilter;

  static const List<MapEntry<String?, String>> _filters = [
    MapEntry(null, 'Todas'),
    MapEntry('tarea', 'Tareas'),
    MapEntry('clase', 'Clases'),
    MapEntry('evento', 'Eventos'),
    MapEntry('otros', 'Otros'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // `initialize()` es un no-op después de la primera vez que corre en
      // toda la sesión (normalmente disparado desde Home) — sin el
      // `refresh()` de acá, reabrir esta pantalla mostraba lo que había en
      // memoria en ESE momento, no lo que el backend tiene ahora. Eso
      // explicaba el bug reportado: entrabas a Notificaciones apenas
      // abierta la app (antes de que `rescheduleAll` de Home terminara de
      // crear/actualizar recordatorios) y veías la lista vacía o
      // incompleta, aunque la campanita ya mostraba el contador correcto;
      // recién se veía bien al volver a entrar más tarde.
      final provider = context.read<NotificationProvider>();
      await provider.initialize();
      if (!mounted) return;
      await provider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final isLoading = provider.isLoading && !provider.isInitialized;
    final items = provider.notificationsByFilterGroup(_tipoFilter);

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

  /// Al tocar una notificación de `'tarea'`, `'clase'` o `'evento'`, navega
  /// directo a la entidad referenciada y la saca del feed — ya cumplió su
  /// función (avisar) y quedó vista, no tiene sentido que siga ocupando
  /// lugar en la lista. Las de tipo `'sistema'`/`'general'` no tienen una
  /// entidad a la que navegar, así que mantienen el comportamiento
  /// anterior: se marcan como leídas y se confirma con un snackbar.
  Future<void> _handleTap(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notification,
  ) async {
    final referenciaId = notification.referenciaId;
    final isTarea = notification.tipo == 'tarea' && referenciaId != null;
    final isClase = notification.tipo == 'clase' && referenciaId != null;
    final isEvento = notification.tipo == 'evento' && referenciaId != null;

    if (!isTarea && !isClase && !isEvento) {
      if (!notification.leida) {
        await provider.markRead(notification.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification.mensaje),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    try {
      if (isTarea) {
        final task = await _taskService.getTaskById(referenciaId);
        if (!context.mounted) return;
        if (task == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esa tarea ya no existe'),
              backgroundColor: AppTheme.error,
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
          );
        }
      } else if (isClase) {
        final schedule = await _scheduleService.getScheduleById(referenciaId);
        if (!context.mounted) return;
        if (schedule == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esa clase ya no existe'),
              backgroundColor: AppTheme.error,
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClassDetailScreen(schedule: schedule)),
          );
        }
      } else {
        final event = await _calendarService.getEventById(referenciaId);
        if (!context.mounted) return;
        if (event == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ese evento ya no existe'),
              backgroundColor: AppTheme.error,
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventFormScreen(
                event: event,
                selectedDate: event.fecha,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
      return; // no se borra si falló por red — se puede reintentar
    }

    if (!context.mounted) return;
    await provider.delete(notification.id);
  }
}
