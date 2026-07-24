// ============================================
// MODELO DE TAREAS
// ============================================

const { pool } = require('../config/database');

class Task {
  
  // Crear nueva tarea
  static async create(taskData) {
    const { 
      id_estudiante, id_materia, titulo, descripcion, 
      fecha_entrega, prioridad, estado, recordatorio, es_proyecto
    } = taskData;
    
    const query = `
      INSERT INTO tareas 
      (id_estudiante, id_materia, titulo, descripcion, fecha_entrega, prioridad, estado, recordatorio, es_proyecto)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia || null,
        titulo,
        descripcion || null,
        fecha_entrega,
        prioridad || 'media',
        estado || 'pendiente',
        recordatorio || false,
        es_proyecto || false
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todas las tareas de un estudiante
  static async findByStudent(id_estudiante, filters = {}) {
    let query = `
      SELECT t.*, m.nombre as materia_nombre, m.color as materia_color
      FROM tareas t
      LEFT JOIN materias m ON t.id_materia = m.id
      WHERE t.id_estudiante = ? AND t.activo = TRUE
    `;
    
    const params = [id_estudiante];

    // Filtros opcionales
    if (filters.estado) {
      query += ' AND t.estado = ?';
      params.push(filters.estado);
    }

    if (filters.prioridad) {
      query += ' AND t.prioridad = ?';
      params.push(filters.prioridad);
    }

    if (filters.id_materia) {
      query += ' AND t.id_materia = ?';
      params.push(filters.id_materia);
    }

    if (filters.es_proyecto !== undefined) {
      query += ' AND t.es_proyecto = ?';
      params.push(filters.es_proyecto);
    }

    query += ' ORDER BY t.fecha_entrega ASC, t.prioridad DESC';
    
    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener tarea por ID
  static async findById(id) {
    const query = `
      SELECT t.*, m.nombre as materia_nombre, m.color as materia_color
      FROM tareas t
      LEFT JOIN materias m ON t.id_materia = m.id
      WHERE t.id = ? AND t.activo = TRUE
    `;
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar tarea
  static async update(id, taskData) {
    const { titulo, descripcion, fecha_entrega, prioridad, estado, id_materia, es_proyecto } = taskData;
    
    const query = `
      UPDATE tareas 
      SET titulo = ?, descripcion = ?, fecha_entrega = ?, 
          prioridad = ?, estado = ?, id_materia = ?, es_proyecto = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [
        titulo, descripcion, fecha_entrega, prioridad, estado, id_materia, es_proyecto || false, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Marcar/desmarcar tarea como completada
  static async setCompletion(id, completada) {
    const query = `
      UPDATE tareas
      SET completada = ?,
          estado = ?,
          fecha_completada = ?
      WHERE id = ? AND activo = TRUE
    `;

    const isCompleted = Boolean(completada);
    const estado = isCompleted ? 'completada' : 'pendiente';
    const fechaCompletada = isCompleted ? new Date() : null;

    try {
      const [result] = await pool.execute(query, [
        isCompleted,
        estado,
        fechaCompletada,
        id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar tarea
  static async delete(id) {
    const query = 'UPDATE tareas SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener tareas próximas (próximos 7 días)
  static async getUpcoming(id_estudiante) {
    const query = `
      SELECT t.*, m.nombre as materia_nombre, m.color as materia_color
      FROM tareas t
      LEFT JOIN materias m ON t.id_materia = m.id
      WHERE t.id_estudiante = ?
        AND t.activo = TRUE
        AND t.completada = FALSE
        AND t.fecha_entrega BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
      ORDER BY t.fecha_entrega ASC
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Estadísticas de tareas
  static async getStats(id_estudiante) {
    const query = `
      SELECT
        COUNT(*) as total_tareas,
        SUM(CASE WHEN completada = TRUE THEN 1 ELSE 0 END) as completadas,
        SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) as pendientes,
        SUM(CASE WHEN prioridad = 'alta' THEN 1 ELSE 0 END) as alta_prioridad
      FROM tareas
      WHERE id_estudiante = ? AND activo = TRUE
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows[0];
    } catch (error) {
      throw error;
    }
  }

  /**
   * Soft-delete de tareas antiguas (anteriores a N días respecto a hoy).
   * Diseñado para invocarse manualmente desde el script CLI `backend/scripts/cleanup-old-tasks.js`
   * porque el backend corre en hosting serverless (Vercel) y no soporta un worker/cron de larga vida.
   *
   *   - Solo tareas con `completada = TRUE` son elegibles (no tocamos pendientes).
   *   - Solo soft-delete (activo = FALSE); nunca hard-delete.
   *   - Acepta `dryRun: true` para contar candidatas sin mutar.
   *
   * @param {Object} opts
   *   - daysOld {number} obligatorio (>0). Antigüedad en días respecto a `fecha_entrega`.
   *   - dryRun {boolean} opcional. Si true, cuenta sin escribir.
   * @returns {Promise<{candidates: number, softDeleted: number, dryRun: boolean, daysOld: number}>}
   */
  static async cleanupOld(opts = {}) {
    const { daysOld, dryRun = false } = opts;

    if (!Number.isFinite(daysOld) || daysOld <= 0) {
      throw new Error('cleanupOld: daysOld debe ser un número positivo');
    }

    // MySQL DATE_ADD firma: DATE_ADD(NOW(), INTERVAL <días> DAY), con días negativos restando.
    // Lo negamos para apuntar a "hace N días" desde hoy.
    const sqlDays = -Math.trunc(daysOld);

    // 1) Conteo de candidatas (separado para reporte claro)
    const countQuery = `
      SELECT COUNT(*) AS total
      FROM tareas
      WHERE activo = TRUE
        AND completada = TRUE
        AND fecha_entrega <= DATE_ADD(CURDATE(), INTERVAL ? DAY)
    `;

    const [countRows] = await pool.execute(countQuery, [sqlDays]);
    const candidates = Number(countRows[0].total) || 0;

    if (dryRun || candidates === 0) {
      return { candidates, softDeleted: 0, dryRun: Boolean(dryRun), daysOld };
    }

    // 2) Soft-delete de esas candidatas
    const updateQuery = `
      UPDATE tareas
      SET activo = FALSE
      WHERE activo = TRUE
        AND completada = TRUE
        AND fecha_entrega <= DATE_ADD(CURDATE(), INTERVAL ? DAY)
    `;

    const [result] = await pool.execute(updateQuery, [sqlDays]);

    return {
      candidates,
      softDeleted: Number(result.affectedRows) || 0,
      dryRun: false,
      daysOld
    };
  }
}

module.exports = Task;
