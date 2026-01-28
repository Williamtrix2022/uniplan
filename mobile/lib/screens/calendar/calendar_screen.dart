// ============================================
// PANTALLA DE CALENDARIO
// ============================================

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_service.dart';
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

      // Organizar eventos por día
      final Map<DateTime, List<CalendarEvent>> eventsMap = {};
      
      for (var event in events) {
        final date = DateTime(
          event.fecha.year,
          event.fecha.month,
          event.fecha.day,
        );
        
        if (eventsMap[date] == null) {
          eventsMap[date] = [];
        }
        eventsMap[date]!.add(event);
      }

      setState(() {
        _events = eventsMap;
        _selectedEvents = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      print('Error loading events: $e');
    } finally {
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadEvents();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendario
                _buildCalendar(),
                
                const SizedBox(height: 8),
                
                // Título de eventos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? DateFormat('EEEE, d MMMM', 'es_ES')
                                .format(_selectedDay!)
                            : 'Eventos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        '${_selectedEvents.length} eventos',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Lista de eventos
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildEventsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventForm(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Nuevo evento',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
        
        // Estilo
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: AppTheme.error),
        ),
        
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppTheme.greyText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay eventos para este día',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(_selectedEvents[index]);
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final eventColor = event.getColor();
    
    return GestureDetector(
      onTap: () => _openEventForm(event: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: eventColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: eventColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Barra de color
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Información del evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Tipo de evento
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: eventColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
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
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      if (!event.todoElDia &&
                          event.horaInicio != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.horaInicio!.format(context)}${event.horaFin != null ? ' - ${event.horaFin!.format(context)}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.all_inclusive,
                          size: 14,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Todo el día',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                      
                      if (event.ubicacion != null &&
                          event.ubicacion!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.ubicacion!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Menú de opciones
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
    );
  }
}