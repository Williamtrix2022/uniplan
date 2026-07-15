// ============================================
// RUTAS DE CALIFICACIONES
// ============================================

const express = require('express');
const router = express.Router();
const gradeController = require('../controllers/gradeController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/grades - Crear calificación
router.post('/', gradeController.createGrade);

// GET /api/grades - Obtener todas las calificaciones del estudiante
router.get('/', gradeController.getMyGrades);

// GET /api/grades/summary - Resumen general (promedio general y por materia)
router.get('/summary', gradeController.getSummary);

// GET /api/grades/subject/:id - Calificaciones de una materia específica
router.get('/subject/:id', gradeController.getGradesBySubject);

// GET /api/grades/subject/:id/projection - Nota necesaria para aprobar la materia
router.get('/subject/:id/projection', gradeController.getSubjectProjection);

// GET /api/grades/:id - Obtener una calificación específica
router.get('/:id', gradeController.getGradeById);

// PUT /api/grades/:id - Actualizar calificación
router.put('/:id', gradeController.updateGrade);

// DELETE /api/grades/:id - Eliminar calificación
router.delete('/:id', gradeController.deleteGrade);

module.exports = router;
