-- ============================================================
-- Reversa: quita el soporte de login con Google
-- ============================================================
-- OJO: este down falla si ya existen estudiantes con contrasena NULL
-- (cuentas creadas solo con Google) — habría que asignarles una
-- contraseña temporal antes de revertir esta migración.
-- ============================================================

ALTER TABLE estudiantes
  DROP COLUMN google_id,
  MODIFY COLUMN contrasena VARCHAR(255) NOT NULL;
