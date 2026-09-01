// ============================================
// HELPER: queryWithRetry
// ============================================

const { pool } = require('../config/database');

/**
 * Ejecuta una query con reintento automático si falla por conexión perdida.
 * Retorna el mismo formato que pool.execute: [rows, fields]
 * MySQL remoto (alwaysdata) puede cerrar conexiones inactivas → ECONNRESET.
 */
async function queryWithRetry(query, params = [], retries = 2) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const result = await pool.execute(query, params);
      return result; // [rows, fields]
    } catch (error) {
      const isConnectionError =
        error.code === 'ECONNRESET' ||
        error.code === 'PROTOCOL_CONNECTION_LOST' ||
        error.code === 'ETIMEDOUT' ||
        error.errno === -4077;

      if (isConnectionError && attempt < retries) {
        console.log(`🔄 Reintentando query (intento ${attempt}/${retries - 1})...`);
        await new Promise(r => setTimeout(r, 500));
        continue;
      }
      throw error;
    }
  }
}

module.exports = queryWithRetry;
