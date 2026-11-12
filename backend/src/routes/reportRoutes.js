// ============================================
// RUTAS DE REPORTES (PROBLEMAS Y SUGERENCIAS)
// ============================================

const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middlewares/authMiddleware');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/reportValidators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/reports - Crear nuevo reporte
router.post('/', v.create, handleValidation, reportController.createReport);

// GET /api/reports - Obtener los reportes del estudiante autenticado
router.get('/', v.list, handleValidation, reportController.getMyReports);

module.exports = router;
