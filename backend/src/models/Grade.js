// ============================================
// MODELO DE CALIFICACIONES
// ============================================

const { pool } = require('../config/database');

class Grade {

  // Crear nueva calificación
  static async create(data) {
    const { id_estudiante, id_materia, tipo, descripcion, valor, porcentaje, fecha_evaluacion } = data;

    const query = `
      INSERT INTO calificaciones
      (id_estudiante, id_materia, tipo, descripcion, valor, porcentaje, fecha_evaluacion)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    try {
      const [result] = await pool.execute(query, [
        id_estudiante,
        id_materia,
        tipo || 'otro',
        descripcion || null,
        valor,
        porcentaje,
        fecha_evaluacion || null
      ]);
      return {
        id: result.insertId,
        id_estudiante,
        id_materia,
        tipo: tipo || 'otro',
        descripcion: descripcion || null,
        valor,
        porcentaje,
        fecha_evaluacion: fecha_evaluacion || null
      };
    } catch (error) {
      throw error;
    }
  }

  // Obtener todas las calificaciones activas de un estudiante
  static async findByStudent(id_estudiante) {
    const query = `
      SELECT c.*,
             m.nombre AS materia_nombre,
             m.color  AS materia_color
      FROM calificaciones c
      INNER JOIN materias m ON c.id_materia = m.id
      WHERE c.id_estudiante = ? AND c.activo = TRUE
      ORDER BY c.fecha_evaluacion DESC, c.fecha_creacion DESC
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Obtener una calificación por ID
  static async findById(id) {
    const query = `
      SELECT c.*,
             m.nombre AS materia_nombre,
             m.color  AS materia_color
      FROM calificaciones c
      INNER JOIN materias m ON c.id_materia = m.id
      WHERE c.id = ? AND c.activo = TRUE
    `;

    try {
      const [rows] = await pool.execute(query, [id]);
      return rows[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Obtener calificaciones de una materia específica
  static async findBySubject(id_estudiante, id_materia) {
    const query = `
      SELECT c.*,
             m.nombre AS materia_nombre,
             m.color  AS materia_color
      FROM calificaciones c
      INNER JOIN materias m ON c.id_materia = m.id
      WHERE c.id_estudiante = ? AND c.id_materia = ? AND c.activo = TRUE
      ORDER BY c.fecha_evaluacion DESC, c.fecha_creacion DESC
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante, id_materia]);
      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Actualizar calificación (SET dinámico según campos permitidos)
  static async update(id, fields) {
    const allowedFields = ['tipo', 'descripcion', 'valor', 'porcentaje', 'fecha_evaluacion'];
    const setClauses = [];
    const params = [];

    for (const field of allowedFields) {
      if (fields[field] !== undefined) {
        setClauses.push(`${field} = ?`);
        params.push(fields[field]);
      }
    }

    if (setClauses.length === 0) {
      return false;
    }

    const query = `
      UPDATE calificaciones
      SET ${setClauses.join(', ')}
      WHERE id = ? AND activo = TRUE
    `;
    params.push(id);

    try {
      const [result] = await pool.execute(query, params);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Soft delete
  static async delete(id) {
    const query = 'UPDATE calificaciones SET activo = FALSE WHERE id = ?';

    try {
      const [result] = await pool.execute(query, [id]);
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Suma de porcentaje acumulado de una materia (activo = TRUE), opcionalmente
  // excluyendo una calificación puntual (para validar en updates)
  static async getPercentageSum(id_estudiante, id_materia, excludeId = null) {
    let query = `
      SELECT COALESCE(SUM(porcentaje), 0) AS total
      FROM calificaciones
      WHERE id_estudiante = ? AND id_materia = ? AND activo = TRUE
    `;
    const params = [id_estudiante, id_materia];

    if (excludeId !== null && excludeId !== undefined) {
      query += ' AND id != ?';
      params.push(excludeId);
    }

    try {
      const [rows] = await pool.execute(query, params);
      return Number(rows[0].total) || 0;
    } catch (error) {
      throw error;
    }
  }

  // Promedio ponderado de una materia: SUM(valor * porcentaje) / SUM(porcentaje)
  static async getSubjectAverage(id_estudiante, id_materia) {
    const query = `
      SELECT
        SUM(valor * porcentaje) AS suma_ponderada,
        SUM(porcentaje)         AS porcentaje_acumulado
      FROM calificaciones
      WHERE id_estudiante = ? AND id_materia = ? AND activo = TRUE
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante, id_materia]);
      const row = rows[0];

      const porcentajeAcumulado = Number(row.porcentaje_acumulado) || 0;

      if (!row.suma_ponderada || porcentajeAcumulado === 0) {
        return {
          promedio: null,
          porcentaje_acumulado: porcentajeAcumulado
        };
      }

      const sumaPonderada = Number(row.suma_ponderada);
      const promedio = sumaPonderada / porcentajeAcumulado;

      return {
        promedio,
        porcentaje_acumulado: porcentajeAcumulado
      };
    } catch (error) {
      throw error;
    }
  }

  // Promedio general: media simple de los promedios de las materias con calificaciones
  static async getGeneralAverage(id_estudiante) {
    const query = `
      SELECT id_materia, SUM(valor * porcentaje) / SUM(porcentaje) AS promedio_materia
      FROM calificaciones
      WHERE id_estudiante = ? AND activo = TRUE
      GROUP BY id_materia
      HAVING SUM(porcentaje) > 0
    `;

    try {
      const [rows] = await pool.execute(query, [id_estudiante]);

      if (rows.length === 0) {
        return null;
      }

      const suma = rows.reduce((acc, row) => acc + Number(row.promedio_materia), 0);
      return suma / rows.length;
    } catch (error) {
      throw error;
    }
  }

  // Nota necesaria en el porcentaje restante de una materia para alcanzar targetAverage
  static async getProjectedGrade(id_estudiante, id_materia, targetAverage = 3.0) {
    try {
      const { promedio, porcentaje_acumulado } = await Grade.getSubjectAverage(id_estudiante, id_materia);

      const porcentajeRestante = Math.max(0, 100 - porcentaje_acumulado);

      if (porcentaje_acumulado >= 100 || porcentajeRestante === 0) {
        return {
          promedio_actual: promedio,
          porcentaje_acumulado,
          porcentaje_restante: 0,
          nota_necesaria: null,
          aprobado: promedio !== null ? promedio >= targetAverage : false
        };
      }

      const sumaPonderadaActual = promedio !== null ? promedio * porcentaje_acumulado : 0;
      const notaNecesaria = (targetAverage * 100 - sumaPonderadaActual) / porcentajeRestante;

      // Si la nota necesaria en el porcentaje restante es <= 0, el estudiante
      // ya tiene el promedio garantizado (incluso sacando 0 en lo que falta),
      // aunque todavía queden evaluaciones pendientes por registrar.
      const aprobado = notaNecesaria <= 0;

      return {
        promedio_actual: promedio,
        porcentaje_acumulado,
        porcentaje_restante: porcentajeRestante,
        nota_necesaria: notaNecesaria,
        aprobado
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Grade;
