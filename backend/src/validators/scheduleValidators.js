// ============================================
// VALIDADORES: HORARIOS
// ============================================

const { body, query, param } = require('express-validator');
const { OPTIONAL, HHMM, idParam } = require('./common');

const DIAS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

const create = [
  body('id_materia')
    .notEmpty().withMessage('id_materia es obligatorio')
    .isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('dia')
    .notEmpty().withMessage('dia es obligatorio')
    .isIn(DIAS).withMessage(`dia debe ser: ${DIAS.join(', ')}`),
  body('hora_inicio')
    .notEmpty().withMessage('hora_inicio es obligatoria')
    .matches(HHMM).withMessage('hora_inicio debe tener formato HH:MM'),
  body('hora_fin')
    .notEmpty().withMessage('hora_fin es obligatoria')
    .matches(HHMM).withMessage('hora_fin debe tener formato HH:MM'),
  body('aula').optional(OPTIONAL).trim().isLength({ max: 100 }).withMessage('aula no puede superar 100 caracteres'),
  body('force').optional({ nullable: true }).isBoolean().withMessage('force debe ser booleano')
];

const update = [
  idParam(),
  body('id_materia').optional(OPTIONAL).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('dia').optional(OPTIONAL).isIn(DIAS).withMessage(`dia debe ser: ${DIAS.join(', ')}`),
  body('hora_inicio').optional(OPTIONAL).matches(HHMM).withMessage('hora_inicio debe tener formato HH:MM'),
  body('hora_fin').optional(OPTIONAL).matches(HHMM).withMessage('hora_fin debe tener formato HH:MM'),
  body('aula').optional(OPTIONAL).trim().isLength({ max: 100 }).withMessage('aula no puede superar 100 caracteres'),
  body('force').optional({ nullable: true }).isBoolean().withMessage('force debe ser booleano')
];

const list = [
  query('dia').optional().isIn(DIAS).withMessage(`dia debe ser: ${DIAS.join(', ')}`),
  query('id_materia').optional().isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo')
];

const byDay = [
  param('dia').isIn(DIAS).withMessage(`dia debe ser: ${DIAS.join(', ')}`)
];

const detail = [idParam()];

module.exports = { create, update, list, byDay, detail };
