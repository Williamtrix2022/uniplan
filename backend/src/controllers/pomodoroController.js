// ============================================
// CONTROLADOR DE SESIONES POMODORO
// ============================================

const Pomodoro = require('../models/Pomodoro');

// Crear nueva sesión Pomodoro
const createSession = async (req, res) => {
  try {
    const { id_materia, duracion_trabajo, duracion_descanso, notas } = req.body;
    const id_estudiante = req.user.id;

    const sessionId = await Pomodoro.create({
      id_estudiante,
      id_materia,
      duracion_trabajo,
      duracion_descanso,
      fecha_inicio: new Date(),
      notas
    });

    const session = await Pomodoro.findById(sessionId);

    res.status(201).json({
      success: true,
      message: 'Sesión Pomodoro iniciada',
      data: session
    });

  } catch (error) {
    console.error('Error en createSession:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear sesión',
      error: error.message
    });
  }
};

// Obtener todas las sesiones del estudiante
const getMySessions = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { id_materia, completada, fecha_inicio, fecha_fin } = req.query;

    const filters = {};
    if (id_materia) filters.id_materia = id_materia;
    if (completada !== undefined) filters.completada = completada === 'true';
    if (fecha_inicio && fecha_fin) {
      filters.fecha_inicio = fecha_inicio;
      filters.fecha_fin = fecha_fin;
    }

    const sessions = await Pomodoro.findByStudent(id_estudiante, filters);

    res.json({
      success: true,
      count: sessions.length,
      data: sessions
    });

  } catch (error) {
    console.error('Error en getMySessions:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener sesiones',
      error: error.message
    });
  }
};

// Obtener sesiones de hoy
const getTodaySessions = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const sessions = await Pomodoro.getToday(id_estudiante);

    res.json({
      success: true,
      count: sessions.length,
      data: sessions
    });

  } catch (error) {
    console.error('Error en getTodaySessions:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener sesiones de hoy',
      error: error.message
    });
  }
};

// Obtener sesión por ID
const getSessionById = async (req, res) => {
  try {
    const { id } = req.params;
    const session = await Pomodoro.findById(id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    if (session.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta sesión'
      });
    }

    res.json({
      success: true,
      data: session
    });

  } catch (error) {
    console.error('Error en getSessionById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener sesión',
      error: error.message
    });
  }
};

// Actualizar sesión
const updateSession = async (req, res) => {
  try {
    const { id } = req.params;
    const { ciclos_completados, tiempo_total_estudio, notas } = req.body;

    const session = await Pomodoro.findById(id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    if (session.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar esta sesión'
      });
    }

    const updated = await Pomodoro.update(id, {
      ciclos_completados: ciclos_completados || session.ciclos_completados,
      tiempo_total_estudio: tiempo_total_estudio || session.tiempo_total_estudio,
      fecha_fin: session.fecha_fin,
      completada: session.completada,
      notas: notas !== undefined ? notas : session.notas
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la sesión'
      });
    }

    const updatedSession = await Pomodoro.findById(id);

    res.json({
      success: true,
      message: 'Sesión actualizada exitosamente',
      data: updatedSession
    });

  } catch (error) {
    console.error('Error en updateSession:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar sesión',
      error: error.message
    });
  }
};

// Finalizar sesión
const completeSession = async (req, res) => {
  try {
    const { id } = req.params;
    const { ciclos_completados, tiempo_total_estudio } = req.body;

    const session = await Pomodoro.findById(id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    if (session.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para completar esta sesión'
      });
    }

    if (session.completada) {
      return res.status(400).json({
        success: false,
        message: 'La sesión ya está completada'
      });
    }

    const completed = await Pomodoro.complete(
      id, 
      ciclos_completados || session.ciclos_completados,
      tiempo_total_estudio || session.tiempo_total_estudio
    );

    if (!completed) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo completar la sesión'
      });
    }

    const updatedSession = await Pomodoro.findById(id);

    res.json({
      success: true,
      message: 'Sesión completada exitosamente',
      data: updatedSession
    });

  } catch (error) {
    console.error('Error en completeSession:', error);
    res.status(500).json({
      success: false,
      message: 'Error al completar sesión',
      error: error.message
    });
  }
};

// Eliminar sesión
const deleteSession = async (req, res) => {
  try {
    const { id } = req.params;
    const session = await Pomodoro.findById(id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    if (session.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta sesión'
      });
    }

    const deleted = await Pomodoro.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar la sesión'
      });
    }

    res.json({
      success: true,
      message: 'Sesión eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteSession:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar sesión',
      error: error.message
    });
  }
};

// Obtener estadísticas
const getStats = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { periodo } = req.query; // today, week, month

    const stats = await Pomodoro.getStats(id_estudiante, periodo || 'week');

    res.json({
      success: true,
      periodo: periodo || 'week',
      data: stats
    });

  } catch (error) {
    console.error('Error en getStats:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas',
      error: error.message
    });
  }
};

// Obtener estadísticas por materia
const getStatsBySubject = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Pomodoro.getBySubject(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getStatsBySubject:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas por materia',
      error: error.message
    });
  }
};

// Obtener estadísticas por día
const getStatsByDay = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Pomodoro.getByDay(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getStatsByDay:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas por día',
      error: error.message
    });
  }
};

module.exports = {
  createSession,
  getMySessions,
  getTodaySessions,
  getSessionById,
  updateSession,
  completeSession,
  deleteSession,
  getStats,
  getStatsBySubject,
  getStatsByDay
};