// ============================================
// CONTROLADOR DE NOTIFICACIONES
// ============================================

const Notification = require('../models/Notification');

const VALID_TYPES = ['tarea', 'clase', 'sistema', 'general'];

// Obtener notificaciones del estudiante (con filtros opcionales ?tipo=&leida=)
const getNotifications = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { tipo, leida } = req.query;

    if (tipo !== undefined && !VALID_TYPES.includes(tipo)) {
      return res.status(400).json({
        success: false,
        message: `Tipo inválido. Valores permitidos: ${VALID_TYPES.join(', ')}`
      });
    }

    let leidaFilter;
    if (leida !== undefined) {
      if (leida !== 'true' && leida !== 'false') {
        return res.status(400).json({
          success: false,
          message: 'leida debe ser "true" o "false"'
        });
      }
      leidaFilter = leida === 'true';
    }

    const notifications = await Notification.findByStudent(id_estudiante, {
      tipo,
      leida: leidaFilter
    });

    res.json({
      success: true,
      count: notifications.length,
      data: notifications
    });

  } catch (error) {
    console.error('Error en getNotifications:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener notificaciones',
      error: error.message
    });
  }
};

// Crear una notificación en el feed del estudiante (usada por el motor de
// recordatorios locales del cliente para que la campanita / Centro de
// Notificaciones reflejen los recordatorios que se programan en el
// dispositivo — el backend no dispara nada, solo persiste el feed)
const createNotification = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const {
      tipo,
      titulo,
      mensaje,
      referencia_tipo,
      referencia_id,
      fecha_programada
    } = req.body;

    if (tipo !== undefined && !VALID_TYPES.includes(tipo)) {
      return res.status(400).json({
        success: false,
        message: `Tipo inválido. Valores permitidos: ${VALID_TYPES.join(', ')}`
      });
    }

    if (!titulo || !titulo.trim()) {
      return res.status(400).json({
        success: false,
        message: 'titulo es obligatorio'
      });
    }

    const created = await Notification.create({
      id_estudiante,
      tipo,
      titulo,
      mensaje,
      referencia_tipo,
      referencia_id,
      fecha_programada
    });

    res.status(201).json({
      success: true,
      message: 'Notificación creada exitosamente',
      data: created
    });

  } catch (error) {
    console.error('Error en createNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear notificación',
      error: error.message
    });
  }
};

// Contar notificaciones no leídas
const getUnreadCount = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const count = await Notification.getUnreadCount(id_estudiante);

    res.json({
      success: true,
      data: { unread_count: count }
    });

  } catch (error) {
    console.error('Error en getUnreadCount:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener el conteo de notificaciones no leídas',
      error: error.message
    });
  }
};

// Marcar una notificación como leída
const markRead = async (req, res) => {
  try {
    const { id } = req.params;
    const id_estudiante = req.user.id;

    const existing = await Notification.findById(id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Notificación no encontrada'
      });
    }

    if (existing.id_estudiante !== id_estudiante) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para modificar esta notificación'
      });
    }

    const updated = await Notification.markAsRead(id, id_estudiante);

    res.json({
      success: true,
      message: 'Notificación marcada como leída',
      data: updated
    });

  } catch (error) {
    console.error('Error en markRead:', error);
    res.status(500).json({
      success: false,
      message: 'Error al marcar la notificación como leída',
      error: error.message
    });
  }
};

// Marcar todas las notificaciones del estudiante como leídas
const markAllRead = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const updatedCount = await Notification.markAllAsRead(id_estudiante);

    res.json({
      success: true,
      message: 'Notificaciones marcadas como leídas',
      count: updatedCount
    });

  } catch (error) {
    console.error('Error en markAllRead:', error);
    res.status(500).json({
      success: false,
      message: 'Error al marcar las notificaciones como leídas',
      error: error.message
    });
  }
};

// Eliminar (soft delete) una notificación
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const id_estudiante = req.user.id;

    const existing = await Notification.findById(id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Notificación no encontrada'
      });
    }

    if (existing.id_estudiante !== id_estudiante) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta notificación'
      });
    }

    await Notification.remove(id, id_estudiante);

    res.json({
      success: true,
      message: 'Notificación eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar la notificación',
      error: error.message
    });
  }
};

// Obtener preferencias de notificación del estudiante
const getPreferences = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const preferences = await Notification.getPreferences(id_estudiante);

    res.json({
      success: true,
      data: preferences
    });

  } catch (error) {
    console.error('Error en getPreferences:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener preferencias de notificación',
      error: error.message
    });
  }
};

// Actualizar preferencias de notificación del estudiante
const updatePreferences = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const {
      notif_tareas,
      notif_clases,
      notif_generales,
      minutos_antes_tarea,
      minutos_antes_clase,
      sonido_activo,
      hora_silencio_inicio,
      hora_silencio_fin
    } = req.body;

    if (minutos_antes_tarea !== undefined && (isNaN(minutos_antes_tarea) || minutos_antes_tarea < 0)) {
      return res.status(400).json({
        success: false,
        message: 'minutos_antes_tarea debe ser un número mayor o igual a 0'
      });
    }

    if (minutos_antes_clase !== undefined && (isNaN(minutos_antes_clase) || minutos_antes_clase < 0)) {
      return res.status(400).json({
        success: false,
        message: 'minutos_antes_clase debe ser un número mayor o igual a 0'
      });
    }

    const updated = await Notification.updatePreferences(id_estudiante, {
      notif_tareas,
      notif_clases,
      notif_generales,
      minutos_antes_tarea,
      minutos_antes_clase,
      sonido_activo,
      hora_silencio_inicio,
      hora_silencio_fin
    });

    res.json({
      success: true,
      message: 'Preferencias actualizadas exitosamente',
      data: updated
    });

  } catch (error) {
    console.error('Error en updatePreferences:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar preferencias de notificación',
      error: error.message
    });
  }
};

module.exports = {
  getNotifications,
  createNotification,
  getUnreadCount,
  markRead,
  markAllRead,
  deleteNotification,
  getPreferences,
  updatePreferences
};
