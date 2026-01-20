// ============================================
// MODELO DE CALENDARIO
// ============================================

const { pool } = require('../config/database');

class Calendar {
  
  // Crear nuevo evento
  static async create(eventData) {
    const { 
      id_estudiante, id_materia, titulo, descripcion, 
      fecha, hora_inicio, hora_fin, tipo, ubicacion, 
      recordatorio, minutos_antes_recordatorio, todo_el_dia, color 
    } = eventData;
    
    const query = `
      INSERT INTO eventos_calendario 
      (id_estudiante, id_materia, titulo, descripcion, fecha, hora_inicio, 
       hora_fin, tipo, ubicacion, recordatorio, minutos_antes_recordatorio, 
       todo_el_dia, color)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia || null,
        titulo,
        descripcion || null,
        fecha,
        hora_inicio || null,
        hora_fin || null,
        tipo || 'evento',
        ubicacion || null,
        recordatorio || false,
        minutos_antes_recordatorio || 30,
        todo_el_dia || false,
        color || '#2196F3'
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todos los eventos de un estudiante
  static async findByStudent(id_estudiante, filters = {}) {
    let query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id_estudiante = ? AND e.activo = TRUE
    `;
    
    const params = [id_estudiante];

    // Filtro por tipo
    if (filters.tipo) {
      query += ' AND e.tipo = ?';
      params.push(filters.tipo);
    }

    // Filtro por materia
    if (filters.id_materia) {
      query += ' AND e.id_materia = ?';
      params.push(filters.id_materia);
    }

    // Filtro por rango de fechas
    if (filters.fecha_inicio && filters.fecha_fin) {
      query += ' AND e.fecha BETWEEN ? AND ?';
      params.push(filters.fecha_inicio, filters.fecha_fin);
    }

    // Filtro por fecha específica
    if (filters.fecha) {
      query += ' AND e.fecha = ?';
      params.push(filters.fecha);
    }

    query += ' ORDER BY e.fecha ASC, e.hora_inicio ASC';
    
    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener evento por ID
  static async findById(id) {
    const query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id = ? AND e.activo = TRUE
    `;
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar evento
  static async update(id, eventData) {
    const { 
      titulo, descripcion, fecha, hora_inicio, hora_fin, 
      tipo, ubicacion, id_materia, recordatorio, 
      minutos_antes_recordatorio, todo_el_dia, color 
    } = eventData;
    
    const query = `
      UPDATE eventos_calendario 
      SET titulo = ?, descripcion = ?, fecha = ?, hora_inicio = ?, 
          hora_fin = ?, tipo = ?, ubicacion = ?, id_materia = ?,
          recordatorio = ?, minutos_antes_recordatorio = ?, 
          todo_el_dia = ?, color = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [
        titulo, descripcion, fecha, hora_inicio, hora_fin, 
        tipo, ubicacion, id_materia, recordatorio, 
        minutos_antes_recordatorio, todo_el_dia, color, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar evento
  static async delete(id) {
    const query = 'UPDATE eventos_calendario SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener eventos del día
  static async getToday(id_estudiante) {
    const query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id_estudiante = ? 
        AND e.fecha = CURDATE()
        AND e.activo = TRUE
      ORDER BY e.hora_inicio ASC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener eventos de la semana
  static async getWeek(id_estudiante) {
    const query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id_estudiante = ? 
        AND e.fecha BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
        AND e.activo = TRUE
      ORDER BY e.fecha ASC, e.hora_inicio ASC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener eventos del mes
  static async getMonth(id_estudiante, year, month) {
    const query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id_estudiante = ? 
        AND YEAR(e.fecha) = ? 
        AND MONTH(e.fecha) = ?
        AND e.activo = TRUE
      ORDER BY e.fecha ASC, e.hora_inicio ASC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante, year, month]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener próximos eventos con recordatorio
  static async getUpcomingWithReminder(id_estudiante) {
    const query = `
      SELECT e.*, m.nombre as materia_nombre, m.color as materia_color
      FROM eventos_calendario e
      LEFT JOIN materias m ON e.id_materia = m.id
      WHERE e.id_estudiante = ? 
        AND e.recordatorio = TRUE
        AND e.fecha >= CURDATE()
        AND e.activo = TRUE
      ORDER BY e.fecha ASC, e.hora_inicio ASC
      LIMIT 10
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Estadísticas del calendario
  static async getStats(id_estudiante) {
    const query = `
      SELECT 
        COUNT(*) as total_eventos,
        SUM(CASE WHEN tipo = 'clase' THEN 1 ELSE 0 END) as clases,
        SUM(CASE WHEN tipo = 'examen' THEN 1 ELSE 0 END) as examenes,
        SUM(CASE WHEN tipo = 'tarea' THEN 1 ELSE 0 END) as entregas,
        SUM(CASE WHEN fecha = CURDATE() THEN 1 ELSE 0 END) as eventos_hoy,
        SUM(CASE WHEN fecha BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as eventos_semana
      FROM eventos_calendario 
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

module.exports = Calendar;