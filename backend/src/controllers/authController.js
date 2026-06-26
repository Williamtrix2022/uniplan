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

    const isConnectionError =
      error.code === 'ECONNRESET' ||
      error.code === 'PROTOCOL_CONNECTION_LOST' ||
      error.code === 'ETIMEDOUT' ||
      error.errno === -4077;

    if (isConnectionError) {
      return res.status(503).json({
        success: false,
        message: 'El servidor de base de datos está temporalmente desconectado. Por favor, intenta de nuevo en unos segundos.'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Error al iniciar sesión'
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

    const otp = crypto.randomInt(100000, 1000000).toString();
    const tokenHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiresMinutes = parseInt(process.env.RESET_TOKEN_EXPIRE_MINUTES || '10', 10);
    const expiresAt = new Date(Date.now() + expiresMinutes * 60 * 1000);

    await Student.savePasswordResetToken(student.id, tokenHash, expiresAt);

    const otpDigits = otp.split('').join('  ');

    const emailHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#F5F5F5;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F5F5;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- HEADER -->
          <tr>
            <td style="background:linear-gradient(135deg,#00D9A0 0%,#00B386 100%);padding:36px 40px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.15);border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;margin-bottom:12px;">🎓</div>
              <h1 style="margin:0;color:#ffffff;font-size:26px;font-weight:700;letter-spacing:-0.5px;">Uniplan</h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">Tu espacio de enfoque académico</p>
            </td>
          </tr>

          <!-- BODY -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="margin:0 0 8px;color:#1A1A1A;font-size:20px;font-weight:700;">Recuperación de contraseña</h2>
              <p style="margin:0 0 28px;color:#6B7280;font-size:14px;line-height:1.6;">
                Hola <strong style="color:#1A1A1A;">${student.nombre}</strong>, recibimos una solicitud para restablecer tu contraseña. Usá el siguiente código en la app.
              </p>

              <!-- OTP BOX -->
              <div style="background:#E0F9F4;border-radius:14px;padding:28px 24px;text-align:center;margin-bottom:24px;">
                <p style="margin:0 0 12px;color:#6B7280;font-size:11px;text-transform:uppercase;letter-spacing:1.5px;font-weight:600;">Tu código de recuperación</p>
                <p style="margin:0;color:#00B386;font-size:42px;font-weight:800;letter-spacing:12px;font-family:monospace;">${otp}</p>
              </div>

              <!-- PASOS -->
              <div style="background:#F9FAFB;border-radius:10px;padding:16px 20px;margin-bottom:24px;">
                <p style="margin:0 0 8px;color:#1A1A1A;font-size:13px;font-weight:600;">¿Cómo usarlo?</p>
                <ol style="margin:0;padding-left:18px;color:#6B7280;font-size:13px;line-height:1.9;">
                  <li>Abrí la app Uniplan</li>
                  <li>Tocá <strong>"¿Olvidaste tu contraseña?"</strong></li>
                  <li>Tocá <strong>"Ya tengo mi código"</strong></li>
                  <li>Ingresá el código de 6 dígitos y elegí tu nueva contraseña</li>
                </ol>
              </div>

              <!-- EXPIRY WARNING -->
              <div style="background:#FEF3C7;border-radius:8px;padding:12px 16px;margin-bottom:32px;">
                <p style="margin:0;color:#92400E;font-size:13px;">⏱ Este código expira en <strong>${expiresMinutes} minutos</strong>. Si no lo usás a tiempo, solicitá uno nuevo.</p>
              </div>

              <!-- DIVIDER -->
              <hr style="border:none;border-top:1px solid #E5E7EB;margin:0 0 24px;">

              <!-- SECURITY NOTE -->
              <p style="margin:0;color:#9CA3AF;font-size:12px;line-height:1.6;text-align:center;">
                Si no solicitaste este cambio, ignorá este correo — tu cuenta sigue segura.<br>
                Nunca compartás este código con nadie.
              </p>
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="background:#F5F5F5;padding:20px 40px;text-align:center;border-top:1px solid #E5E7EB;">
              <p style="margin:0;color:#9CA3AF;font-size:12px;">© 2025 Uniplan · Todos los derechos reservados</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const emailText = `Hola ${student.nombre},\n\nTu código de recuperación de contraseña es:\n\n${otpDigits}\n\nExpira en ${expiresMinutes} minutos.\n\nCómo usarlo:\n1. Abrí la app Uniplan\n2. Tocá "¿Olvidaste tu contraseña?"\n3. Tocá "Ya tengo mi código"\n4. Ingresá el código y elegí tu nueva contraseña\n\nSi no solicitaste este cambio, ignorá este correo.\n\n© 2025 Uniplan`;

    await sendEmail({
      to: student.correo,
      subject: 'Uniplan · Recuperá tu contraseña',
      text: emailText,
      html: emailHtml
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
        message: 'Correo, código y nueva contraseña son obligatorios'
      });

    }

    if (!/^\d{6}$/.test(token.trim())) {
      return res.status(400).json({
        success: false,
        message: 'El código debe ser de 6 dígitos'
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

    const tokenHash = crypto.createHash('sha256').update(token.trim()).digest('hex');
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
