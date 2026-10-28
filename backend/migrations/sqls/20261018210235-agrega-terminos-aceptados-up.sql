-- ============================================================
-- Registra la versión de términos aceptada y su fecha por estudiante
-- ============================================================
-- version_terminos_aceptados queda NULL para cuentas creadas antes de
-- esta migración (no se puede inferir retroactivamente qué aceptaron).
-- ============================================================

ALTER TABLE estudiantes
  ADD COLUMN version_terminos_aceptados VARCHAR(20) DEFAULT NULL,
  ADD COLUMN fecha_aceptacion_terminos TIMESTAMP NULL DEFAULT NULL;
