// ============================================
// MIDDLEWARE DE RATE LIMITING (AUTENTICACIÓN)
// ============================================

const rateLimit = require('express-rate-limit');

// Respuesta uniforme para intentos bloqueados, siguiendo el mismo formato
// de error ({ success, message }) que usa el resto de la API.
const rateLimitHandler = (req, res) => {
  res.status(429).json({
    success: false,
    message: 'Demasiados intentos. Intentá de nuevo en unos minutos.'
  });
};

// NOTA: este backend corre en funciones serverless de Vercel (ver
// comentarios de backend/src/config/database.js y el header de
// mobile/lib/services/local_notification_service.dart), por lo que el
// store en memoria por defecto de express-rate-limit es "best effort":
// cada lambda tiene su propia memoria y un cold start reinicia el
// contador. Cuando se agregue infraestructura persistente, este store
// debería reemplazarse por uno compartido (ej. Redis con
// rate-limit-redis) para que el límite se aplique de forma consistente
// entre invocaciones.

// Limita /register y /login: 10 intentos cada 15 minutos por IP
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler
});

// Limita /forgot-password y /reset-password: 5 intentos cada 15 minutos
// por IP (más estricto porque el OTP de 6 dígitos es fuerza-bruteable)
const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler
});

module.exports = {
  authLimiter,
  resetLimiter
};
