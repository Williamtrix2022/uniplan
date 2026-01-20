// ============================================
// CONFIGURACIÓN DE EXPRESS
// ============================================

const express = require('express');
const cors = require('cors');

const app = express();

// ========== MIDDLEWARES GLOBALES ==========

// 1. CORS - Permitir peticiones desde Flutter
app.use(cors({
  origin: '*', // En producción, especifica el dominio de tu app
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 2. Parser de JSON - Leer body de las peticiones
app.use(express.json());

// 3. Parser de URL encoded - Para formularios
app.use(express.urlencoded({ extended: true }));

// ========== IMPORTAR RUTAS ==========
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const subjectRoutes = require('./routes/subjectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const noteRoutes = require('./routes/noteRoutes');
const pomodoroRoutes = require('./routes/pomodoroRoutes');


// 4. Logger simple de peticiones
app.use((req, res, next) => {
  console.log(`📨 ${req.method} ${req.path} - ${new Date().toLocaleTimeString()}`);
  next();
});

// ========== RUTAS ==========

// Ruta principal
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Bienvenido a Uniplan API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      students: '/api/students',
      subjects: '/api/subjects',
      tasks: '/api/tasks',
      notes: '/api/notes',
      pomodoro: '/api/pomodoro'
    }
  });
});

// ========== IMPORTAR RUTAS ==========
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/subjects', subjectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/pomodoro', pomodoroRoutes);

// Health check - Para verificar que el servidor funciona
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Servidor funcionando correctamente',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// ========== IMPORTAR RUTAS (las crearemos después) ==========
// const authRoutes = require('./routes/authRoutes');
// const studentRoutes = require('./routes/studentRoutes');

// app.use('/api/auth', authRoutes);
// app.use('/api/students', studentRoutes);

// ========== MANEJO DE ERRORES ==========

// Ruta no encontrada (404)
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Ruta no encontrada',
    path: req.path
  });
});

// Error handler global
app.use((error, req, res, next) => {
  console.error('❌ Error:', error);
  
  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? error.stack : undefined
  });
});

module.exports = app;