// ============================================
// MODELO DE HORARIOS
// ============================================

const { pool } = require('../config/database');

class Schedule {

  // Crear bloque de horario
  static async create(data) {
    const { id_estudiante, id_materia, dia, hora_inicio, hora_fin, aula } = data;

    const query = `
      INSERT INTO horarios (id_estudiante, id_materia, dia, hora_inicio, hora_fin, aula)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia,
        dia,
        hora_inicio,
        hora_fin,
        aula || null
      ]);
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener horarios de un estudiante con JOIN a materias
  static async findByStudent(id_estudiante, filters = {}) {
    let query = `
      SELECT h.*,
             m.nombre   AS materia_nombre,
             m.color    AS materia_color,
             m.profesor AS materia_profesor
      FROM horarios h
      INNER JOIN materias m ON h.id_materia = m.id
      WHERE h.id_estudiante = ? AND h.activo = TRUE
    `;

    const params = [id_estudiante];

    if (filters.dia) {
      query += ' AND h.dia = ?';
      params.push(filters.dia);
    }

    if (filters.id_materia) {
      query += ' AND h.id_materia = ?';
      params.push(filters.id_materia);
    }

    query += `
      ORDER BY FIELD(h.dia, 'lunes','martes','miercoles','jueves','viernes','sabado','domingo'),
               h.hora_inicio ASC
    `;

    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener un bloque por ID
  static async findById(id) {
    const query = `
      SELECT h.*,
             m.nombre   AS materia_nombre,
             m.color    AS materia_color,
             m.profesor AS materia_profesor
      FROM horarios h
      INNER JOIN materias m ON h.id_materia = m.id
      WHERE h.id = ? AND h.activo = TRUE
    `;

    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Obtener horarios de un día específico
  static async findByDay(id_estudiante, dia) {
    const query = `
      SELECT h.*,
             m.nombre   AS materia_nombre,
             m.color    AS materia_color,
             m.profesor AS materia_profesor
      FROM horarios h
      INNER JOIN materias m ON h.id_materia = m.id
      WHERE h.id_estudiante = ? AND h.dia = ? AND h.activo = TRUE
      ORDER BY h.hora_inicio ASC
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante, dia]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener horario semanal completo ordenado lunes→domingo
  static async findWeekSchedule(id_estudiante) {
    const query = `
      SELECT h.*,
             m.nombre   AS materia_nombre,
             m.color    AS materia_color,
             m.profesor AS materia_profesor
      FROM horarios h
      INNER JOIN materias m ON h.id_materia = m.id
      WHERE h.id_estudiante = ? AND h.activo = TRUE
      ORDER BY FIELD(h.dia, 'lunes','martes','miercoles','jueves','viernes','sabado','domingo'),
               h.hora_inicio ASC
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar bloque de horario
  static async update(id, data) {
    const { id_materia, dia, hora_inicio, hora_fin, aula } = data;

    const query = `
      UPDATE horarios
      SET id_materia = ?, dia = ?, hora_inicio = ?, hora_fin = ?, aula = ?
      WHERE id = ? AND activo = TRUE
    `;

    try {
      const [result] = await pool.execute(query, [
        id_materia, dia, hora_inicio, hora_fin, aula || null, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Soft delete
  static async delete(id) {
    const query = 'UPDATE horarios SET activo = FALSE WHERE id = ?';

    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Detectar conflictos de horario (superposición de bloques)
  // Lógica: dos bloques se superponen si hora_inicio_A < hora_fin_B AND hora_fin_A > hora_inicio_B
  static async detectConflicts(id_estudiante, dia, hora_inicio, hora_fin, excludeId = null) {
    let query = `
      SELECT h.*,
             m.nombre AS materia_nombre
      FROM horarios h
      INNER JOIN materias m ON h.id_materia = m.id
      WHERE h.id_estudiante = ?
        AND h.dia = ?
        AND h.activo = TRUE
        AND h.hora_inicio < ?
        AND h.hora_fin > ?
    `;

    const params = [id_estudiante, dia, hora_fin, hora_inicio];

    if (excludeId !== null) {
      query += ' AND h.id != ?';
      params.push(excludeId);
    }

    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Schedule;
