// ============================================
// UTILIDADES DE VALIDACIÓN
// ============================================

// Validar email
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Validar contraseña (mínimo 6 caracteres)
const isValidPassword = (password) => {
  return password && password.length >= 6;
};

// Validar fecha (formato YYYY-MM-DD)
const isValidDate = (dateString) => {
  const regex = /^\d{4}-\d{2}-\d{2}$/;
  if (!regex.test(dateString)) return false;
  
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date);
};

// Validar hora (formato HH:MM)
const isValidTime = (timeString) => {
  const regex = /^([01]\d|2[0-3]):([0-5]\d)$/;
  return regex.test(timeString);
};

// Validar prioridad
const isValidPriority = (priority) => {
  const validPriorities = ['baja', 'media', 'alta'];
  return validPriorities.includes(priority);
};

// Validar estado de tarea
const isValidTaskStatus = (status) => {
  const validStatuses = ['pendiente', 'en_progreso', 'completada'];
  return validStatuses.includes(status);
};

// Validar tipo de evento
const isValidEventType = (type) => {
  const validTypes = ['clase', 'examen', 'tarea', 'evento', 'otro'];
  return validTypes.includes(type);
};

// Validar color hexadecimal
const isValidColor = (color) => {
  const regex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
  return regex.test(color);
};

// Sanitizar texto (prevenir XSS básico)
const sanitizeText = (text) => {
  if (typeof text !== 'string') return text;
  return text
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .trim();
};

// Validar rango de fechas
const isValidDateRange = (startDate, endDate) => {
  if (!isValidDate(startDate) || !isValidDate(endDate)) return false;
  return new Date(startDate) <= new Date(endDate);
};

// Validar que la fecha no sea pasada
const isNotPastDate = (dateString) => {
  const date = new Date(dateString);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return date >= today;
};

module.exports = {
  isValidEmail,
  isValidPassword,
  isValidDate,
  isValidTime,
  isValidPriority,
  isValidTaskStatus,
  isValidEventType,
  isValidColor,
  sanitizeText,
  isValidDateRange,
  isNotPastDate
};