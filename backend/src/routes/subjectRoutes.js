// ============================================
// RUTAS DE MATERIAS
// ============================================

const express = require('express');
const router = express.Router();
const subjectController = require('../controllers/subjectController');
const authMiddleware = require('../middlewares/authMiddleware');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/subjectValidators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/subjects - Crear nueva materia
router.post('/', v.create, handleValidation, subjectController.createSubject);

// GET /api/subjects - Obtener todas las materias del estudiante
router.get('/', subjectController.getMySubjects);

// GET /api/subjects/stats - Obtener estadísticas
router.get('/stats', subjectController.getSubjectStats);

// GET /api/subjects/:id - Obtener una materia específica
router.get('/:id', v.detail, handleValidation, subjectController.getSubjectById);

// PUT /api/subjects/:id - Actualizar materia
router.put('/:id', v.update, handleValidation, subjectController.updateSubject);

// DELETE /api/subjects/:id - Eliminar materia
router.delete('/:id', v.detail, handleValidation, subjectController.deleteSubject);

module.exports = router;
