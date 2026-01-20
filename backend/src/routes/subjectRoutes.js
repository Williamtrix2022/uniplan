// ============================================
// RUTAS DE MATERIAS
// ============================================

const express = require('express');
const router = express.Router();
const subjectController = require('../controllers/subjectController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/subjects - Crear nueva materia
router.post('/', subjectController.createSubject);

// GET /api/subjects - Obtener todas las materias del estudiante
router.get('/', subjectController.getMySubjects);

// GET /api/subjects/stats - Obtener estadísticas
router.get('/stats', subjectController.getSubjectStats);

// GET /api/subjects/:id - Obtener una materia específica
router.get('/:id', subjectController.getSubjectById);

// PUT /api/subjects/:id - Actualizar materia
router.put('/:id', subjectController.updateSubject);

// DELETE /api/subjects/:id - Eliminar materia
router.delete('/:id', subjectController.deleteSubject);

module.exports = router;