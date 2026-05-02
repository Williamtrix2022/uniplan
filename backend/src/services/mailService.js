const nodemailer = require('nodemailer');

const buildFromAddress = () => process.env.SMTP_FROM || process.env.RESEND_FROM || process.env.SMTP_USER;

const sendWithResend = async ({ to, subject, text, html }) => {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    return false;
  }

  const from = process.env.RESEND_FROM || buildFromAddress();
  if (!from) {
    throw new Error('Falta REMITENTE de correo (RESEND_FROM o SMTP_FROM)');
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      text,
      html
    })
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Error enviando correo con Resend: ${errorBody}`);
  }

  return true;
};

const createSmtpTransport = () => {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;
  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS) {
    return null;
  }

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: Number(SMTP_PORT),
    secure: Number(SMTP_PORT) === 465,
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS
    }
  });
};

const sendWithSmtp = async ({ to, subject, text, html }) => {
  const transporter = createSmtpTransport();
  if (!transporter) {
    return false;
  }

  const from = buildFromAddress();
  if (!from) {
    throw new Error('Falta REMITENTE de correo (SMTP_FROM o SMTP_USER)');
  }

  await transporter.sendMail({
    from,
    to,
    subject,
    text,
    html
  });

  return true;
};

const sendEmail = async (payload) => {
  const sentByResend = await sendWithResend(payload);
  if (sentByResend) return;

  const sentBySmtp = await sendWithSmtp(payload);
  if (sentBySmtp) return;

  throw new Error('No hay proveedor de correo configurado. Configura RESEND_API_KEY o SMTP_*');
};

module.exports = {
  sendEmail
};
