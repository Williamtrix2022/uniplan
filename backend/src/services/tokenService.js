// ============================================
// SERVICIO DE TOKENS (access + refresh)
// ============================================

const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Access token: corto (default 15m). Se valida stateless en authMiddleware.
// Refresh token: largo (default 30d). Es un secreto aleatorio opaco (no un
// JWT); en la DB se guarda solo su hash SHA-256, igual que password_resets.
const ACCESS_EXPIRE = process.env.JWT_ACCESS_EXPIRE || '15m';
const REFRESH_EXPIRE_DAYS = parseInt(process.env.JWT_REFRESH_EXPIRE_DAYS || '30', 10);

const signAccessToken = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_EXPIRE });

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

// Devuelve el token en claro (se manda al cliente una sola vez) + su hash y
// vencimiento (se guardan en la DB).
const generateRefreshToken = () => {
  const token = crypto.randomBytes(48).toString('hex');
  const expiresAt = new Date(Date.now() + REFRESH_EXPIRE_DAYS * 24 * 60 * 60 * 1000);
  return { token, tokenHash: hashToken(token), expiresAt };
};

module.exports = {
  signAccessToken,
  generateRefreshToken,
  hashToken,
  ACCESS_EXPIRE,
  REFRESH_EXPIRE_DAYS
};
