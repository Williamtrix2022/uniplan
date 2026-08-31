// ============================================
// CONFIGURACIÓN DE EXPRESS
// ============================================

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const { apiLimiter } = require('./middlewares/rateLimiter');
const sanitizeErrorResponse = require('./middlewares/sanitizeErrorResponse');

const app = express();

// El backend corre detrás del proxy de Vercel; sin esto express-rate-limit
// ve siempre la IP del proxy y el límite por IP no sirve.
app.set('trust proxy', 1);

// ========== MIDDLEWARES GLOBALES ==========

// 1. Headers de seguridad (helmet). Es una API JSON, no sirve HTML propio,
//    así que la CSP por defecto de helmet no molesta.
app.use(helmet());

// 2. CORS. La lista de orígenes permitidos se toma de CORS_ORIGINS
//    (separados por coma). Si no está seteada se cae a '*' —sólo pensado
//    para desarrollo— con una advertencia en el log.
const corsOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

if (corsOrigins.length === 0) {
  console.warn(
    '⚠️  CORS_ORIGINS no está configurada: se permite cualquier origen (*). ' +
    'Definí CORS_ORIGINS con el dominio real antes de producción.'
  );
}

app.use(cors({
  origin: (origin, callback) => {
    // Peticiones sin Origin (apps móviles, curl, health checks) siempre pasan.
    if (!origin) return callback(null, true);
    if (corsOrigins.length === 0 || corsOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Origen no permitido por CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 3. Límite general de peticiones por IP (los endpoints de auth tienen
//    límites más estrictos propios encima de este).
app.use(apiLimiter);

// 4. No filtrar detalles internos de error al cliente fuera de desarrollo.
app.use(sanitizeErrorResponse);

// 5. Parser de JSON - Leer body de las peticiones
app.use(express.json());

// 6. Parser de URL encoded - Para formularios
app.use(express.urlencoded({ extended: true }));

// ========== IMPORTAR RUTAS ==========
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const subjectRoutes = require('./routes/subjectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const noteRoutes = require('./routes/noteRoutes');
const pomodoroRoutes = require('./routes/pomodoroRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const gradeRoutes = require('./routes/gradeRoutes');
const notificationRoutes = require('./routes/notificationRoutes');


// 7. Logger simple de peticiones
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
    author: 'William Moya Santana',
    description: 'API REST para gestión académica universitaria',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      students: '/api/students',
      subjects: '/api/subjects',
      tasks: '/api/tasks',
      notes: '/api/notes',
      pomodoro: '/api/pomodoro',
      calendar: '/api/calendar',
      dashboard: '/api/dashboard',
      schedules: '/api/schedules',
      grades: '/api/grades',
      notifications: '/api/notifications'
    },
    documentation: 'Ver README.md para más información'
  });
});

// ========== IMPORTAR RUTAS ==========
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/subjects', subjectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/pomodoro', pomodoroRoutes);
app.use('/api/calendar', calendarRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/grades', gradeRoutes);
app.use('/api/notifications', notificationRoutes);

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

  const status = error.status || 500;
  const isDev = process.env.NODE_ENV === 'development';

  // Para errores del servidor (5xx) no se expone el mensaje interno al
  // cliente fuera de desarrollo; el detalle real ya quedó en el log.
  const message = status >= 500 && !isDev
    ? 'Error interno del servidor'
    : (error.message || 'Error interno del servidor');

  res.status(status).json({
    success: false,
    message,
    error: isDev ? error.stack : undefined
  });
});

module.exports = app;
