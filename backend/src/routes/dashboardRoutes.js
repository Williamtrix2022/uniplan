// ============================================
// RUTAS DE DASHBOARD
// ============================================

const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// GET /api/dashboard - Dashboard completo
router.get('/', dashboardController.getDashboard);

// GET /api/dashboard/weekly - Resumen semanal
router.get('/weekly', dashboardController.getWeeklySummary);

// GET /api/dashboard/today - Resumen de hoy
router.get('/today', dashboardController.getTodaySummary);

module.exports = router;