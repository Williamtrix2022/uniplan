// ============================================
// VALIDADORES: ESTUDIANTES
// ============================================

const { body } = require('express-validator');
const { OPTIONAL, idParam } = require('./common');

const update = [
  idParam(),
  body('nombre').optional(OPTIONAL).trim().isLength({ max: 100 }).withMessage('El nombre no puede superar 100 caracteres'),
  body('carrera').optional({ nullable: true }).trim().isLength({ max: 100 }).withMessage('La carrera no puede superar 100 caracteres'),
  body('universidad').optional({ nullable: true }).trim().isLength({ max: 150 }).withMessage('La universidad no puede superar 150 caracteres')
];

const detail = [idParam()];

module.exports = { update, detail };
