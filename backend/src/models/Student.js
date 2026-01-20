// ============================================
// MODELO DE ESTUDIANTE
// ============================================

const { pool } = require('../config/database');

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
      const [rows] = await pool.execute(query, [correo]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Buscar estudiante por ID
  static async findById(id) {
    const query = 'SELECT id, nombre, correo, carrera, universidad, fecha_registro FROM estudiantes WHERE id = ? AND activo = TRUE';
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todos los estudiantes
  static async findAll() {
    const query = 'SELECT id, nombre, correo, carrera, universidad, fecha_registro FROM estudiantes WHERE activo = TRUE';
    
    try {
      const [rows] = await pool.execute(query);
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
      const [result] = await pool.execute(query, [nombre, carrera, universidad, id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar estudiante (soft delete)
  static async delete(id) {
    const query = 'UPDATE estudiantes SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Student;