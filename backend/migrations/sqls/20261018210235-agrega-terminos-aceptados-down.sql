-- ============================================================
-- Reversa: quita el registro de aceptación de términos
-- ============================================================

ALTER TABLE estudiantes
  DROP COLUMN version_terminos_aceptados,
  DROP COLUMN fecha_aceptacion_terminos;
