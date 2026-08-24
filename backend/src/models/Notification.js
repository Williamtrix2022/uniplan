// ============================================
// MODELO DE NOTIFICACIONES
// ============================================

const { pool } = require('../config/database');

/**
 * Ejecuta una query con reintento automático si falla por conexión perdida.
 * Retorna el mismo formato que pool.execute: [rows, fields]
 * MySQL remoto (alwaysdata) puede cerrar conexiones inactivas → ECONNRESET.
 * (Réplica del helper privado en Student.js — no está exportado desde ahí.)
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

const DEFAULT_PREFERENCES = {
  notif_tareas: true,
  notif_clases: true,
  notif_generales: true,
  minutos_antes_tarea: 60,
  minutos_antes_clase: 30,
  sonido_activo: true,
  hora_silencio_inicio: null,
  hora_silencio_fin: null
};

class Notification {

  // Crear las tablas del módulo de notificaciones si no existen
  // (mismo patrón que Student.ensurePasswordResetTable, seguro de llamar repetidas veces)
  static async ensureTables() {
    const notificacionesQuery = `
      CREATE TABLE IF NOT EXISTS notificaciones (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_estudiante INT NOT NULL,
        tipo ENUM('tarea','clase','sistema','general') NOT NULL DEFAULT 'general',
        titulo VARCHAR(150) NOT NULL,
        mensaje TEXT NULL,
        leida BOOLEAN DEFAULT FALSE,
        referencia_tipo VARCHAR(50) NULL,
        referencia_id INT NULL,
        fecha_programada DATETIME NULL,
        activo BOOLEAN DEFAULT TRUE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE,
        INDEX idx_estudiante (id_estudiante),
        INDEX idx_leida (leida)
      )
    `;

    const preferenciasQuery = `
      CREATE TABLE IF NOT EXISTS preferencias_notificacion (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_estudiante INT NOT NULL UNIQUE,
        notif_tareas BOOLEAN DEFAULT TRUE,
        notif_clases BOOLEAN DEFAULT TRUE,
        notif_generales BOOLEAN DEFAULT TRUE,
        minutos_antes_tarea INT DEFAULT 60,
        minutos_antes_clase INT DEFAULT 30,
        sonido_activo BOOLEAN DEFAULT TRUE,
        hora_silencio_inicio TIME NULL,
        hora_silencio_fin TIME NULL,
        activo BOOLEAN DEFAULT TRUE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE
      )
    `;

    try {
      await queryWithRetry(notificacionesQuery);
      await queryWithRetry(preferenciasQuery);
    } catch (error) {
      throw error;
    }
  }

  // Crear nueva notificación
  static async create(data) {
    const {
      id_estudiante,
      tipo,
      titulo,
      mensaje,
      referencia_tipo,
      referencia_id,
      fecha_programada
    } = data;

    const query = `
      INSERT INTO notificaciones
      (id_estudiante, tipo, titulo, mensaje, referencia_tipo, referencia_id, fecha_programada)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    try {
      const [result] = await queryWithRetry(query, [
        id_estudiante,
        tipo || 'general',
        titulo,
        mensaje || null,
        referencia_tipo || null,
        referencia_id || null,
        fecha_programada || null
      ]);

      return {
        id: result.insertId,
        id_estudiante,
        tipo: tipo || 'general',
        titulo,
        mensaje: mensaje || null,
        leida: false,
        referencia_tipo: referencia_tipo || null,
        referencia_id: referencia_id || null,
        fecha_programada: fecha_programada || null
      };
    } catch (error) {
      throw error;
    }
  }

  // Obtener notificaciones de un estudiante, con filtros opcionales
  static async findByStudent(id_estudiante, filters = {}) {
    const { tipo, leida } = filters;

    let query = `
      SELECT *
      FROM notificaciones
      WHERE id_estudiante = ? AND activo = TRUE
        AND (fecha_programada IS NULL OR fecha_programada <= NOW())
    `;
    const params = [id_estudiante];

    if (tipo !== undefined) {
      query += ' AND tipo = ?';
      params.push(tipo);
    }

    if (leida !== undefined) {
      query += ' AND leida = ?';
      params.push(leida ? 1 : 0);
    }

    query += ' ORDER BY fecha_creacion DESC';

    try {
      const [rows] = await queryWithRetry(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener una notificación por ID (sin filtrar por dueño — la ownership la valida el controller)
  static async findById(id) {
    const query = `
      SELECT *
      FROM notificaciones
      WHERE id = ? AND activo = TRUE
    `;

    try {
      const [rows] = await queryWithRetry(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Contar notificaciones no leídas
  static async getUnreadCount(id_estudiante) {
    const query = `
      SELECT COUNT(*) AS total
      FROM notificaciones
      WHERE id_estudiante = ? AND leida = FALSE AND activo = TRUE
        AND (fecha_programada IS NULL OR fecha_programada <= NOW())
    `;

    try {
      const [rows] = await queryWithRetry(query, [id_estudiante]);
      return Number(rows[0].total) || 0;
    } catch (error) {
      throw error;
    }
  }

  // Marcar una notificación como leída, escopeada al dueño
  static async markAsRead(id, id_estudiante) {
    const query = `
      UPDATE notificaciones
      SET leida = TRUE
      WHERE id = ? AND id_estudiante = ? AND activo = TRUE
    `;

    try {
      const [result] = await queryWithRetry(query, [id, id_estudiante]);
      if (result.affectedRows === 0) {
        return null;
      }
      return Notification.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Marcar todas las notificaciones de un estudiante como leídas
  static async markAllAsRead(id_estudiante) {
    const query = `
      UPDATE notificaciones
      SET leida = TRUE
      WHERE id_estudiante = ? AND leida = FALSE AND activo = TRUE
    `;

    try {
      const [result] = await queryWithRetry(query, [id_estudiante]);
      return result.affectedRows;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar (soft delete) una notificación, escopeada al dueño
  static async remove(id, id_estudiante) {
    const query = `
      UPDATE notificaciones
      SET activo = FALSE
      WHERE id = ? AND id_estudiante = ? AND activo = TRUE
    `;

    try {
      const [result] = await queryWithRetry(query, [id, id_estudiante]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener preferencias de notificación; si no existen, crea una fila por defecto primero
  static async getPreferences(id_estudiante) {
    const selectQuery = `
      SELECT *
      FROM preferencias_notificacion
      WHERE id_estudiante = ? AND activo = TRUE
    `;

    try {
      const [rows] = await queryWithRetry(selectQuery, [id_estudiante]);

      if (rows[0]) {
        return rows[0];
      }

      const insertQuery = `
        INSERT INTO preferencias_notificacion
        (id_estudiante, notif_tareas, notif_clases, notif_generales,
         minutos_antes_tarea, minutos_antes_clase, sonido_activo,
         hora_silencio_inicio, hora_silencio_fin)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      try {
        await queryWithRetry(insertQuery, [
          id_estudiante,
          DEFAULT_PREFERENCES.notif_tareas,
          DEFAULT_PREFERENCES.notif_clases,
          DEFAULT_PREFERENCES.notif_generales,
          DEFAULT_PREFERENCES.minutos_antes_tarea,
          DEFAULT_PREFERENCES.minutos_antes_clase,
          DEFAULT_PREFERENCES.sonido_activo,
          DEFAULT_PREFERENCES.hora_silencio_inicio,
          DEFAULT_PREFERENCES.hora_silencio_fin
        ]);
      } catch (insertError) {
        // Condición de carrera: otra request concurrente para el mismo
        // estudiante ya insertó la fila por defecto entre nuestro SELECT y
        // este INSERT (UNIQUE en id_estudiante). En vez de propagar el 500,
        // se asume que esa fila ya existe y se re-consulta.
        if (insertError.code !== 'ER_DUP_ENTRY') {
          throw insertError;
        }
      }

      const [newRows] = await queryWithRetry(selectQuery, [id_estudiante]);
      return newRows[0];
    } catch (error) {
      throw error;
    }
  }

  // Actualizar preferencias (SET dinámico según campos permitidos)
  static async updatePreferences(id_estudiante, fields) {
    // Asegura que exista una fila antes de actualizar (evita 0 affectedRows silencioso)
    await Notification.getPreferences(id_estudiante);

    const allowedFields = [
      'notif_tareas',
      'notif_clases',
      'notif_generales',
      'minutos_antes_tarea',
      'minutos_antes_clase',
      'sonido_activo',
      'hora_silencio_inicio',
      'hora_silencio_fin'
    ];

    const setClauses = [];
    const params = [];

    for (const field of allowedFields) {
      if (fields[field] !== undefined) {
        setClauses.push(`${field} = ?`);
        params.push(fields[field]);
      }
    }

    if (setClauses.length === 0) {
      return Notification.getPreferences(id_estudiante);
    }

    const query = `
      UPDATE preferencias_notificacion
      SET ${setClauses.join(', ')}
      WHERE id_estudiante = ? AND activo = TRUE
    `;
    params.push(id_estudiante);

    try {
      await queryWithRetry(query, params);
      return Notification.getPreferences(id_estudiante);
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Notification;
