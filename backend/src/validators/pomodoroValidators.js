// ============================================
// VALIDADORES: SESIONES POMODORO
// ============================================

const { body, query } = require('express-validator');
const { OPTIONAL, idParam } = require('./common');

const PERIODOS = ['today', 'week', 'month'];

const create = [
  body('id_materia').optional(OPTIONAL).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('duracion_trabajo').optional(OPTIONAL).isInt({ min: 1, max: 600 }).withMessage('duracion_trabajo debe estar entre 1 y 600 minutos'),
  body('duracion_descanso').optional(OPTIONAL).isInt({ min: 0, max: 600 }).withMessage('duracion_descanso debe estar entre 0 y 600 minutos'),
  body('notas').optional({ nullable: true }).isString().withMessage('notas debe ser texto')
];

const update = [
  idParam(),
  body('ciclos_completados').optional(OPTIONAL).isInt({ min: 0 }).withMessage('ciclos_completados debe ser un entero >= 0'),
  body('tiempo_total_estudio').optional(OPTIONAL).isInt({ min: 0 }).withMessage('tiempo_total_estudio debe ser un entero >= 0'),
  body('notas').optional({ nullable: true }).isString().withMessage('notas debe ser texto')
];

const complete = [
  idParam(),
  body('ciclos_completados').optional(OPTIONAL).isInt({ min: 0 }).withMessage('ciclos_completados debe ser un entero >= 0'),
  body('tiempo_total_estudio').optional(OPTIONAL).isInt({ min: 0 }).withMessage('tiempo_total_estudio debe ser un entero >= 0')
];

const list = [
  query('id_materia').optional().isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  query('fecha_inicio').optional().isISO8601().withMessage('fecha_inicio no tiene un formato válido'),
  query('fecha_fin').optional().isISO8601().withMessage('fecha_fin no tiene un formato válido')
];

const stats = [
  query('periodo').optional().isIn(PERIODOS).withMessage(`periodo debe ser: ${PERIODOS.join(', ')}`)
];

const detail = [idParam()];

module.exports = { create, update, complete, list, stats, detail };
