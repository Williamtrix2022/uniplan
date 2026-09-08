-- ============================================================
-- Agrega soporte de login con Google a estudiantes
-- ============================================================
-- google_id identifica la cuenta de Google vinculada (payload.sub del
-- ID token). contrasena pasa a ser nullable porque una cuenta creada
-- directamente vía Google no tiene contraseña propia.
-- ============================================================

ALTER TABLE estudiantes
  ADD COLUMN google_id VARCHAR(255) NULL UNIQUE,
  MODIFY COLUMN contrasena VARCHAR(255) NULL;
