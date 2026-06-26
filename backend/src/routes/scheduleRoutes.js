// ============================================
// RUTAS DE HORARIOS
// ============================================

const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/scheduleController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/schedules - Crear bloque de horario
router.post('/', scheduleController.createSchedule);

// GET /api/schedules - Obtener todos los horarios (con filtros opcionales: ?dia=lunes&id_materia=1)
router.get('/', scheduleController.getMySchedules);

// GET /api/schedules/week - Horario semanal completo ordenado lunes→domingo
router.get('/week', scheduleController.getWeekSchedule);

// GET /api/schedules/conflicts - Listar todos los conflictos del estudiante
router.get('/conflicts', scheduleController.getScheduleConflicts);

// GET /api/schedules/day/:dia - Horario de un día específico
router.get('/day/:dia', scheduleController.getScheduleByDay);

// GET /api/schedules/:id - Obtener un bloque específico
router.get('/:id', scheduleController.getScheduleById);

// PUT /api/schedules/:id - Actualizar bloque
router.put('/:id', scheduleController.updateSchedule);

// DELETE /api/schedules/:id - Eliminar bloque
router.delete('/:id', scheduleController.deleteSchedule);

module.exports = router;
