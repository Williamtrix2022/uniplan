// ============================================
// MIDDLEWARE: RESULTADO DE VALIDACIÓN
// ============================================

// Corre después de las cadenas de express-validator de cada ruta. Si hubo
// algún error, corta con 400 y el envelope estándar { success, message }
// más un array `errors` con el detalle campo por campo. Si no, sigue.

const { validationResult } = require('express-validator');

const handleValidation = (req, res, next) => {
  const result = validationResult(req);

  if (result.isEmpty()) {
    return next();
  }

  const errors = result.array({ onlyFirstError: true });

  return res.status(400).json({
    success: false,
    message: errors[0].msg,
    errors: errors.map((e) => ({
      campo: e.path,
      mensaje: e.msg
    }))
  });
};

module.exports = { handleValidation };
