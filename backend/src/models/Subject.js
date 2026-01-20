// ============================================
// MODELO DE MATERIAS
// ============================================

const { pool } = require('../config/database');

class Subject {
  
  // Crear nueva materia
  static async create(subjectData) {
    const { id_estudiante, nombre, codigo, profesor, semestre, creditos, horario, color } = subjectData;
    
    const query = `
      INSERT INTO materias 
      (id_estudiante, nombre, codigo, profesor, semestre, creditos, horario, color)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        nombre,
        codigo || null,
        profesor || null,
        semestre || null,
        creditos || 3,
        horario || null,
        color || '#4CAF50'
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todas las materias de un estudiante
  static async findByStudent(id_estudiante) {
    const query = `
      SELECT * FROM materias 
      WHERE id_estudiante = ? AND activo = TRUE 
      ORDER BY nombre ASC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener materia por ID
  static async findById(id) {
    const query = 'SELECT * FROM materias WHERE id = ? AND activo = TRUE';
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar materia
  static async update(id, subjectData) {
    const { nombre, codigo, profesor, semestre, creditos, horario, color } = subjectData;
    
    const query = `
      UPDATE materias 
      SET nombre = ?, codigo = ?, profesor = ?, semestre = ?, 
          creditos = ?, horario = ?, color = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [
        nombre, codigo, profesor, semestre, creditos, horario, color, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar materia (soft delete)
  static async delete(id) {
    const query = 'UPDATE materias SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener estadísticas de materias por estudiante
  static async getStats(id_estudiante) {
    const query = `
      SELECT 
        COUNT(*) as total_materias,
        SUM(creditos) as total_creditos,
        COUNT(DISTINCT semestre) as semestres
      FROM materias 
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

module.exports = Subject;