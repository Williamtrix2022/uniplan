// ============================================
// RUTAS DE ESTUDIANTES
// ============================================

const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const authMiddleware = require('../middlewares/authMiddleware');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/studentValidators');

// ========== TODAS LAS RUTAS REQUIEREN AUTENTICACIÓN ==========
router.use(authMiddleware);

// GET /api/students/:id - Obtener un estudiante específico
router.get('/:id', v.detail, handleValidation, studentController.getStudentById);

// PUT /api/students/:id - Actualizar un estudiante
router.put('/:id', v.update, handleValidation, studentController.updateStudent);

// DELETE /api/students/:id - Eliminar un estudiante
router.delete('/:id', v.detail, handleValidation, studentController.deleteStudent);

module.exports = router;
