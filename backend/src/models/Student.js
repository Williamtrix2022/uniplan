// ============================================
// MODELO DE ESTUDIANTE
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

class Student {
  
  // Crear un nuevo estudiante
  static async create(studentData) {
    const { nombre, correo, contrasena, carrera, universidad } = studentData;
    
    const query = `
      INSERT INTO estudiantes (nombre, correo, contrasena, carrera, universidad)
      VALUES (?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        nombre, 
        correo, 
        contrasena, 
        carrera, 
        universidad || 'Universidad de Córdoba'
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Buscar estudiante por correo
  static async findByEmail(correo) {
    const query = 'SELECT * FROM estudiantes WHERE correo = ? AND activo = TRUE';
    
    try {
      const [rows] = await queryWithRetry(query, [correo]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Buscar estudiante por ID
  static async findById(id) {
    const query = 'SELECT id, nombre, correo, carrera, universidad, fecha_registro FROM estudiantes WHERE id = ? AND activo = TRUE';
    
    try {
      const [rows] = await queryWithRetry(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todos los estudiantes
  static async findAll() {
    const query = 'SELECT id, nombre, correo, carrera, universidad, fecha_registro FROM estudiantes WHERE activo = TRUE';
    
    try {
      const [rows] = await queryWithRetry(query);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar estudiante
  static async update(id, studentData) {
    const { nombre, carrera, universidad } = studentData;
    
    const query = `
      UPDATE estudiantes 
      SET nombre = ?, carrera = ?, universidad = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await queryWithRetry(query, [nombre, carrera, universidad, id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar estudiante (soft delete)
  static async delete(id) {
    const query = 'UPDATE estudiantes SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await queryWithRetry(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Crear tabla de recuperación de contraseña si no existe
  static async ensurePasswordResetTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS password_resets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        student_id INT NOT NULL,
        token_hash VARCHAR(255) NOT NULL,
        expires_at DATETIME NOT NULL,
        used TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        used_at DATETIME NULL,
        INDEX idx_token_hash (token_hash),
        INDEX idx_student_id (student_id),
        CONSTRAINT fk_password_resets_student
          FOREIGN KEY (student_id) REFERENCES estudiantes(id)
          ON DELETE CASCADE
      )
    `;

    try {
      await queryWithRetry(query);
    } catch (error) {
      throw error;
    }
  }

  // Guardar token de recuperación (invalidando anteriores activos)
  static async savePasswordResetToken(studentId, tokenHash, expiresAt) {
    const invalidateQuery = `
      UPDATE password_resets
      SET used = 1, used_at = NOW()
      WHERE student_id = ? AND used = 0
    `;

    const insertQuery = `
      INSERT INTO password_resets (student_id, token_hash, expires_at)
      VALUES (?, ?, ?)
    `;

    try {
      await queryWithRetry(invalidateQuery, [studentId]);
      const [result] = await pool.execute(insertQuery, [studentId, tokenHash, expiresAt]);
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Buscar token válido por hash
  static async findValidPasswordResetByHash(tokenHash) {
    const query = `
      SELECT pr.id, pr.student_id, pr.expires_at, pr.used, s.activo
      FROM password_resets pr
      INNER JOIN estudiantes s ON s.id = pr.student_id
      WHERE pr.token_hash = ?
        AND pr.used = 0
        AND pr.expires_at > NOW()
        AND s.activo = TRUE
      LIMIT 1
    `;

    try {
      const [rows] = await queryWithRetry(query, [tokenHash]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Marcar token como usado
  static async markPasswordResetAsUsed(resetId) {
    const query = `
      UPDATE password_resets
      SET used = 1, used_at = NOW()
      WHERE id = ?
    `;

    try {
      const [result] = await queryWithRetry(query, [resetId]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar contraseña del estudiante
  static async updatePassword(studentId, hashedPassword) {
    const query = `
      UPDATE estudiantes
      SET contrasena = ?
      WHERE id = ? AND activo = TRUE
    `;

    try {
      const [result] = await queryWithRetry(query, [hashedPassword, studentId]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Student;
