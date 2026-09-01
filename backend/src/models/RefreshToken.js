// ============================================
// MODELO DE REFRESH TOKENS
// ============================================
// Guarda solo el hash SHA-256 del refresh token. Soporta rotación
// (replaced_by) y revocación individual o masiva (revoked).

const { pool } = require('../config/database');

async function queryWithRetry(query, params = [], retries = 2) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await pool.execute(query, params);
    } catch (error) {
      const isConnectionError =
        error.code === 'ECONNRESET' ||
        error.code === 'PROTOCOL_CONNECTION_LOST' ||
        error.code === 'ETIMEDOUT' ||
        error.errno === -4077;
      if (isConnectionError && attempt < retries) {
        await new Promise((r) => setTimeout(r, 500));
        continue;
      }
      throw error;
    }
  }
}

class RefreshToken {
  static async ensureTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_estudiante INT NOT NULL,
        token_hash VARCHAR(255) NOT NULL,
        expires_at DATETIME NOT NULL,
        revoked TINYINT(1) NOT NULL DEFAULT 0,
        replaced_by INT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        revoked_at DATETIME NULL,
        UNIQUE KEY uniq_token_hash (token_hash),
        KEY idx_estudiante (id_estudiante),
        CONSTRAINT fk_refresh_tokens_estudiante
          FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    `;
    await queryWithRetry(query);
  }

  // Inserta un token nuevo. Devuelve su id.
  static async create(idEstudiante, tokenHash, expiresAt) {
    const [result] = await queryWithRetry(
      `INSERT INTO refresh_tokens (id_estudiante, token_hash, expires_at)
       VALUES (?, ?, ?)`,
      [idEstudiante, tokenHash, expiresAt]
    );
    return result.insertId;
  }

  // Busca por hash (esté o no revocado / vencido). null si no existe.
  static async findByHash(tokenHash) {
    const [rows] = await queryWithRetry(
      `SELECT * FROM refresh_tokens WHERE token_hash = ? LIMIT 1`,
      [tokenHash]
    );
    return rows[0] || null;
  }

  static isUsable(row) {
    return !!row && row.revoked === 0 && new Date(row.expires_at) > new Date();
  }

  static async revoke(id, replacedById = null) {
    await queryWithRetry(
      `UPDATE refresh_tokens
       SET revoked = 1, revoked_at = UTC_TIMESTAMP(), replaced_by = ?
       WHERE id = ?`,
      [replacedById, id]
    );
  }

  static async revokeAllForStudent(idEstudiante) {
    const [result] = await queryWithRetry(
      `UPDATE refresh_tokens
       SET revoked = 1, revoked_at = UTC_TIMESTAMP()
       WHERE id_estudiante = ? AND revoked = 0`,
      [idEstudiante]
    );
    return result.affectedRows;
  }
}

module.exports = RefreshToken;
