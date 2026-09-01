// ============================================
// VALIDADORES: NOTIFICACIONES
// ============================================

const { body, query } = require('express-validator');
const { OPTIONAL, HHMM, idParam } = require('./common');

const TIPOS = ['tarea', 'clase', 'evento', 'sistema', 'general'];

const list = [
  query('tipo').optional().isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  query('leida').optional().isIn(['true', 'false']).withMessage('leida debe ser "true" o "false"')
];

const create = [
  body('titulo')
    .trim()
    .notEmpty().withMessage('titulo es obligatorio')
    .isLength({ max: 150 }).withMessage('titulo no puede superar 150 caracteres'),
  body('tipo').optional(OPTIONAL).isIn(TIPOS).withMessage(`tipo debe ser: ${TIPOS.join(', ')}`),
  body('mensaje').optional({ nullable: true }).isString().withMessage('mensaje debe ser texto'),
  body('referencia_tipo').optional({ nullable: true }).isString().withMessage('referencia_tipo debe ser texto')
    .isLength({ max: 50 }).withMessage('referencia_tipo no puede superar 50 caracteres'),
  body('referencia_id').optional({ nullable: true }).isInt({ min: 1 }).withMessage('referencia_id debe ser un entero positivo'),
  body('fecha_programada').optional(OPTIONAL).isISO8601().withMessage('fecha_programada no tiene un formato válido')
];

const preferences = [
  body('notif_tareas').optional({ nullable: true }).isBoolean().withMessage('notif_tareas debe ser booleano'),
  body('notif_clases').optional({ nullable: true }).isBoolean().withMessage('notif_clases debe ser booleano'),
  body('notif_generales').optional({ nullable: true }).isBoolean().withMessage('notif_generales debe ser booleano'),
  body('sonido_activo').optional({ nullable: true }).isBoolean().withMessage('sonido_activo debe ser booleano'),
  body('minutos_antes_tarea').optional(OPTIONAL).isInt({ min: 0 }).withMessage('minutos_antes_tarea debe ser un entero >= 0'),
  body('minutos_antes_clase').optional(OPTIONAL).isInt({ min: 0 }).withMessage('minutos_antes_clase debe ser un entero >= 0'),
  body('hora_silencio_inicio').optional(OPTIONAL).matches(HHMM).withMessage('hora_silencio_inicio debe tener formato HH:MM'),
  body('hora_silencio_fin').optional(OPTIONAL).matches(HHMM).withMessage('hora_silencio_fin debe tener formato HH:MM')
];

const detail = [idParam()];

module.exports = { list, create, preferences, detail };
