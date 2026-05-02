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

// POST /api/auth/forgot-password - Solicitar recuperación de contraseña
router.post('/forgot-password', authController.forgotPassword);

// POST /api/auth/reset-password - Restablecer contraseña
router.post('/reset-password', authController.resetPassword);

// ========== RUTAS PROTEGIDAS (requieren autenticación) ==========

// GET /api/auth/profile - Obtener perfil del usuario autenticado
router.get('/profile', authMiddleware, authController.getProfile);

// PATCH /api/auth/change-password - Cambiar contraseña del usuario autenticado
router.patch('/change-password', authMiddleware, authController.changePassword);

module.exports = router;
