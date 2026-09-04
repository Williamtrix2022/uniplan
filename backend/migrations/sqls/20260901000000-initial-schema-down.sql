-- ============================================================
-- Reversa de la migración inicial
-- ============================================================
-- Borra todas las tablas del esquema. DESTRUCTIVO: solo para rehacer una
-- base local desde cero. Nunca correr en producción.
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS preferencias_notificacion;
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS calificaciones;
DROP TABLE IF EXISTS password_resets;
DROP TABLE IF EXISTS progreso_academico;
DROP TABLE IF EXISTS sesiones_pomodoro;
DROP TABLE IF EXISTS eventos_calendario;
DROP TABLE IF EXISTS notas;
DROP TABLE IF EXISTS horarios;
DROP TABLE IF EXISTS tareas;
DROP TABLE IF EXISTS materias;
DROP TABLE IF EXISTS estudiantes;

SET FOREIGN_KEY_CHECKS = 1;
