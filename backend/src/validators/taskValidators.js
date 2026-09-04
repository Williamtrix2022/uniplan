// ============================================
// VALIDADORES: TAREAS
// ============================================

const { body, query } = require('express-validator');
const { OPTIONAL, idParam } = require('./common');

const PRIORIDADES = ['baja', 'media', 'alta'];
const ESTADOS = ['pendiente', 'en_progreso', 'completada'];

const create = [
  body('titulo')
    .trim()
    .notEmpty().withMessage('El título es obligatorio')
    .isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('fecha_entrega')
    .notEmpty().withMessage('La fecha de entrega es obligatoria')
    .isISO8601().withMessage('La fecha de entrega no tiene un formato válido'),
  body('descripcion').optional(OPTIONAL).isString().withMessage('La descripción debe ser texto'),
  body('id_materia').optional(OPTIONAL).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('prioridad').optional(OPTIONAL).isIn(PRIORIDADES).withMessage(`prioridad debe ser: ${PRIORIDADES.join(', ')}`),
  body('estado').optional(OPTIONAL).isIn(ESTADOS).withMessage(`estado debe ser: ${ESTADOS.join(', ')}`),
  body('recordatorio').optional({ nullable: true }).isBoolean().withMessage('recordatorio debe ser booleano'),
  body('es_proyecto').optional({ nullable: true }).isBoolean().withMessage('es_proyecto debe ser booleano')
];

const update = [
  idParam(),
  body('titulo').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('fecha_entrega').optional(OPTIONAL).isISO8601().withMessage('La fecha de entrega no tiene un formato válido'),
  body('descripcion').optional({ nullable: true }).isString().withMessage('La descripción debe ser texto'),
  body('id_materia').optional({ nullable: true }).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('prioridad').optional(OPTIONAL).isIn(PRIORIDADES).withMessage(`prioridad debe ser: ${PRIORIDADES.join(', ')}`),
  body('estado').optional(OPTIONAL).isIn(ESTADOS).withMessage(`estado debe ser: ${ESTADOS.join(', ')}`),
  body('es_proyecto').optional({ nullable: true }).isBoolean().withMessage('es_proyecto debe ser booleano')
];

const toggle = [
  idParam(),
  body('completada').optional({ nullable: true }).isBoolean().withMessage('completada debe ser booleano')
];

const list = [
  query('estado').optional().isIn(ESTADOS).withMessage(`estado debe ser: ${ESTADOS.join(', ')}`),
  query('prioridad').optional().isIn(PRIORIDADES).withMessage(`prioridad debe ser: ${PRIORIDADES.join(', ')}`),
  query('id_materia').optional().isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo')
];

const detail = [idParam()];

module.exports = { create, update, toggle, list, detail };
