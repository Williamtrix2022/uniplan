// ============================================
// CONTROLADOR DE TAREAS
// ============================================

const Task = require('../models/Task');

// Crear nueva tarea
const createTask = async (req, res) => {
  try {
    const { id_materia, titulo, descripcion, fecha_entrega, prioridad, estado, recordatorio } = req.body;
    const id_estudiante = req.user.id;

    if (!titulo || !fecha_entrega) {
      return res.status(400).json({
        success: false,
        message: 'Título y fecha de entrega son obligatorios'
      });
    }

    const taskId = await Task.create({
      id_estudiante,
      id_materia,
      titulo,
      descripcion,
      fecha_entrega,
      prioridad,
      estado,
      recordatorio
    });

    const task = await Task.findById(taskId);

    res.status(201).json({
      success: true,
      message: 'Tarea creada exitosamente',
      data: task
    });

  } catch (error) {
    console.error('Error en createTask:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear tarea',
      error: error.message
    });
  }
};

// Obtener todas las tareas del estudiante
const getMyTasks = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { estado, prioridad, id_materia } = req.query;

    const filters = {};
    if (estado) filters.estado = estado;
    if (prioridad) filters.prioridad = prioridad;
    if (id_materia) filters.id_materia = id_materia;

    const tasks = await Task.findByStudent(id_estudiante, filters);

    res.json({
      success: true,
      count: tasks.length,
      data: tasks
    });

  } catch (error) {
    console.error('Error en getMyTasks:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener tareas',
      error: error.message
    });
  }
};

// Obtener tareas próximas
const getUpcomingTasks = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const tasks = await Task.getUpcoming(id_estudiante);

    res.json({
      success: true,
      count: tasks.length,
      data: tasks
    });

  } catch (error) {
    console.error('Error en getUpcomingTasks:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener tareas próximas',
      error: error.message
    });
  }
};

// Obtener tarea por ID
const getTaskById = async (req, res) => {
  try {
    const { id } = req.params;
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Tarea no encontrada'
      });
    }

    if (task.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta tarea'
      });
    }

    res.json({
      success: true,
      data: task
    });

  } catch (error) {
    console.error('Error en getTaskById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener tarea',
      error: error.message
    });
  }
};

// Actualizar tarea
const updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, descripcion, fecha_entrega, prioridad, estado, id_materia } = req.body;

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Tarea no encontrada'
      });
    }

    if (task.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar esta tarea'
      });
    }

    const updated = await Task.update(id, {
      titulo: titulo || task.titulo,
      descripcion: descripcion !== undefined ? descripcion : task.descripcion,
      fecha_entrega: fecha_entrega || task.fecha_entrega,
      prioridad: prioridad || task.prioridad,
      estado: estado || task.estado,
      id_materia: id_materia !== undefined ? id_materia : task.id_materia
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la tarea'
      });
    }

    const updatedTask = await Task.findById(id);

    res.json({
      success: true,
      message: 'Tarea actualizada exitosamente',
      data: updatedTask
    });

  } catch (error) {
    console.error('Error en updateTask:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar tarea',
      error: error.message
    });
  }
};

// Marcar tarea como completada
const completeTask = async (req, res) => {
  try {
    const { id } = req.params;
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Tarea no encontrada'
      });
    }

    if (task.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para completar esta tarea'
      });
    }

    const completed = await Task.markAsCompleted(id);

    if (!completed) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo completar la tarea'
      });
    }

    const updatedTask = await Task.findById(id);

    res.json({
      success: true,
      message: 'Tarea marcada como completada',
      data: updatedTask
    });

  } catch (error) {
    console.error('Error en completeTask:', error);
    res.status(500).json({
      success: false,
      message: 'Error al completar tarea',
      error: error.message
    });
  }
};

// Eliminar tarea
const deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Tarea no encontrada'
      });
    }

    if (task.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta tarea'
      });
    }

    const deleted = await Task.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar la tarea'
      });
    }

    res.json({
      success: true,
      message: 'Tarea eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteTask:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar tarea',
      error: error.message
    });
  }
};

// Obtener estadísticas
const getTaskStats = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Task.getStats(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getTaskStats:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas',
      error: error.message
    });
  }
};

module.exports = {
  createTask,
  getMyTasks,
  getUpcomingTasks,
  getTaskById,
  updateTask,
  completeTask,
  deleteTask,
  getTaskStats
};