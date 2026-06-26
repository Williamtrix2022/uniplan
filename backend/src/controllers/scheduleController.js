// ============================================
// CONTROLADOR DE HORARIOS
// ============================================

const Schedule = require('../models/Schedule');

const VALID_DAYS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

// Crear bloque de horario
const createSchedule = async (req, res) => {
  try {
    const { id_materia, dia, hora_inicio, hora_fin, aula, force } = req.body;
    const id_estudiante = req.user.id;

    if (!id_materia || !dia || !hora_inicio || !hora_fin) {
      return res.status(400).json({
        success: false,
        message: 'id_materia, dia, hora_inicio y hora_fin son obligatorios'
      });
    }

    if (!VALID_DAYS.includes(dia)) {
      return res.status(400).json({
        success: false,
        message: `Día inválido. Valores permitidos: ${VALID_DAYS.join(', ')}`
      });
    }

    if (hora_fin <= hora_inicio) {
      return res.status(400).json({
        success: false,
        message: 'hora_fin debe ser posterior a hora_inicio'
      });
    }

    if (!force) {
      const conflicts = await Schedule.detectConflicts(id_estudiante, dia, hora_inicio, hora_fin);
      if (conflicts.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'El horario se superpone con una o más clases existentes',
          conflicts
        });
      }
    }

    const scheduleId = await Schedule.create({ id_estudiante, id_materia, dia, hora_inicio, hora_fin, aula });
    const schedule = await Schedule.findById(scheduleId);

    res.status(201).json({
      success: true,
      message: 'Bloque de horario creado exitosamente',
      data: schedule
    });

  } catch (error) {
    console.error('Error en createSchedule:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear bloque de horario',
      error: error.message
    });
  }
};

// Obtener todos los horarios del estudiante
const getMySchedules = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { dia, id_materia } = req.query;

    const filters = {};
    if (dia) filters.dia = dia;
    if (id_materia) filters.id_materia = id_materia;

    const schedules = await Schedule.findByStudent(id_estudiante, filters);

    res.json({
      success: true,
      count: schedules.length,
      data: schedules
    });

  } catch (error) {
    console.error('Error en getMySchedules:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener horarios',
      error: error.message
    });
  }
};

// Obtener horario semanal completo
const getWeekSchedule = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const schedules = await Schedule.findWeekSchedule(id_estudiante);

    res.json({
      success: true,
      count: schedules.length,
      data: schedules
    });

  } catch (error) {
    console.error('Error en getWeekSchedule:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener horario semanal',
      error: error.message
    });
  }
};

// Obtener horario de un día específico
const getScheduleByDay = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { dia } = req.params;

    if (!VALID_DAYS.includes(dia)) {
      return res.status(400).json({
        success: false,
        message: `Día inválido. Valores permitidos: ${VALID_DAYS.join(', ')}`
      });
    }

    const schedules = await Schedule.findByDay(id_estudiante, dia);

    res.json({
      success: true,
      count: schedules.length,
      data: schedules
    });

  } catch (error) {
    console.error('Error en getScheduleByDay:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener horario del día',
      error: error.message
    });
  }
};

// Obtener todos los conflictos del estudiante
const getScheduleConflicts = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const schedules = await Schedule.findWeekSchedule(id_estudiante);

    const conflicts = [];

    for (let i = 0; i < schedules.length; i++) {
      for (let j = i + 1; j < schedules.length; j++) {
        const a = schedules[i];
        const b = schedules[j];
        if (
          a.dia === b.dia &&
          a.hora_inicio < b.hora_fin &&
          a.hora_fin > b.hora_inicio
        ) {
          conflicts.push({ block_a: a, block_b: b });
        }
      }
    }

    res.json({
      success: true,
      count: conflicts.length,
      data: conflicts
    });

  } catch (error) {
    console.error('Error en getScheduleConflicts:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener conflictos de horario',
      error: error.message
    });
  }
};

// Obtener un bloque por ID
const getScheduleById = async (req, res) => {
  try {
    const { id } = req.params;
    const schedule = await Schedule.findById(id);

    if (!schedule) {
      return res.status(404).json({
        success: false,
        message: 'Bloque de horario no encontrado'
      });
    }

    if (schedule.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver este horario'
      });
    }

    res.json({
      success: true,
      data: schedule
    });

  } catch (error) {
    console.error('Error en getScheduleById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener bloque de horario',
      error: error.message
    });
  }
};

// Actualizar bloque de horario
const updateSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const { id_materia, dia, hora_inicio, hora_fin, aula, force } = req.body;

    const schedule = await Schedule.findById(id);

    if (!schedule) {
      return res.status(404).json({
        success: false,
        message: 'Bloque de horario no encontrado'
      });
    }

    if (schedule.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar este horario'
      });
    }

    const newDia        = dia        || schedule.dia;
    const newHoraInicio = hora_inicio || schedule.hora_inicio;
    const newHoraFin    = hora_fin    || schedule.hora_fin;

    if (dia && !VALID_DAYS.includes(dia)) {
      return res.status(400).json({
        success: false,
        message: `Día inválido. Valores permitidos: ${VALID_DAYS.join(', ')}`
      });
    }

    if (newHoraFin <= newHoraInicio) {
      return res.status(400).json({
        success: false,
        message: 'hora_fin debe ser posterior a hora_inicio'
      });
    }

    if (!force) {
      const conflicts = await Schedule.detectConflicts(
        req.user.id, newDia, newHoraInicio, newHoraFin, Number(id)
      );
      if (conflicts.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'El horario actualizado se superpone con una o más clases existentes',
          conflicts
        });
      }
    }

    await Schedule.update(id, {
      id_materia: id_materia || schedule.id_materia,
      dia:        newDia,
      hora_inicio: newHoraInicio,
      hora_fin:    newHoraFin,
      aula:       aula !== undefined ? aula : schedule.aula
    });

    const updated = await Schedule.findById(id);

    res.json({
      success: true,
      message: 'Bloque de horario actualizado exitosamente',
      data: updated
    });

  } catch (error) {
    console.error('Error en updateSchedule:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar bloque de horario',
      error: error.message
    });
  }
};

// Eliminar bloque de horario
const deleteSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const schedule = await Schedule.findById(id);

    if (!schedule) {
      return res.status(404).json({
        success: false,
        message: 'Bloque de horario no encontrado'
      });
    }

    if (schedule.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar este horario'
      });
    }

    await Schedule.delete(id);

    res.json({
      success: true,
      message: 'Bloque de horario eliminado exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteSchedule:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar bloque de horario',
      error: error.message
    });
  }
};

module.exports = {
  createSchedule,
  getMySchedules,
  getWeekSchedule,
  getScheduleByDay,
  getScheduleConflicts,
  getScheduleById,
  updateSchedule,
  deleteSchedule
};
