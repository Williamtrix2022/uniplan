// ============================================
// CONTROLADOR DE AUTENTICACIÓN
// ============================================

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Student = require('../models/Student');

// ========== REGISTRAR NUEVO ESTUDIANTE ==========
const register = async (req, res) => {
  try {
    const { nombre, correo, contrasena, carrera, universidad } = req.body;

    // 1. Validar que vengan todos los campos requeridos
    if (!nombre || !correo || !contrasena) {
      return res.status(400).json({
        success: false,
        message: 'Nombre, correo y contraseña son obligatorios'
      });
    }

    // 2. Verificar si el correo ya existe
    const existingStudent = await Student.findByEmail(correo);
    if (existingStudent) {
      return res.status(400).json({
        success: false,
        message: 'El correo ya está registrado'
      });
    }

    // 3. Encriptar la contraseña
    const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_ROUNDS));
    const hashedPassword = await bcrypt.hash(contrasena, salt);

    // 4. Crear el estudiante en la base de datos
    const studentId = await Student.create({
      nombre,
      correo,
      contrasena: hashedPassword,
      carrera,
      universidad
    });

    // 5. Generar token JWT
    const token = jwt.sign(
      { id: studentId, correo },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    // 6. Responder con éxito
    res.status(201).json({
      success: true,
      message: 'Estudiante registrado exitosamente',
      data: {
        id: studentId,
        nombre,
        correo,
        carrera,
        universidad
      },
      token
    });

  } catch (error) {
    console.error('Error en register:', error);
    res.status(500).json({
      success: false,
      message: 'Error al registrar estudiante',
      error: error.message
    });
  }
};

// ========== INICIAR SESIÓN ==========
const login = async (req, res) => {
  try {
    const { correo, contrasena } = req.body;

    // 1. Validar campos requeridos
    if (!correo || !contrasena) {
      return res.status(400).json({
        success: false,
        message: 'Correo y contraseña son obligatorios'
      });
    }

    // 2. Buscar estudiante por correo
    const student = await Student.findByEmail(correo);
    if (!student) {
      return res.status(401).json({
        success: false,
        message: 'Credenciales inválidas'
      });
    }

    // 3. Verificar contraseña
    const isPasswordValid = await bcrypt.compare(contrasena, student.contrasena);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Credenciales inválidas'
      });
    }

    // 4. Generar token JWT
    const token = jwt.sign(
      { id: student.id, correo: student.correo },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    // 5. Responder con éxito (sin enviar la contraseña)
    res.json({
      success: true,
      message: 'Inicio de sesión exitoso',
      data: {
        id: student.id,
        nombre: student.nombre,
        correo: student.correo,
        carrera: student.carrera,
        universidad: student.universidad
      },
      token
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      success: false,
      message: 'Error al iniciar sesión',
      error: error.message
    });
  }
};

// ========== OBTENER PERFIL DEL USUARIO AUTENTICADO ==========
const getProfile = async (req, res) => {
  try {
    // req.user viene del middleware de autenticación
    const student = await Student.findById(req.user.id);

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
    console.error('Error en getProfile:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener perfil',
      error: error.message
    });
  }
};

module.exports = {
  register,
  login,
  getProfile
};