// ============================================
// VALIDADORES: CALIFICACIONES
// ============================================

const { body } = require('express-validator');
const { OPTIONAL, idParam } = require('./common');

const TIPOS = ['parcial', 'taller', 'quiz', 'proyecto', 'laboratorio', 'final', 'otro'];

const create = [
  body('id_materia')
    .notEmpty().withMessage('id_materia es obligatorio')
    .isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('valor')
    .notEmpty().withMessage('valor es obligatorio')
    .isFloat({ min: 0, max: 5 }).withMessage('valor debe ser un número entre 0 y 5'),
  body('porcentaje')
    .notEmpty().withMessage('porcentaje es obligatorio')
    .isFloat({ min: 0, max: 100 }).withMessage('porcentaje debe ser un número entre 0 y 100'),
  body('tipo').optional(OPTIONAL).isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  body('descripcion').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('descripcion no puede superar 150 caracteres'),
  body('fecha_evaluacion').optional(OPTIONAL).isISO8601().withMessage('fecha_evaluacion no tiene un formato válido')
];

const update = [
  idParam(),
  body('valor').optional(OPTIONAL).isFloat({ min: 0, max: 5 }).withMessage('valor debe ser un número entre 0 y 5'),
  body('porcentaje').optional(OPTIONAL).isFloat({ min: 0, max: 100 }).withMessage('porcentaje debe ser un número entre 0 y 100'),
  body('tipo').optional(OPTIONAL).isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  body('descripcion').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('descripcion no puede superar 150 caracteres'),
  body('fecha_evaluacion').optional(OPTIONAL).isISO8601().withMessage('fecha_evaluacion no tiene un formato válido')
];

const detail = [idParam()];

module.exports = { create, update, detail };
