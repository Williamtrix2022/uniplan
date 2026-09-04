// ============================================
// VALIDADORES REUTILIZABLES
// ============================================

const { param } = require('express-validator');

// Regex de hora HH:MM o HH:MM:SS (columnas TIME de MySQL).
const HHMM = /^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/;

// Regex de color hexadecimal (#RGB o #RRGGBB) — columnas VARCHAR(7).
const HEX_COLOR = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;

// Opciones estándar para campos opcionales: se saltan si vienen null,
// undefined o string vacío (el cliente manda null para "sin valor").
const OPTIONAL = { nullable: true, checkFalsy: true };

// `:id` numérico y positivo, presente en casi todas las rutas de detalle.
const idParam = (name = 'id') =>
  param(name)
    .isInt({ min: 1 })
    .withMessage(`El parámetro ${name} debe ser un entero positivo`);

module.exports = {
  HHMM,
  HEX_COLOR,
  OPTIONAL,
  idParam
};
