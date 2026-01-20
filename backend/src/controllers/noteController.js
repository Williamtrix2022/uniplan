// ============================================
// CONTROLADOR DE NOTAS
// ============================================

const Note = require('../models/Note');

// Crear nueva nota
const createNote = async (req, res) => {
  try {
    const { id_materia, titulo, contenido, etiquetas, favorito } = req.body;
    const id_estudiante = req.user.id;

    if (!titulo || !contenido) {
      return res.status(400).json({
        success: false,
        message: 'Título y contenido son obligatorios'
      });
    }

    const noteId = await Note.create({
      id_estudiante,
      id_materia,
      titulo,
      contenido,
      etiquetas,
      favorito
    });

    const note = await Note.findById(noteId);

    res.status(201).json({
      success: true,
      message: 'Nota creada exitosamente',
      data: note
    });

  } catch (error) {
    console.error('Error en createNote:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear nota',
      error: error.message
    });
  }
};

// Obtener todas las notas del estudiante
const getMyNotes = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { id_materia, favorito, search } = req.query;

    const filters = {};
    if (id_materia) filters.id_materia = id_materia;
    if (favorito !== undefined) filters.favorito = favorito === 'true';
    if (search) filters.search = search;

    const notes = await Note.findByStudent(id_estudiante, filters);

    res.json({
      success: true,
      count: notes.length,
      data: notes
    });

  } catch (error) {
    console.error('Error en getMyNotes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener notas',
      error: error.message
    });
  }
};

// Obtener notas favoritas
const getFavoriteNotes = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const notes = await Note.getFavorites(id_estudiante);

    res.json({
      success: true,
      count: notes.length,
      data: notes
    });

  } catch (error) {
    console.error('Error en getFavoriteNotes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener notas favoritas',
      error: error.message
    });
  }
};

// Obtener notas recientes
const getRecentNotes = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const limit = parseInt(req.query.limit) || 10;
    const notes = await Note.getRecent(id_estudiante, limit);

    res.json({
      success: true,
      count: notes.length,
      data: notes
    });

  } catch (error) {
    console.error('Error en getRecentNotes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener notas recientes',
      error: error.message
    });
  }
};

// Obtener nota por ID
const getNoteById = async (req, res) => {
  try {
    const { id } = req.params;
    const note = await Note.findById(id);

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Nota no encontrada'
      });
    }

    if (note.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta nota'
      });
    }

    res.json({
      success: true,
      data: note
    });

  } catch (error) {
    console.error('Error en getNoteById:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener nota',
      error: error.message
    });
  }
};

// Actualizar nota
const updateNote = async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, contenido, id_materia, etiquetas, favorito } = req.body;

    const note = await Note.findById(id);

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Nota no encontrada'
      });
    }

    if (note.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para actualizar esta nota'
      });
    }

    const updated = await Note.update(id, {
      titulo: titulo || note.titulo,
      contenido: contenido || note.contenido,
      id_materia: id_materia !== undefined ? id_materia : note.id_materia,
      etiquetas: etiquetas !== undefined ? etiquetas : note.etiquetas,
      favorito: favorito !== undefined ? favorito : note.favorito
    });

    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la nota'
      });
    }

    const updatedNote = await Note.findById(id);

    res.json({
      success: true,
      message: 'Nota actualizada exitosamente',
      data: updatedNote
    });

  } catch (error) {
    console.error('Error en updateNote:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar nota',
      error: error.message
    });
  }
};

// Alternar favorito
const toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;
    const note = await Note.findById(id);

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Nota no encontrada'
      });
    }

    if (note.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para modificar esta nota'
      });
    }

    const toggled = await Note.toggleFavorite(id);

    if (!toggled) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar el favorito'
      });
    }

    const updatedNote = await Note.findById(id);

    res.json({
      success: true,
      message: updatedNote.favorito ? 'Nota marcada como favorita' : 'Nota desmarcada como favorita',
      data: updatedNote
    });

  } catch (error) {
    console.error('Error en toggleFavorite:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar favorito',
      error: error.message
    });
  }
};

// Eliminar nota
const deleteNote = async (req, res) => {
  try {
    const { id } = req.params;
    const note = await Note.findById(id);

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Nota no encontrada'
      });
    }

    if (note.id_estudiante !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para eliminar esta nota'
      });
    }

    const deleted = await Note.delete(id);

    if (!deleted) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo eliminar la nota'
      });
    }

    res.json({
      success: true,
      message: 'Nota eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error en deleteNote:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar nota',
      error: error.message
    });
  }
};

// Obtener estadísticas
const getNoteStats = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const stats = await Note.getStats(id_estudiante);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error en getNoteStats:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas',
      error: error.message
    });
  }
};

module.exports = {
  createNote,
  getMyNotes,
  getFavoriteNotes,
  getRecentNotes,
  getNoteById,
  updateNote,
  toggleFavorite,
  deleteNote,
  getNoteStats
};