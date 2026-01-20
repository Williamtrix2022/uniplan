// ============================================
// CONTROLADOR DE MATERIAS
// ============================================

const Subject = require('../models/Subject');

// Crear nueva materia
const createSubject = async (req, res) => {
  try {
    const { nombre, codigo, profesor, semestre, creditos, horario, color } = req.body;
    const id_estudiante = req.user.id;

    // Validación
    if (!nombre) {
      return res.status(400).json({
        success: false,
        message: 'El nombre de la materia es obligatorio'
      });
    }

    const subjectId = await Subject.create({
      id_estudiante,
      nombre,
      codigo,
      profesor,
      semestre,
      creditos,
      horario,
      color
    });

    const subject = await Subject.findById(subjectId);

    res.status(201).json({
      success: true,
      message: 'Materia creada exitosamente',
      data: subject
    });

  } catch (error) {
    console.error('Error en createSubject:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear materia',
      error: error.message
    });
  }
};

// Obtener todas las materias del estudiante
const getMySubjects = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const subjects = await Subject.findByStudent(id_estudiante);

    res.json({
      success: true,
      count: subjects.length,
      data: subjects
    });

  } catch (error) {
    console.error('Error en getMySubjects:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener materias',
      error: error.message
    });
  }
};

// Obtener una materia específica
const getSubjectById = async (req, res) => {
  try {
    const { id } = req.params;
    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: 'Materia no encontrada'
      });
    }

    // Verificar que la materia pertenece al estudiante
    if (subject.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta materia'
      });
    }

    res.json({
      success: true,
      data: subject
    });

  } catch (error) {
    console.error('Error en getSubjectById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener materia',
      error: error.message
    });
  }
};

// Actualizar materia
const updateSubject = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, codigo, profesor, semestre, creditos, horario, color } = req.body;

    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: 'Materia no encontrada'
      });
    }

    // Verificar permisos
    if (subject.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar esta materia'
      });
    }

    const updated = await Subject.update(id, {
      nombre: nombre || subject.nombre,
      codigo: codigo !== undefined ? codigo : subject.codigo,
      profesor: profesor !== undefined ? profesor : subject.profesor,
      semestre: semestre !== undefined ? semestre : subject.semestre,
      creditos: creditos || subject.creditos,
      horario: horario !== undefined ? horario : subject.horario,
      color: color || subject.color
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la materia'
      });
    }

    const updatedSubject = await Subject.findById(id);

    res.json({
      success: true,
      message: 'Materia actualizada exitosamente',
      data: updatedSubject
    });

  } catch (error) {
    console.error('Error en updateSubject:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar materia',
      error: error.message
    });
  }
};

// Eliminar materia
const deleteSubject = async (req, res) => {
  try {
    const { id } = req.params;
    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: 'Materia no encontrada'
      });
    }

    // Verificar permisos
    if (subject.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta materia'
      });
    }

    const deleted = await Subject.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar la materia'
      });
    }

    res.json({
      success: true,
      message: 'Materia eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteSubject:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar materia',
      error: error.message
    });
  }
};

// Obtener estadísticas
const getSubjectStats = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Subject.getStats(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getSubjectStats:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas',
      error: error.message
    });
  }
};

module.exports = {
  createSubject,
  getMySubjects,
  getSubjectById,
  updateSubject,
  deleteSubject,
  getSubjectStats
};