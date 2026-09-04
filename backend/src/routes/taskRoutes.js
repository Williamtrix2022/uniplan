// ============================================
// RUTAS DE TAREAS
// ============================================

const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middlewares/authMiddleware');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/taskValidators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/tasks - Crear nueva tarea
router.post('/', v.create, handleValidation, taskController.createTask);

// GET /api/tasks - Obtener todas las tareas (con filtros opcionales)
router.get('/', v.list, handleValidation, taskController.getMyTasks);

// GET /api/tasks/upcoming - Obtener tareas próximas
router.get('/upcoming', taskController.getUpcomingTasks);

// GET /api/tasks/stats - Obtener estadísticas
router.get('/stats', taskController.getTaskStats);

// GET /api/tasks/:id - Obtener una tarea específica
router.get('/:id', v.detail, handleValidation, taskController.getTaskById);

// PUT /api/tasks/:id - Actualizar tarea
router.put('/:id', v.update, handleValidation, taskController.updateTask);

// PATCH /api/tasks/:id/complete - Compatibilidad con ruta previa
router.patch('/:id/complete', v.toggle, handleValidation, taskController.toggleTaskComplete);

// PATCH /api/tasks/:id/toggle - Marcar/desmarcar como completada
router.patch('/:id/toggle', v.toggle, handleValidation, taskController.toggleTaskComplete);

// DELETE /api/tasks/:id - Eliminar tarea
router.delete('/:id', v.detail, handleValidation, taskController.deleteTask);

module.exports = router;
