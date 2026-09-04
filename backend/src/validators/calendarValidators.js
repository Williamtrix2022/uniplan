// ============================================
// VALIDADORES: CALENDARIO
// ============================================

const { body, query } = require('express-validator');
const { OPTIONAL, HHMM, HEX_COLOR, idParam } = require('./common');

const TIPOS = ['clase', 'examen', 'tarea', 'evento', 'otro'];

const camposComunes = () => [
  body('descripcion').optional({ nullable: true }).isString().withMessage('La descripción debe ser texto'),
  body('id_materia').optional(OPTIONAL).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('hora_inicio').optional(OPTIONAL).matches(HHMM).withMessage('hora_inicio debe tener formato HH:MM'),
  body('hora_fin').optional(OPTIONAL).matches(HHMM).withMessage('hora_fin debe tener formato HH:MM'),
  body('tipo').optional(OPTIONAL).isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  body('ubicacion').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('ubicacion no puede superar 150 caracteres'),
  body('recordatorio').optional({ nullable: true }).isBoolean().withMessage('recordatorio debe ser booleano'),
  body('minutos_antes_recordatorio').optional(OPTIONAL).isInt({ min: 0 }).withMessage('minutos_antes_recordatorio debe ser un entero >= 0'),
  body('todo_el_dia').optional({ nullable: true }).isBoolean().withMessage('todo_el_dia debe ser booleano'),
  body('color').optional(OPTIONAL).matches(HEX_COLOR).withMessage('color debe ser un hexadecimal tipo #RRGGBB')
];

const create = [
  body('titulo').trim().notEmpty().withMessage('El título es obligatorio')
    .isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('fecha').notEmpty().withMessage('La fecha es obligatoria')
    .isISO8601().withMessage('La fecha no tiene un formato válido'),
  ...camposComunes()
];

const update = [
  idParam(),
  body('titulo').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('fecha').optional(OPTIONAL).isISO8601().withMessage('La fecha no tiene un formato válido'),
  ...camposComunes()
];

const list = [
  query('tipo').optional().isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  query('id_materia').optional().isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  query('fecha').optional().isISO8601().withMessage('fecha no tiene un formato válido'),
  query('fecha_inicio').optional().isISO8601().withMessage('fecha_inicio no tiene un formato válido'),
  query('fecha_fin').optional().isISO8601().withMessage('fecha_fin no tiene un formato válido')
];

const month = [
  query('year').optional().isInt({ min: 2000, max: 2100 }).withMessage('year debe ser un año válido'),
  query('month').optional().isInt({ min: 1, max: 12 }).withMessage('month debe estar entre 1 y 12')
];

const detail = [idParam()];

module.exports = { create, update, list, month, detail };
