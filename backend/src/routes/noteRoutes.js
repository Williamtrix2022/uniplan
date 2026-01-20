// ============================================
// RUTAS DE NOTAS
// ============================================

const express = require('express');
const router = express.Router();
const noteController = require('../controllers/noteController');
const authMiddleware = require('../middlewares/authMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/notes - Crear nueva nota
router.post('/', noteController.createNote);

// GET /api/notes - Obtener todas las notas (con filtros opcionales)
router.get('/', noteController.getMyNotes);

// GET /api/notes/favorites - Obtener notas favoritas
router.get('/favorites', noteController.getFavoriteNotes);

// GET /api/notes/recent - Obtener notas recientes
router.get('/recent', noteController.getRecentNotes);

// GET /api/notes/stats - Obtener estadísticas
router.get('/stats', noteController.getNoteStats);

// GET /api/notes/:id - Obtener una nota específica
router.get('/:id', noteController.getNoteById);

// PUT /api/notes/:id - Actualizar nota
router.put('/:id', noteController.updateNote);

// PATCH /api/notes/:id/favorite - Alternar favorito
router.patch('/:id/favorite', noteController.toggleFavorite);

// DELETE /api/notes/:id - Eliminar nota
router.delete('/:id', noteController.deleteNote);

module.exports = router;