// ============================================
// CONTROLADOR DE CALENDARIO
// ============================================

const Calendar = require('../models/Calendar');

// Crear nuevo evento
const createEvent = async (req, res) => {
  try {
    const { 
      id_materia, titulo, descripcion, fecha, hora_inicio, 
      hora_fin, tipo, ubicacion, recordatorio, 
      minutos_antes_recordatorio, todo_el_dia, color 
    } = req.body;
    const id_estudiante = req.user.id;

    if (!titulo || !fecha) {
      return res.status(400).json({
        success: false,
        message: 'Título y fecha son obligatorios'
      });
    }

    const eventId = await Calendar.create({
      id_estudiante,
      id_materia,
      titulo,
      descripcion,
      fecha,
      hora_inicio,
      hora_fin,
      tipo,
      ubicacion,
      recordatorio,
      minutos_antes_recordatorio,
      todo_el_dia,
      color
    });

    const event = await Calendar.findById(eventId);

    res.status(201).json({
      success: true,
      message: 'Evento creado exitosamente',
      data: event
    });

  } catch (error) {
    console.error('Error en createEvent:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear evento',
      error: error.message
    });
  }
};

// Obtener todos los eventos
const getMyEvents = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { tipo, id_materia, fecha_inicio, fecha_fin, fecha } = req.query;

    const filters = {};
    if (tipo) filters.tipo = tipo;
    if (id_materia) filters.id_materia = id_materia;
    if (fecha_inicio && fecha_fin) {
      filters.fecha_inicio = fecha_inicio;
      filters.fecha_fin = fecha_fin;
    }
    if (fecha) filters.fecha = fecha;

    const events = await Calendar.findByStudent(id_estudiante, filters);

    res.json({
      success: true,
      count: events.length,
      data: events
    });

  } catch (error) {
    console.error('Error en getMyEvents:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener eventos',
      error: error.message
    });
  }
};

// Obtener eventos de hoy
const getTodayEvents = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const events = await Calendar.getToday(id_estudiante);

    res.json({
      success: true,
      count: events.length,
      data: events
    });

  } catch (error) {
    console.error('Error en getTodayEvents:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener eventos de hoy',
      error: error.message
    });
  }
};

// Obtener eventos de la semana
const getWeekEvents = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const events = await Calendar.getWeek(id_estudiante);

    res.json({
      success: true,
      count: events.length,
      data: events
    });

  } catch (error) {
    console.error('Error en getWeekEvents:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener eventos de la semana',
      error: error.message
    });
  }
};

// Obtener eventos del mes
const getMonthEvents = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { year, month } = req.query;

    if (!year || !month) {
      return res.status(400).json({
        success: false,
        message: 'Año y mes son obligatorios'
      });
    }

    const events = await Calendar.getMonth(id_estudiante, year, month);

    res.json({
      success: true,
      count: events.length,
      data: events
    });

  } catch (error) {
    console.error('Error en getMonthEvents:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener eventos del mes',
      error: error.message
    });
  }
};

// Obtener eventos con recordatorio
const getEventsWithReminder = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const events = await Calendar.getUpcomingWithReminder(id_estudiante);

    res.json({
      success: true,
      count: events.length,
      data: events
    });

  } catch (error) {
    console.error('Error en getEventsWithReminder:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener eventos con recordatorio',
      error: error.message
    });
  }
};

// Obtener evento por ID
const getEventById = async (req, res) => {
  try {
    const { id } = req.params;
    const event = await Calendar.findById(id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Evento no encontrado'
      });
    }

    if (event.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver este evento'
      });
    }

    res.json({
      success: true,
      data: event
    });

  } catch (error) {
    console.error('Error en getEventById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener evento',
      error: error.message
    });
  }
};

// Actualizar evento
const updateEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      titulo, descripcion, fecha, hora_inicio, hora_fin, 
      tipo, ubicacion, id_materia, recordatorio, 
      minutos_antes_recordatorio, todo_el_dia, color 
    } = req.body;

    const event = await Calendar.findById(id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Evento no encontrado'
      });
    }

    if (event.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar este evento'
      });
    }

    const updated = await Calendar.update(id, {
      titulo: titulo || event.titulo,
      descripcion: descripcion !== undefined ? descripcion : event.descripcion,
      fecha: fecha || event.fecha,
      hora_inicio: hora_inicio !== undefined ? hora_inicio : event.hora_inicio,
      hora_fin: hora_fin !== undefined ? hora_fin : event.hora_fin,
      tipo: tipo || event.tipo,
      ubicacion: ubicacion !== undefined ? ubicacion : event.ubicacion,
      id_materia: id_materia !== undefined ? id_materia : event.id_materia,
      recordatorio: recordatorio !== undefined ? recordatorio : event.recordatorio,
      minutos_antes_recordatorio: minutos_antes_recordatorio || event.minutos_antes_recordatorio,
      todo_el_dia: todo_el_dia !== undefined ? todo_el_dia : event.todo_el_dia,
      color: color || event.color
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar el evento'
      });
    }

    const updatedEvent = await Calendar.findById(id);

    res.json({
      success: true,
      message: 'Evento actualizado exitosamente',
      data: updatedEvent
    });

  } catch (error) {
    console.error('Error en updateEvent:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar evento',
      error: error.message
    });
  }
};

// Eliminar evento
const deleteEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const event = await Calendar.findById(id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Evento no encontrado'
      });
    }

    if (event.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar este evento'
      });
    }

    const deleted = await Calendar.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar el evento'
      });
    }

    res.json({
      success: true,
      message: 'Evento eliminado exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteEvent:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar evento',
      error: error.message
    });
  }
};

// Obtener estadísticas
const getCalendarStats = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Calendar.getStats(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getCalendarStats:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas',
      error: error.message
    });
  }
};

module.exports = {
  createEvent,
  getMyEvents,
  getTodayEvents,
  getWeekEvents,
  getMonthEvents,
  getEventsWithReminder,
  getEventById,
  updateEvent,
  deleteEvent,
  getCalendarStats
};