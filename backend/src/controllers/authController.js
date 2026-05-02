// ============================================
// CONTROLADOR DE AUTENTICACIÓN
// ============================================

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const Student = require('../models/Student');
const { isValidEmail, isRealEmail } = require('../utils/validators');
const { sendEmail } = require('../services/mailService');

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

    if (!isValidEmail(correo)) {
      return res.status(400).json({
        success: false,
        message: 'El correo no tiene un formato válido'
      });
    }

    const emailIsReal = await isRealEmail(correo);
    if (!emailIsReal) {
      return res.status(400).json({
        success: false,
        message: 'Debes usar un correo real y entregable'
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

    const welcomeSubject = 'Uniplan - Cuenta registrada';
    const welcomeText = `Hola ${nombre},\n\nTu cuenta en Uniplan fue creada correctamente.\nSi no reconoces esta acción, cambia tu contraseña inmediatamente.`;
    const welcomeHtml = `
      <p>Hola <strong>${nombre}</strong>,</p>
      <p>Tu cuenta en Uniplan fue creada correctamente.</p>
      <p>Si no reconoces esta acción, cambia tu contraseña inmediatamente.</p>
    `;

    sendEmail({
      to: correo,
      subject: welcomeSubject,
      text: welcomeText,
      html: welcomeHtml
    }).catch((error) => {
      console.error('Error enviando correo de bienvenida:', error.message);
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

// ========== SOLICITAR RECUPERACIÓN DE CONTRASEÑA ==========
const forgotPassword = async (req, res) => {
  const genericMessage = 'Si el correo existe, recibirás instrucciones para recuperar tu contraseña';

  try {
    const { correo } = req.body;

    if (!correo) {
      return res.status(400).json({
        success: false,
        message: 'El correo es obligatorio'
      });
    }

    if (!isValidEmail(correo)) {
      return res.status(400).json({
        success: false,
        message: 'Correo inválido'
      });
    }

    const emailIsReal = await isRealEmail(correo);
    if (!emailIsReal) {
      return res.status(400).json({
        success: false,
        message: 'Debes usar un correo real y entregable'
      });
    }

    const student = await Student.findByEmail(correo);

    // Respuesta segura: no exponer si el correo existe o no
    if (!student) {
      return res.json({
        success: true,
        message: genericMessage
      });
    }

    const resetBaseUrl = process.env.RESET_PASSWORD_URL;
    if (!resetBaseUrl) {
      throw new Error('Falta RESET_PASSWORD_URL en variables de entorno');
    }

    await Student.ensurePasswordResetTable();

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const expiresMinutes = parseInt(process.env.RESET_TOKEN_EXPIRE_MINUTES || '30', 10);
    const expiresAt = new Date(Date.now() + expiresMinutes * 60 * 1000);

    await Student.savePasswordResetToken(student.id, tokenHash, expiresAt);

    const resetUrl = `${resetBaseUrl}${resetBaseUrl.includes('?') ? '&' : '?'}token=${rawToken}`;
    const resetWebBaseUrl = process.env.RESET_PASSWORD_WEB_URL;
    const resetWebUrl = resetWebBaseUrl
      ? `${resetWebBaseUrl}${resetWebBaseUrl.includes('?') ? '&' : '?'}token=${rawToken}&email=${encodeURIComponent(student.correo)}`
      : null;
    const primaryUrl = resetWebUrl || resetUrl;

    await sendEmail({
      to: student.correo,
      subject: 'Uniplan - Recuperación de contraseña',
      text: `Hola ${student.nombre},\n\nRecibimos una solicitud para restablecer tu contraseña.\n\nAbre este enlace:\n${primaryUrl}\n\nSi tu correo no permite abrir enlaces de app, usa este enlace alterno:\n${resetUrl}\n\nTambién puedes usar este token manualmente en la app:\n${rawToken}\n\nEste enlace/token expira en ${expiresMinutes} minutos.\n\nSi no solicitaste este cambio, ignora este correo.`,
      html: `
        <p>Hola <strong>${student.nombre}</strong>,</p>
        <p>Recibimos una solicitud para restablecer tu contraseña.</p>
        <p>
          <a href="${primaryUrl}" target="_blank" rel="noopener noreferrer">
            Restablecer contraseña
          </a>
        </p>
        <p>Si el botón no funciona, copia y pega este enlace:</p>
        <p><code>${primaryUrl}</code></p>
        <p>Enlace alterno de app (deep link):</p>
        <p><code>${resetUrl}</code></p>
        <p>Token manual para pegar en la app:</p>
        <p><code>${rawToken}</code></p>
        <p>Este enlace expira en ${expiresMinutes} minutos.</p>
        <p>Si no solicitaste este cambio, ignora este correo.</p>
      `
    });

    res.json({
      success: true,
      message: genericMessage
    });

  } catch (error) {
    console.error('Error en forgotPassword:', error);
    res.status(500).json({
      success: false,
      message: 'Error al procesar recuperación de contraseña',
      error: error.message
    });
  }
};

// ========== RESTABLECER CONTRASEÑA ==========
const resetPassword = async (req, res) => {
  try {
    const { token, nuevaContrasena, correo } = req.body;

    if (!token || !nuevaContrasena || !correo) {
      return res.status(400).json({
        success: false,
        message: 'Correo, token y nueva contraseña son obligatorios'
      });
    }

    if (nuevaContrasena.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'La nueva contraseña debe tener al menos 6 caracteres'
      });
    }

    if (!isValidEmail(correo)) {
      return res.status(400).json({
        success: false,
        message: 'Correo inválido'
      });
    }

    await Student.ensurePasswordResetTable();

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const resetRecord = await Student.findValidPasswordResetByHash(tokenHash);

    if (!resetRecord) {
      return res.status(400).json({
        success: false,
        message: 'Token inválido o expirado'
      });
    }

    const student = await Student.findById(resetRecord.student_id);
    if (!student || student.correo.toLowerCase() !== correo.toLowerCase()) {
      return res.status(400).json({
        success: false,
        message: 'El correo no coincide con el token de recuperación'
      });
    }

    const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_ROUNDS, 10));
    const hashedPassword = await bcrypt.hash(nuevaContrasena, salt);

    const passwordUpdated = await Student.updatePassword(resetRecord.student_id, hashedPassword);
    if (!passwordUpdated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la contraseña'
      });
    }

    await Student.markPasswordResetAsUsed(resetRecord.id);

    res.json({
      success: true,
      message: 'Contraseña actualizada exitosamente'
    });

  } catch (error) {
    console.error('Error en resetPassword:', error);
    res.status(500).json({
      success: false,
      message: 'Error al restablecer contraseña',
      error: error.message
    });
  }
};

// ========== CAMBIAR CONTRASEÑA (USUARIO AUTENTICADO) ==========
const changePassword = async (req, res) => {
  try {
    const { contrasenaActual, nuevaContrasena } = req.body;

    if (!contrasenaActual || !nuevaContrasena) {
      return res.status(400).json({
        success: false,
        message: 'La contraseña actual y la nueva contraseña son obligatorias'
      });
    }

    if (nuevaContrasena.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'La nueva contraseña debe tener al menos 6 caracteres'
      });
    }

    const student = await Student.findByEmail(req.user.correo);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Estudiante no encontrado'
      });
    }

    const isCurrentValid = await bcrypt.compare(contrasenaActual, student.contrasena);
    if (!isCurrentValid) {
      return res.status(400).json({
        success: false,
        message: 'La contraseña actual es incorrecta'
      });
    }

    const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_ROUNDS, 10));
    const hashedPassword = await bcrypt.hash(nuevaContrasena, salt);

    const updated = await Student.updatePassword(req.user.id, hashedPassword);
    if (!updated) {
      return res.status(400).json({
        success: false,
        message: 'No se pudo actualizar la contraseña'
      });
    }

    res.json({
      success: true,
      message: 'Contraseña cambiada exitosamente'
    });
  } catch (error) {
    console.error('Error en changePassword:', error);
    res.status(500).json({
      success: false,
      message: 'Error al cambiar contraseña',
      error: error.message
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  forgotPassword,
  resetPassword,
  changePassword
};
