// ============================================
// MIDDLEWARE: SANEAR RESPUESTAS DE ERROR
// ============================================

// Varios controladores incluyen `error: error.message` (y a veces el stack)
// en las respuestas 5xx. Eso filtra al cliente rutas de archivos, fragmentos
// de SQL y versiones de librerías. El error real ya queda registrado del lado
// del servidor vía console.error, así que acá sólo se poda del cuerpo que
// llega al cliente.
//
// En desarrollo se deja pasar tal cual para no perder detalle al depurar.
module.exports = function sanitizeErrorResponse(req, res, next) {
  if (process.env.NODE_ENV === 'development') {
    return next();
  }

  const originalJson = res.json.bind(res);

  res.json = (body) => {
    if (body && typeof body === 'object' && res.statusCode >= 500) {
      const { error, stack, ...safe } = body;
      return originalJson(safe);
    }
    return originalJson(body);
  };

  next();
};
