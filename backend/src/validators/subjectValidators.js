// ============================================
// VALIDADORES: MATERIAS
// ============================================

const { body } = require('express-validator');
const { OPTIONAL, HEX_COLOR, idParam } = require('./common');

const camposMateria = (nombreRequerido) => [
  nombreRequerido
    ? body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio')
        .isLength({ max: 100 }).withMessage('El nombre no puede superar 100 caracteres')
    : body('nombre').optional(OPTIONAL).trim()
        .isLength({ max: 100 }).withMessage('El nombre no puede superar 100 caracteres'),
  body('codigo').optional(OPTIONAL).trim().isLength({ max: 20 }).withMessage('El código no puede superar 20 caracteres'),
  body('profesor').optional(OPTIONAL).trim().isLength({ max: 100 }).withMessage('El profesor no puede superar 100 caracteres'),
  body('semestre').optional(OPTIONAL).isInt({ min: 0, max: 100 }).withMessage('semestre debe ser un entero entre 0 y 100'),
  body('creditos').optional(OPTIONAL).isInt({ min: 0, max: 100 }).withMessage('creditos debe ser un entero entre 0 y 100'),
  body('horario').optional({ nullable: true }).isString().withMessage('horario debe ser texto'),
  body('color').optional(OPTIONAL).matches(HEX_COLOR).withMessage('color debe ser un hexadecimal tipo #RRGGBB')
];

const create = camposMateria(true);
const update = [idParam(), ...camposMateria(false)];
const detail = [idParam()];

module.exports = { create, update, detail };
