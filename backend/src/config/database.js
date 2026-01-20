// ============================================
// CONFIGURACIÓN DE CONEXIÓN A MYSQL
// ============================================

const mysql = require('mysql2');
require('dotenv').config();

// Crear pool de conexiones (más eficiente que conexiones individuales)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  waitForConnections: true,
  connectionLimit: 10,      // Máximo 10 conexiones simultáneas
  queueLimit: 0
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
  testConnection
};