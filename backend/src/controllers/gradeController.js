// ============================================
// CONTROLADOR DE CALIFICACIONES
// ============================================

const Grade = require('../models/Grade');

const VALID_TYPES = ['parcial', 'taller', 'quiz', 'proyecto', 'laboratorio', 'final', 'otro'];
const PASSING_GRADE = 3.0;

// Determinar estado/color según el promedio
const getGradeStatus = (promedio) => {
  if (promedio === null) {
    return { estado: 'sin_calificaciones', color: 'gris' };
  }
  if (promedio < 3.0) {
    return { estado: 'en riesgo', color: 'rojo' };
  }
  if (promedio < 4.0) {
    return { estado: 'aprobado', color: 'amarillo' };
  }
  return { estado: 'aprobado', color: 'verde' };
};

// Crear calificación
const createGrade = async (req, res) => {
  try {
    const { id_materia, tipo, descripcion, valor, porcentaje, fecha_evaluacion } = req.body;
    const id_estudiante = req.user.id;

    if (!id_materia) {
      return res.status(400).json({
        success: false,
        message: 'id_materia es obligatorio'
      });
    }

    if (valor === undefined || valor === null || isNaN(valor) || valor < 0 || valor > 5) {
      return res.status(400).json({
        success: false,
        message: 'valor es obligatorio y debe ser un número entre 0 y 5'
      });
    }

    if (porcentaje === undefined || porcentaje === null || isNaN(porcentaje) || porcentaje < 0 || porcentaje > 100) {
      return res.status(400).json({
        success: false,
        message: 'porcentaje es obligatorio y debe ser un número entre 0 y 100'
      });
    }

    if (tipo && !VALID_TYPES.includes(tipo)) {
      return res.status(400).json({
        success: false,
        message: `Tipo inválido. Valores permitidos: ${VALID_TYPES.join(', ')}`
      });
    }

    const porcentajeAcumulado = await Grade.getPercentageSum(id_estudiante, id_materia);
    const porcentajeDisponible = 100 - porcentajeAcumulado;

    if (porcentaje > porcentajeDisponible) {
      return res.status(400).json({
        success: false,
        message: `El porcentaje acumulado para esta materia no puede superar 100%. Porcentaje actual: ${porcentajeAcumulado}%, disponible: ${porcentajeDisponible}%.`
      });
    }

    const grade = await Grade.create({
      id_estudiante,
      id_materia,
      tipo,
      descripcion,
      valor,
      porcentaje,
      fecha_evaluacion
    });

    res.status(201).json({
      success: true,
      message: 'Calificación creada exitosamente',
      data: grade
    });

  } catch (error) {
    console.error('Error en createGrade:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear calificación'
    });
  }
};

// Obtener todas las calificaciones del estudiante
const getMyGrades = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const grades = await Grade.findByStudent(id_estudiante);

    res.json({
      success: true,
      count: grades.length,
      data: grades
    });

  } catch (error) {
    console.error('Error en getMyGrades:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener calificaciones'
    });
  }
};

// Obtener una calificación por ID
const getGradeById = async (req, res) => {
  try {
    const { id } = req.params;
    const grade = await Grade.findById(id);

    if (!grade) {
      return res.status(404).json({
        success: false,
        message: 'Calificación no encontrada'
      });
    }

    if (grade.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta calificación'
      });
    }

    res.json({
      success: true,
      data: grade
    });

  } catch (error) {
    console.error('Error en getGradeById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener calificación'
    });
  }
};

// Obtener calificaciones de una materia
const getGradesBySubject = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { id } = req.params;

    const grades = await Grade.findBySubject(id_estudiante, id);

    res.json({
      success: true,
      count: grades.length,
      data: grades
    });

  } catch (error) {
    console.error('Error en getGradesBySubject:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener calificaciones de la materia'
    });
  }
};

// Actualizar calificación
const updateGrade = async (req, res) => {
  try {
    const { id } = req.params;
    const { tipo, descripcion, valor, porcentaje, fecha_evaluacion } = req.body;

    const grade = await Grade.findById(id);

    if (!grade) {
      return res.status(404).json({
        success: false,
        message: 'Calificación no encontrada'
      });
    }

    if (grade.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar esta calificación'
      });
    }

    if (tipo && !VALID_TYPES.includes(tipo)) {
      return res.status(400).json({
        success: false,
        message: `Tipo inválido. Valores permitidos: ${VALID_TYPES.join(', ')}`
      });
    }

    if (valor !== undefined && (isNaN(valor) || valor < 0 || valor > 5)) {
      return res.status(400).json({
        success: false,
        message: 'valor debe ser un número entre 0 y 5'
      });
    }

    if (porcentaje !== undefined && (isNaN(porcentaje) || porcentaje < 0 || porcentaje > 100)) {
      return res.status(400).json({
        success: false,
        message: 'porcentaje debe ser un número entre 0 y 100'
      });
    }

    if (porcentaje !== undefined) {
      const porcentajeAcumulado = await Grade.getPercentageSum(grade.id_estudiante, grade.id_materia, id);
      const porcentajeDisponible = 100 - porcentajeAcumulado;

      if (porcentaje > porcentajeDisponible) {
        return res.status(400).json({
          success: false,
          message: `El porcentaje acumulado para esta materia no puede superar 100%. Porcentaje actual: ${porcentajeAcumulado}%, disponible: ${porcentajeDisponible}%.`
        });
      }
    }

    await Grade.update(id, { tipo, descripcion, valor, porcentaje, fecha_evaluacion });
    const updated = await Grade.findById(id);

    res.json({
      success: true,
      message: 'Calificación actualizada exitosamente',
      data: updated
    });

  } catch (error) {
    console.error('Error en updateGrade:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar calificación'
    });
  }
};

// Eliminar calificación
const deleteGrade = async (req, res) => {
  try {
    const { id } = req.params;
    const grade = await Grade.findById(id);

    if (!grade) {
      return res.status(404).json({
        success: false,
        message: 'Calificación no encontrada'
      });
    }

    if (grade.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta calificación'
      });
    }

    await Grade.delete(id);

    res.json({
      success: true,
      message: 'Calificación eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteGrade:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar calificación'
    });
  }
};

// Resumen general: promedio general + promedio por materia (para dashboard)
const getSummary = async (req, res) => {
  try {
    const id_estudiante = req.user.id;

    const grades = await Grade.findByStudent(id_estudiante);

    // Agrupar por materia
    const subjectsMap = new Map();
    for (const grade of grades) {
      if (!subjectsMap.has(grade.id_materia)) {
        subjectsMap.set(grade.id_materia, {
          id_materia: grade.id_materia,
          materia_nombre: grade.materia_nombre,
          materia_color: grade.materia_color
        });
      }
    }

    const subjects = [];
    for (const subject of subjectsMap.values()) {
      const { promedio, porcentaje_acumulado } = await Grade.getSubjectAverage(id_estudiante, subject.id_materia);
      const { estado, color } = getGradeStatus(promedio);

      subjects.push({
        ...subject,
        promedio,
        porcentaje_acumulado,
        estado,
        color
      });
    }

    const promedioGeneral = await Grade.getGeneralAverage(id_estudiante);

    res.json({
      success: true,
      data: {
        promedio_general: promedioGeneral,
        materias_con_calificaciones: subjects.length,
        materias: subjects
      }
    });

  } catch (error) {
    console.error('Error en getSummary:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener resumen de calificaciones'
    });
  }
};

// Proyección de nota necesaria para una materia
const getSubjectProjection = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { id } = req.params;

    const projection = await Grade.getProjectedGrade(id_estudiante, id, PASSING_GRADE);

    res.json({
      success: true,
      data: projection
    });

  } catch (error) {
    console.error('Error en getSubjectProjection:', error);
    res.status(500).json({
      success: false,
      message: 'Error al calcular proyección de calificación'
    });
  }
};

module.exports = {
  createGrade,
  getMyGrades,
  getGradeById,
  getGradesBySubject,
  updateGrade,
  deleteGrade,
  getSummary,
  getSubjectProjection
};
