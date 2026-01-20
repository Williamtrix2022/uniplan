// ============================================
// CONTROLADOR DE ESTUDIANTES (CRUD)
// ============================================

const Student = require('../models/Student');

// ========== OBTENER TODOS LOS ESTUDIANTES ==========
const getAllStudents = async (req, res) => {
  try {
    const students = await Student.findAll();

    res.json({
      success: true,
      count: students.length,
      data: students
    });

  } catch (error) {
    console.error('Error en getAllStudents:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estudiantes',
      error: error.message
    });
  }
};

// ========== OBTENER UN ESTUDIANTE POR ID ==========
const getStudentById = async (req, res) => {
  try {
    const { id } = req.params;

    const student = await Student.findById(id);

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Estudiante no encontrado'
      });
    }

    res.json({
      success: true,
      data: student
    });

  } catch (error) {
    console.error('Error en getStudentById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estudiante',
      error: error.message
    });
  }
};

// ========== ACTUALIZAR ESTUDIANTE ==========
const updateStudent = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, carrera, universidad } = req.body;

    // Validar que el estudiante existe
    const student = await Student.findById(id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Estudiante no encontrado'
      });
    }

    // Validar que solo puede actualizar su propio perfil
    if (req.user.id !== parseInt(id)) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar este perfil'
      });
    }

    // Actualizar
    const updated = await Student.update(id, {
      nombre: nombre || student.nombre,
      carrera: carrera || student.carrera,
      universidad: universidad || student.universidad
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar el estudiante'
      });
    }

    // Obtener datos actualizados
    const updatedStudent = await Student.findById(id);

    res.json({
      success: true,
      message: 'Estudiante actualizado exitosamente',
      data: updatedStudent
    });

  } catch (error) {
    console.error('Error en updateStudent:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar estudiante',
      error: error.message
    });
  }
};

// ========== ELIMINAR ESTUDIANTE ==========
const deleteStudent = async (req, res) => {
  try {
    const { id } = req.params;

    // Validar que el estudiante existe
    const student = await Student.findById(id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Estudiante no encontrado'
      });
    }

    // Validar que solo puede eliminar su propio perfil
    if (req.user.id !== parseInt(id)) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar este perfil'
      });
    }

    // Eliminar (soft delete)
    const deleted = await Student.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar el estudiante'
      });
    }

    res.json({
      success: true,
      message: 'Estudiante eliminado exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteStudent:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar estudiante',
      error: error.message
    });
  }
};

module.exports = {
  getAllStudents,
  getStudentById,
  updateStudent,
  deleteStudent
};