// ============================================
// MODELO DE TAREAS
// ============================================

const { pool } = require('../config/database');

class Task {
  
  // Crear nueva tarea
  static async create(taskData) {
    const { 
      id_estudiante, id_materia, titulo, descripcion, 
      fecha_entrega, prioridad, estado, recordatorio 
    } = taskData;
    
    const query = `
      INSERT INTO tareas 
      (id_estudiante, id_materia, titulo, descripcion, fecha_entrega, prioridad, estado, recordatorio)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
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
        recordatorio || false
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
    const { titulo, descripcion, fecha_entrega, prioridad, estado, id_materia } = taskData;
    
    const query = `
      UPDATE tareas 
      SET titulo = ?, descripcion = ?, fecha_entrega = ?, 
          prioridad = ?, estado = ?, id_materia = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [
        titulo, descripcion, fecha_entrega, prioridad, estado, id_materia, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Marcar como completada
  static async markAsCompleted(id) {
    const query = `
      UPDATE tareas 
      SET completada = TRUE, estado = 'completada', fecha_completada = NOW()
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [id]);
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
}

module.exports = Task;