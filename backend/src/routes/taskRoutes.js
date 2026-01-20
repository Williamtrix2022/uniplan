// ============================================
// RUTAS DE TAREAS
// ============================================

const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/tasks - Crear nueva tarea
router.post('/', taskController.createTask);

// GET /api/tasks - Obtener todas las tareas (con filtros opcionales)
router.get('/', taskController.getMyTasks);

// GET /api/tasks/upcoming - Obtener tareas próximas
router.get('/upcoming', taskController.getUpcomingTasks);

// GET /api/tasks/stats - Obtener estadísticas
router.get('/stats', taskController.getTaskStats);

// GET /api/tasks/:id - Obtener una tarea específica
router.get('/:id', taskController.getTaskById);

// PUT /api/tasks/:id - Actualizar tarea
router.put('/:id', taskController.updateTask);

// PATCH /api/tasks/:id/complete - Marcar como completada
router.patch('/:id/complete', taskController.completeTask);

// DELETE /api/tasks/:id - Eliminar tarea
router.delete('/:id', taskController.deleteTask);

module.exports = router;