// ============================================
// RUTAS DE ESTUDIANTES
// ============================================

const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const authMiddleware = require('../middlewares/authMiddleware');

// ========== TODAS LAS RUTAS REQUIEREN AUTENTICACIÓN ==========
router.use(authMiddleware);

// GET /api/students - Obtener todos los estudiantes
router.get('/', studentController.getAllStudents);

// GET /api/students/:id - Obtener un estudiante específico
router.get('/:id', studentController.getStudentById);

// PUT /api/students/:id - Actualizar un estudiante
router.put('/:id', studentController.updateStudent);

// DELETE /api/students/:id - Eliminar un estudiante
router.delete('/:id', studentController.deleteStudent);

module.exports = router;