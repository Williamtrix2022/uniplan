// ============================================
// RUTAS DE AUTENTICACIÓN
// ============================================

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');

// ========== RUTAS PÚBLICAS (sin autenticación) ==========

// POST /api/auth/register - Registrar nuevo estudiante
router.post('/register', authController.register);

// POST /api/auth/login - Iniciar sesión
router.post('/login', authController.login);

// ========== RUTAS PROTEGIDAS (requieren autenticación) ==========

// GET /api/auth/profile - Obtener perfil del usuario autenticado
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;