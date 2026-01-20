// ============================================
// RUTAS DE SESIONES POMODORO
// ============================================

const express = require('express');
const router = express.Router();
const pomodoroController = require('../controllers/pomodoroController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/pomodoro - Crear nueva sesión
router.post('/', pomodoroController.createSession);

// GET /api/pomodoro - Obtener todas las sesiones (con filtros)
router.get('/', pomodoroController.getMySessions);

// GET /api/pomodoro/today - Obtener sesiones de hoy
router.get('/today', pomodoroController.getTodaySessions);

// GET /api/pomodoro/stats - Obtener estadísticas generales
router.get('/stats', pomodoroController.getStats);

// GET /api/pomodoro/stats/subject - Estadísticas por materia
router.get('/stats/subject', pomodoroController.getStatsBySubject);

// GET /api/pomodoro/stats/day - Estadísticas por día
router.get('/stats/day', pomodoroController.getStatsByDay);

// GET /api/pomodoro/:id - Obtener una sesión específica
router.get('/:id', pomodoroController.getSessionById);

// PUT /api/pomodoro/:id - Actualizar sesión
router.put('/:id', pomodoroController.updateSession);

// PATCH /api/pomodoro/:id/complete - Finalizar sesión
router.patch('/:id/complete', pomodoroController.completeSession);

// DELETE /api/pomodoro/:id - Eliminar sesión
router.delete('/:id', pomodoroController.deleteSession);

module.exports = router;