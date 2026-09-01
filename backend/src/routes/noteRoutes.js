// ============================================
// RUTAS DE NOTAS
// ============================================

const express = require('express');
const router = express.Router();
const noteController = require('../controllers/noteController');
const authMiddleware = require('../middlewares/authMiddleware');
const { handleValidation } = require('../middlewares/validate');
const v = require('../validators/noteValidators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/notes - Crear nueva nota
router.post('/', v.create, handleValidation, noteController.createNote);

// GET /api/notes - Obtener todas las notas (con filtros opcionales)
router.get('/', v.list, handleValidation, noteController.getMyNotes);

// GET /api/notes/favorites - Obtener notas favoritas
router.get('/favorites', noteController.getFavoriteNotes);

// GET /api/notes/recent - Obtener notas recientes
router.get('/recent', v.recent, handleValidation, noteController.getRecentNotes);

// GET /api/notes/stats - Obtener estadísticas
router.get('/stats', noteController.getNoteStats);

// GET /api/notes/:id - Obtener una nota específica
router.get('/:id', v.detail, handleValidation, noteController.getNoteById);

// PUT /api/notes/:id - Actualizar nota
router.put('/:id', v.update, handleValidation, noteController.updateNote);

// PATCH /api/notes/:id/favorite - Alternar favorito
router.patch('/:id/favorite', v.detail, handleValidation, noteController.toggleFavorite);

// DELETE /api/notes/:id - Eliminar nota
router.delete('/:id', v.detail, handleValidation, noteController.deleteNote);

module.exports = router;
