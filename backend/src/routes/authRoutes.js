// ============================================
// RUTAS DE AUTENTICACIÓN
// ============================================

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');
const { authLimiter, resetLimiter } = require('../middlewares/rateLimiter');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/authValidators');

// ========== RUTAS PÚBLICAS (sin autenticación) ==========

// POST /api/auth/register - Registrar nuevo estudiante
router.post('/register', authLimiter, v.register, handleValidation, authController.register);

// POST /api/auth/login - Iniciar sesión
router.post('/login', authLimiter, v.login, handleValidation, authController.login);

// POST /api/auth/forgot-password - Solicitar recuperación de contraseña
router.post('/forgot-password', resetLimiter, v.forgotPassword, handleValidation, authController.forgotPassword);

// POST /api/auth/reset-password - Restablecer contraseña
router.post('/reset-password', resetLimiter, v.resetPassword, handleValidation, authController.resetPassword);

// ========== RUTAS PROTEGIDAS (requieren autenticación) ==========

// GET /api/auth/profile - Obtener perfil del usuario autenticado
router.get('/profile', authMiddleware, authController.getProfile);

// PATCH /api/auth/change-password - Cambiar contraseña del usuario autenticado
router.patch('/change-password', authMiddleware, v.changePassword, handleValidation, authController.changePassword);

module.exports = router;
