// ============================================
// RUTAS DE CALENDARIO
// ============================================

const express = require('express');
const router = express.Router();
const calendarController = require('../controllers/calendarController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/calendar - Crear nuevo evento
router.post('/', calendarController.createEvent);

// GET /api/calendar - Obtener todos los eventos (con filtros)
router.get('/', calendarController.getMyEvents);

// GET /api/calendar/today - Eventos de hoy
router.get('/today', calendarController.getTodayEvents);

// GET /api/calendar/week - Eventos de la semana
router.get('/week', calendarController.getWeekEvents);

// GET /api/calendar/month - Eventos del mes (query: year, month)
router.get('/month', calendarController.getMonthEvents);

// GET /api/calendar/reminders - Eventos con recordatorio
router.get('/reminders', calendarController.getEventsWithReminder);

// GET /api/calendar/stats - Estadísticas
router.get('/stats', calendarController.getCalendarStats);

// GET /api/calendar/:id - Obtener evento específico
router.get('/:id', calendarController.getEventById);

// PUT /api/calendar/:id - Actualizar evento
router.put('/:id', calendarController.updateEvent);

// DELETE /api/calendar/:id - Eliminar evento
router.delete('/:id', calendarController.deleteEvent);

module.exports = router;