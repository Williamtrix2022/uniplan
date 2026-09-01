// ============================================
// VALIDADORES: AUTENTICACIÓN
// ============================================

const { body } = require('express-validator');
const { OPTIONAL } = require('./common');

const register = [
  body('nombre')
    .trim()
    .notEmpty().withMessage('El nombre es obligatorio')
    .isLength({ max: 100 }).withMessage('El nombre no puede superar 100 caracteres'),
  body('correo')
    .trim()
    .notEmpty().withMessage('El correo es obligatorio')
    .isEmail().withMessage('El correo no tiene un formato válido')
    .isLength({ max: 100 }).withMessage('El correo no puede superar 100 caracteres'),
  body('contrasena')
    .isString().withMessage('La contraseña es obligatoria')
    .isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),
  body('carrera')
    .optional(OPTIONAL)
    .trim()
    .isLength({ max: 100 }).withMessage('La carrera no puede superar 100 caracteres'),
  body('universidad')
    .optional(OPTIONAL)
    .trim()
    .isLength({ max: 150 }).withMessage('La universidad no puede superar 150 caracteres')
];

const login = [
  body('correo')
    .trim()
    .notEmpty().withMessage('El correo es obligatorio')
    .isEmail().withMessage('El correo no tiene un formato válido'),
  body('contrasena')
    .isString().withMessage('La contraseña es obligatoria')
    .notEmpty().withMessage('La contraseña es obligatoria')
];

const forgotPassword = [
  body('correo')
    .trim()
    .notEmpty().withMessage('El correo es obligatorio')
    .isEmail().withMessage('El correo no tiene un formato válido')
];

const resetPassword = [
  body('correo')
    .trim()
    .notEmpty().withMessage('El correo es obligatorio')
    .isEmail().withMessage('El correo no tiene un formato válido'),
  body('token')
    .isString().withMessage('El token es obligatorio')
    .trim()
    .notEmpty().withMessage('El token es obligatorio'),
  body('nuevaContrasena')
    .isString().withMessage('La nueva contraseña es obligatoria')
    .isLength({ min: 6 }).withMessage('La nueva contraseña debe tener al menos 6 caracteres')
];

const changePassword = [
  body('contrasenaActual')
    .isString().withMessage('La contraseña actual es obligatoria')
    .notEmpty().withMessage('La contraseña actual es obligatoria'),
  body('nuevaContrasena')
    .isString().withMessage('La nueva contraseña es obligatoria')
    .isLength({ min: 6 }).withMessage('La nueva contraseña debe tener al menos 6 caracteres')
];

const refreshOrLogout = [
  body('refreshToken')
    .isString().withMessage('refreshToken es obligatorio')
    .trim()
    .notEmpty().withMessage('refreshToken es obligatorio')
];

module.exports = {
  register,
  login,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshOrLogout
};
