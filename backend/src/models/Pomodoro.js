// ============================================
// MODELO DE SESIONES POMODORO
// ============================================

const { pool } = require('../config/database');

class Pomodoro {
  
  // Crear nueva sesión Pomodoro
  static async create(pomodoroData) {
    const { 
      id_estudiante, id_materia, duracion_trabajo, 
      duracion_descanso, fecha_inicio, notas 
    } = pomodoroData;
    
    const query = `
      INSERT INTO sesiones_pomodoro 
      (id_estudiante, id_materia, duracion_trabajo, duracion_descanso, fecha_inicio, notas)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia || null,
        duracion_trabajo || 25,
        duracion_descanso || 5,
        fecha_inicio,
        notas || null
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todas las sesiones de un estudiante
  static async findByStudent(id_estudiante, filters = {}) {
    let query = `
      SELECT p.*, m.nombre as materia_nombre, m.color as materia_color
      FROM sesiones_pomodoro p
      LEFT JOIN materias m ON p.id_materia = m.id
      WHERE p.id_estudiante = ?
    `;
    
    const params = [id_estudiante];

    // Filtro por materia
    if (filters.id_materia) {
      query += ' AND p.id_materia = ?';
      params.push(filters.id_materia);
    }

    // Filtro por estado (completada o no)
    if (filters.completada !== undefined) {
      query += ' AND p.completada = ?';
      params.push(filters.completada);
    }

    // Filtro por rango de fechas
    if (filters.fecha_inicio && filters.fecha_fin) {
      query += ' AND DATE(p.fecha_inicio) BETWEEN ? AND ?';
      params.push(filters.fecha_inicio, filters.fecha_fin);
    }

    query += ' ORDER BY p.fecha_inicio DESC';
    
    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener sesión por ID
  static async findById(id) {
    const query = `
      SELECT p.*, m.nombre as materia_nombre, m.color as materia_color
      FROM sesiones_pomodoro p
      LEFT JOIN materias m ON p.id_materia = m.id
      WHERE p.id = ?
    `;
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar sesión Pomodoro
  static async update(id, pomodoroData) {
    const { 
      ciclos_completados, tiempo_total_estudio, 
      fecha_fin, completada, notas 
    } = pomodoroData;
    
    const query = `
      UPDATE sesiones_pomodoro 
      SET ciclos_completados = ?, tiempo_total_estudio = ?, 
          fecha_fin = ?, completada = ?, notas = ?
      WHERE id = ?
    `;
    
    try {
      const [result] = await pool.execute(query, [
        ciclos_completados, tiempo_total_estudio, 
        fecha_fin, completada, notas, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Finalizar sesión Pomodoro
  static async complete(id, ciclos_completados, tiempo_total_estudio) {
    const query = `
      UPDATE sesiones_pomodoro 
      SET ciclos_completados = ?, 
          tiempo_total_estudio = ?,
          fecha_fin = NOW(), 
          completada = TRUE
      WHERE id = ?
    `;
    
    try {
      const [result] = await pool.execute(query, [
        ciclos_completados, 
        tiempo_total_estudio, 
        id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar sesión
  static async delete(id) {
    const query = 'DELETE FROM sesiones_pomodoro WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener sesiones de hoy
  static async getToday(id_estudiante) {
    const query = `
      SELECT p.*, m.nombre as materia_nombre, m.color as materia_color
      FROM sesiones_pomodoro p
      LEFT JOIN materias m ON p.id_materia = m.id
      WHERE p.id_estudiante = ? 
        AND DATE(p.fecha_inicio) = CURDATE()
      ORDER BY p.fecha_inicio DESC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener estadísticas de Pomodoro
  static async getStats(id_estudiante, periodo = 'week') {
    let dateCondition;
    
    switch(periodo) {
      case 'today':
        dateCondition = 'DATE(fecha_inicio) = CURDATE()';
        break;
      case 'week':
        dateCondition = 'fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)';
        break;
      case 'month':
        dateCondition = 'fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
        break;
      default:
        dateCondition = 'fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)';
    }

    const query = `
      SELECT 
        COUNT(*) as total_sesiones,
        SUM(ciclos_completados) as total_ciclos,
        SUM(tiempo_total_estudio) as total_minutos,
        AVG(tiempo_total_estudio) as promedio_minutos,
        SUM(CASE WHEN completada = TRUE THEN 1 ELSE 0 END) as sesiones_completadas
      FROM sesiones_pomodoro 
      WHERE id_estudiante = ? AND ${dateCondition}
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows[0];
    } catch (error) {
      throw error;
    }
  }

  // Obtener sesiones por materia
  static async getBySubject(id_estudiante) {
    const query = `
      SELECT 
        m.id,
        m.nombre as materia,
        m.color,
        COUNT(p.id) as total_sesiones,
        SUM(p.tiempo_total_estudio) as total_minutos,
        SUM(p.ciclos_completados) as total_ciclos
      FROM sesiones_pomodoro p
      INNER JOIN materias m ON p.id_materia = m.id
      WHERE p.id_estudiante = ?
      GROUP BY m.id, m.nombre, m.color
      ORDER BY total_minutos DESC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener sesiones por día (últimos 7 días)
  static async getByDay(id_estudiante) {
    const query = `
      SELECT 
        DATE(fecha_inicio) as fecha,
        COUNT(*) as sesiones,
        SUM(tiempo_total_estudio) as minutos_estudiados,
        SUM(ciclos_completados) as ciclos
      FROM sesiones_pomodoro
      WHERE id_estudiante = ? 
        AND fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      GROUP BY DATE(fecha_inicio)
      ORDER BY fecha DESC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Pomodoro;