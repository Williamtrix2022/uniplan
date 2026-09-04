// ============================================
// VALIDADORES: NOTAS (APUNTES)
// ============================================

const { body, query } = require('express-validator');
const { OPTIONAL, idParam } = require('./common');

const create = [
  body('titulo')
    .trim()
    .notEmpty().withMessage('El título es obligatorio')
    .isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('contenido')
    .isString().withMessage('El contenido es obligatorio')
    .trim()
    .notEmpty().withMessage('El contenido es obligatorio'),
  body('id_materia').optional(OPTIONAL).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('etiquetas').optional({ nullable: true }).isString().withMessage('etiquetas debe ser texto')
    .isLength({ max: 255 }).withMessage('etiquetas no puede superar 255 caracteres'),
  body('favorito').optional({ nullable: true }).isBoolean().withMessage('favorito debe ser booleano')
];

const update = [
  idParam(),
  body('titulo').optional(OPTIONAL).trim().isLength({ max: 150 }).withMessage('El título no puede superar 150 caracteres'),
  body('contenido').optional(OPTIONAL).isString().withMessage('El contenido debe ser texto'),
  body('id_materia').optional({ nullable: true }).isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo'),
  body('etiquetas').optional({ nullable: true }).isString().withMessage('etiquetas debe ser texto')
    .isLength({ max: 255 }).withMessage('etiquetas no puede superar 255 caracteres'),
  body('favorito').optional({ nullable: true }).isBoolean().withMessage('favorito debe ser booleano')
];

const list = [
  query('id_materia').optional().isInt({ min: 1 }).withMessage('id_materia debe ser un entero positivo')
];

const recent = [
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit debe estar entre 1 y 100')
];

const detail = [idParam()];

module.exports = { create, update, list, recent, detail };
