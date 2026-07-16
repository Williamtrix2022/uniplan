// ============================================
// RUTAS DE NOTIFICACIONES
// ============================================

const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Rutas literales primero para evitar colisiones con /:id

// GET /api/notifications/unread-count - Contar notificaciones no leídas
router.get('/unread-count', notificationController.getUnreadCount);

// GET /api/notifications/preferences - Obtener preferencias de notificación
router.get('/preferences', notificationController.getPreferences);

// PUT /api/notifications/preferences - Actualizar preferencias de notificación
router.put('/preferences', notificationController.updatePreferences);

// PATCH /api/notifications/read-all - Marcar todas las notificaciones como leídas
router.patch('/read-all', notificationController.markAllRead);

// GET /api/notifications - Obtener notificaciones del estudiante (?tipo=&leida=)
router.get('/', notificationController.getNotifications);

// POST /api/notifications - Crear una notificación en el feed del estudiante
router.post('/', notificationController.createNotification);

// PATCH /api/notifications/:id/read - Marcar una notificación como leída
router.patch('/:id/read', notificationController.markRead);

// DELETE /api/notifications/:id - Eliminar una notificación
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
