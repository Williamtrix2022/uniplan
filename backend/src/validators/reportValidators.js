// ============================================
// VALIDADORES: REPORTES
// ============================================

const { body, query } = require('express-validator');

const MODULOS = [
  'tareas', 'materias', 'horario', 'calendario', 'pomodoro',
  'calificaciones', 'notificaciones', 'perfil', 'otro'
];

const create = [
  body('modulo').isIn(MODULOS).withMessage(`modulo debe ser: ${MODULOS.join(', ')}`),
  body('mensaje').isString().trim().isLength({ min: 10, max: 2000 })
    .withMessage('mensaje debe tener entre 10 y 2000 caracteres')
];

const list = [
  query('modulo').optional().isIn(MODULOS).withMessage(`modulo debe ser: ${MODULOS.join(', ')}`)
];

module.exports = { MODULOS, create, list };
