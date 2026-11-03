// ============================================
// MODELO DE REPORTES (PROBLEMAS Y SUGERENCIAS)
// ============================================

const { pool } = require('../config/database');

class Report {

  // Crear nuevo reporte
  static async create({ id_estudiante, modulo, mensaje }) {
    const query = `
      INSERT INTO reportes (id_estudiante, modulo, mensaje)
      VALUES (?, ?, ?)
    `;

    try {
      const [result] = await pool.execute(query, [id_estudiante, modulo, mensaje]);
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener reporte por ID
  static async findById(id) {
    const query = 'SELECT * FROM reportes WHERE id = ?';

    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todos los reportes de un estudiante
  static async findByStudent(id_estudiante, filters = {}) {
    let query = 'SELECT * FROM reportes WHERE id_estudiante = ?';
    const params = [id_estudiante];

    if (filters.modulo) {
      query += ' AND modulo = ?';
      params.push(filters.modulo);
    }

    query += ' ORDER BY fecha_creacion DESC';

    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

}

module.exports = Report;
