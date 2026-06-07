// ============================================
// CONFIGURACIÓN DE CONEXIÓN A MYSQL
// ============================================

const mysql = require('mysql2');
require('dotenv').config();

// Crear pool de conexiones con reconexión automática
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,

  // Configuración del pool
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,

  // Timeouts para evitar conexiones colgadas
  connectTimeout: 15000,        // 15s para conectar

  // Keepalive para evitar que el servidor cierre conexiones inactivas
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000, // Ping cada 10s de inactividad
});

// Manejador de errores del pool — reconexión automática
pool.on('connection', (connection) => {
  console.log('🔌 Nueva conexión MySQL establecida');
  connection.on('error', (err) => {
    console.error('⚠️ Error en conexión MySQL:', err.message);
    if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 'ECONNRESET') {
      console.log('🔄 Conexión perdida — el pool creará una nueva automáticamente');
    }
  });
});

pool.on('error', (err) => {
  console.error('⚠️ Error en pool MySQL:', err.message);
});

// Convertir pool a promesas (para usar async/await)
const promisePool = pool.promise();

// Función para probar la conexión
const testConnection = async () => {
  try {
    const connection = await promisePool.getConnection();
    console.log('✅ Conexión exitosa a MySQL');
    console.log(`📦 Base de datos: ${process.env.DB_NAME}`);
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Error al conectar con MySQL:', error.message);
    return false;
  }
};

// Exportar el pool y la función de prueba
module.exports = {
  pool: promisePool,
  testConnection,
};