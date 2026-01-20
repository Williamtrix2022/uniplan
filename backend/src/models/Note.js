// ============================================
// MODELO DE NOTAS
// ============================================

const { pool } = require('../config/database');

class Note {
  
  // Crear nueva nota
  static async create(noteData) {
    const { id_estudiante, id_materia, titulo, contenido, etiquetas, favorito } = noteData;
    
    const query = `
      INSERT INTO notas 
      (id_estudiante, id_materia, titulo, contenido, etiquetas, favorito)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia || null,
        titulo,
        contenido,
        etiquetas || null,
        favorito || false
      ]);
      
      return result.insertId;
    } catch (error) {
      throw error;
    }
  }

  // Obtener todas las notas de un estudiante
  static async findByStudent(id_estudiante, filters = {}) {
    let query = `
      SELECT n.*, m.nombre as materia_nombre, m.color as materia_color
      FROM notas n
      LEFT JOIN materias m ON n.id_materia = m.id
      WHERE n.id_estudiante = ? AND n.activo = TRUE
    `;
    
    const params = [id_estudiante];

    // Filtro por materia
    if (filters.id_materia) {
      query += ' AND n.id_materia = ?';
      params.push(filters.id_materia);
    }

    // Filtro por favoritos
    if (filters.favorito !== undefined) {
      query += ' AND n.favorito = ?';
      params.push(filters.favorito);
    }

    // Búsqueda por texto
    if (filters.search) {
      query += ' AND (n.titulo LIKE ? OR n.contenido LIKE ? OR n.etiquetas LIKE ?)';
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    query += ' ORDER BY n.fecha_actualizacion DESC';
    
    try {
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener nota por ID
  static async findById(id) {
    const query = `
      SELECT n.*, m.nombre as materia_nombre, m.color as materia_color
      FROM notas n
      LEFT JOIN materias m ON n.id_materia = m.id
      WHERE n.id = ? AND n.activo = TRUE
    `;
    
    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar nota
  static async update(id, noteData) {
    const { titulo, contenido, id_materia, etiquetas, favorito } = noteData;
    
    const query = `
      UPDATE notas 
      SET titulo = ?, contenido = ?, id_materia = ?, etiquetas = ?, favorito = ?
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [
        titulo, contenido, id_materia, etiquetas, favorito, id
      ]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Marcar/desmarcar como favorito
  static async toggleFavorite(id) {
    const query = `
      UPDATE notas 
      SET favorito = NOT favorito
      WHERE id = ? AND activo = TRUE
    `;
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Eliminar nota
  static async delete(id) {
    const query = 'UPDATE notas SET activo = FALSE WHERE id = ?';
    
    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Obtener notas favoritas
  static async getFavorites(id_estudiante) {
    const query = `
      SELECT n.*, m.nombre as materia_nombre, m.color as materia_color
      FROM notas n
      LEFT JOIN materias m ON n.id_materia = m.id
      WHERE n.id_estudiante = ? AND n.favorito = TRUE AND n.activo = TRUE
      ORDER BY n.fecha_actualizacion DESC
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener notas recientes
  static async getRecent(id_estudiante, limit = 10) {
    const query = `
      SELECT n.*, m.nombre as materia_nombre, m.color as materia_color
      FROM notas n
      LEFT JOIN materias m ON n.id_materia = m.id
      WHERE n.id_estudiante = ? AND n.activo = TRUE
      ORDER BY n.fecha_actualizacion DESC
      LIMIT ?
    `;
    
    try {
      const [rows] = await pool.execute(query, [id_estudiante, limit]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Estadísticas de notas
  static async getStats(id_estudiante) {
    const query = `
      SELECT 
        COUNT(*) as total_notas,
        SUM(CASE WHEN favorito = TRUE THEN 1 ELSE 0 END) as favoritas,
        COUNT(DISTINCT id_materia) as materias_con_notas,
        COUNT(DISTINCT DATE(fecha_creacion)) as dias_con_notas
      FROM notas 
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

module.exports = Note;