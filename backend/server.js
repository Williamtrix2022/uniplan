// ============================================
// UNIPLAN BACKEND - SERVIDOR PRINCIPAL
// ============================================

require('dotenv').config();
const app = require('./src/app');
const { testConnection } = require('./src/config/database');
const Notification = require('./src/models/Notification');
const RefreshToken = require('./src/models/RefreshToken');

const PORT = process.env.PORT || 3000;

// Asegura que existan las tablas de notificaciones y refresh tokens (no debe
// tumbar el server si falla). Las migraciones son el registro "oficial";
// esto es la red de seguridad para el entorno serverless.
const ensureNotificationTables = async () => {
  try {
    await Notification.ensureTables();
    await RefreshToken.ensureTable();
    console.log('✅ Tablas de notificaciones y refresh tokens verificadas/creadas');
  } catch (error) {
    console.error('⚠️ No se pudieron verificar/crear tablas auxiliares:', error.message);
  }
};

// Función para iniciar el servidor
const startServer = async () => {
  try {
    // 1. Probar conexión a la base de datos
    const dbConnected = await testConnection();

    if (!dbConnected) {
      console.error('❌ No se pudo conectar a la base de datos. Servidor detenido.');
      process.exit(1);
    }

    // 1.1 Verificar/crear tablas del módulo de notificaciones
    await ensureNotificationTables();

    // 2. Iniciar el servidor Express
    app.listen(PORT, () => {
      console.log('\n🚀 ================================');
      console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
      console.log(`🚀 Entorno: ${process.env.NODE_ENV}`);
      console.log(`🚀 URL: http://localhost:${PORT}`);
      console.log('🚀 ================================\n');
      console.log('📡 Rutas disponibles:');
      console.log(`   GET  http://localhost:${PORT}/`);
      console.log(`   GET  http://localhost:${PORT}/api/health`);
      console.log(`   POST http://localhost:${PORT}/api/auth/register`);
      console.log(`   POST http://localhost:${PORT}/api/auth/login`);
      console.log('\n⏳ Esperando peticiones...\n');
    });

  } catch (error) {
    console.error('❌ Error al iniciar el servidor:', error);
    process.exit(1);
  }
};

// Iniciar servidor (local) o exportar app (Vercel serverless)
if (require.main === module) {
  startServer();
} else {
  // Entorno serverless (Vercel): no hay app.listen, pero igual verificamos
  // las tablas de notificaciones de forma perezosa (fire-and-forget, no
  // debe bloquear ni tumbar el cold start del handler).
  ensureNotificationTables();
  module.exports = app;
}

// Manejar cierre graceful
process.on('SIGTERM', () => {
  console.log('\n👋 Cerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n👋 Cerrando servidor...');
  process.exit(0);
});