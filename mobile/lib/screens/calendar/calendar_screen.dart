// ============================================
// PANTALLA DE CALENDARIO
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/tasks_screen.dart';
import 'event_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 2;

  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);

    try {
      final events = await _calendarService.getMonthEvents(
        _focusedDay.year,
        _focusedDay.month,
      );

      final Map<DateTime, List<CalendarEvent>> eventsMap = {};
      for (final event in events) {
        final date = DateTime(event.fecha.year, event.fecha.month, event.fecha.day);
        eventsMap.putIfAbsent(date, () => []);
        eventsMap[date]!.add(event);
      }

      setState(() {
        _events = eventsMap;
        _selectedEvents = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _loadEvents();
  }

  void _openEventForm({CalendarEvent? event}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          event: event,
          selectedDate: _selectedDay ?? DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Estás seguro de eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id != null) {
      try {
        await _calendarService.deleteEvent(event.id!);
        _loadEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento eliminado'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = _focusedDay;
    });
    _loadEvents();
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
          child: Container(height: 1, color: AppTheme.surfaceContainerHighest),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay),
          style: const TextStyle(
            color: AppTheme.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            color: AppTheme.darkText,
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppTheme.darkText,
            onPressed: () => _openEventForm(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildCalendarCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 16),
                    if (_selectedEvents.isEmpty)
                      _buildEmptyState()
                    else
                      ..._selectedEvents.map(_buildEventCard),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventForm(),
        backgroundColor: AppTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Nuevo evento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
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
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
        break;
    }
  }

  Widget _buildSummaryCard() {
    final selectedLabel = _selectedDay != null
        ? DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!)
        : 'Eventos';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agenda del día',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedLabel[0].toUpperCase() + selectedLabel.substring(1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedEvents.length} eventos programados',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.darkText,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Hoy',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'es_ES',
        availableGestures: AvailableGestures.horizontalSwipe,
        headerVisible: false,
        daysOfWeekHeight: 24,
        rowHeight: 44,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
          markersAlignment: Alignment.bottomCenter,
          markerDecoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
          ),
          selectedTextStyle: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w700,
          ),
          defaultTextStyle: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: const TextStyle(
            color: AppTheme.error,
            fontWeight: FontWeight.w500,
          ),
          outsideTextStyle: const TextStyle(
            color: AppTheme.greyText,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: AppTheme.error,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: _onPageChanged,
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'EVENTOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          '${_selectedEvents.length} eventos',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.greyText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 56,
            color: AppTheme.greyText.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay eventos para este día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea uno nuevo para mantener tu agenda organizada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final eventColor = event.getColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          onTap: () => _openEventForm(event: event),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: eventColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: eventColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              event.getTypeLabel(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: eventColor,
                              ),
                            ),
                          ),
                          if (event.materiaNombre != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                event.materiaNombre!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.greyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                      if (event.descripcion != null &&
                          event.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.descripcion!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyText,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildMetaItem(
                            icon: event.todoElDia
                                ? Icons.all_inclusive
                                : Icons.access_time,
                            text: event.todoElDia
                                ? 'Todo el día'
                                : '${event.horaInicio!.format(context)}${event.horaFin != null ? ' - ${event.horaFin!.format(context)}' : ''}',
                          ),
                          if (event.ubicacion != null &&
                              event.ubicacion!.isNotEmpty)
                            _buildMetaItem(
                              icon: Icons.location_on_outlined,
                              text: event.ubicacion!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.greyText,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppTheme.error),
                          SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEventForm(event: event);
                    } else if (value == 'delete') {
                      _deleteEvent(event);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.greyText,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }
}
