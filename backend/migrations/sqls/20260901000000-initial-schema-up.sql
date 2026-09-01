-- ============================================================
-- Migración inicial — esquema completo de Uniplan
-- ============================================================
-- Baseline: refleja el estado de backend/db/schema.sql (solo estructura,
-- sin datos de prueba). Todas las tablas usan CREATE TABLE IF NOT EXISTS,
-- así que aplicar esta migración sobre una base que YA tiene el esquema
-- (producción actual) es un no-op seguro: solo deja registrada la
-- migración como aplicada.
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS estudiantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  correo VARCHAR(100) NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  carrera VARCHAR(100) DEFAULT NULL,
  universidad VARCHAR(150) DEFAULT 'Universidad de Córdoba',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo TINYINT(1) DEFAULT 1,
  UNIQUE KEY correo (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS materias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  codigo VARCHAR(20) DEFAULT NULL,
  profesor VARCHAR(100) DEFAULT NULL,
  semestre INT DEFAULT NULL,
  creditos INT DEFAULT 3,
  horario TEXT DEFAULT NULL,
  color VARCHAR(7) DEFAULT '#4CAF50',
  activo TINYINT(1) DEFAULT 1,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  CONSTRAINT materias_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS tareas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT DEFAULT NULL,
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT DEFAULT NULL,
  fecha_entrega DATE NOT NULL,
  prioridad ENUM('baja','media','alta') DEFAULT 'media',
  es_proyecto TINYINT(1) NOT NULL DEFAULT 0,
  estado ENUM('pendiente','en_progreso','completada') DEFAULT 'pendiente',
  recordatorio TINYINT(1) DEFAULT 0,
  fecha_recordatorio DATETIME DEFAULT NULL,
  completada TINYINT(1) DEFAULT 0,
  fecha_completada DATETIME DEFAULT NULL,
  activo TINYINT(1) DEFAULT 1,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  KEY idx_materia (id_materia),
  KEY idx_fecha_entrega (fecha_entrega),
  KEY idx_tareas_es_proyecto (es_proyecto),
  CONSTRAINT tareas_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE,
  CONSTRAINT tareas_ibfk_2 FOREIGN KEY (id_materia) REFERENCES materias (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS horarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT NOT NULL,
  dia ENUM('lunes','martes','miercoles','jueves','viernes','sabado','domingo') NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  aula VARCHAR(100) DEFAULT NULL,
  activo TINYINT(1) DEFAULT 1,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  KEY idx_materia (id_materia),
  KEY idx_estudiante_dia (id_estudiante, dia),
  CONSTRAINT horarios_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE,
  CONSTRAINT horarios_ibfk_2 FOREIGN KEY (id_materia) REFERENCES materias (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS notas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT DEFAULT NULL,
  titulo VARCHAR(150) NOT NULL,
  contenido TEXT NOT NULL,
  etiquetas VARCHAR(255) DEFAULT NULL,
  favorito TINYINT(1) DEFAULT 0,
  activo TINYINT(1) DEFAULT 1,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  KEY idx_materia (id_materia),
  CONSTRAINT notas_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE,
  CONSTRAINT notas_ibfk_2 FOREIGN KEY (id_materia) REFERENCES materias (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS eventos_calendario (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT DEFAULT NULL,
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT DEFAULT NULL,
  fecha DATE NOT NULL,
  hora_inicio TIME DEFAULT NULL,
  hora_fin TIME DEFAULT NULL,
  tipo ENUM('clase','examen','tarea','evento','otro') DEFAULT 'evento',
  ubicacion VARCHAR(150) DEFAULT NULL,
  recordatorio TINYINT(1) DEFAULT 0,
  minutos_antes_recordatorio INT DEFAULT 30,
  todo_el_dia TINYINT(1) DEFAULT 0,
  color VARCHAR(7) DEFAULT '#2196F3',
  activo TINYINT(1) DEFAULT 1,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_materia (id_materia),
  KEY idx_estudiante (id_estudiante),
  KEY idx_fecha (fecha),
  CONSTRAINT eventos_calendario_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE,
  CONSTRAINT eventos_calendario_ibfk_2 FOREIGN KEY (id_materia) REFERENCES materias (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS sesiones_pomodoro (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT DEFAULT NULL,
  duracion_trabajo INT DEFAULT 25,
  duracion_descanso INT DEFAULT 5,
  ciclos_completados INT DEFAULT 0,
  tiempo_total_estudio INT DEFAULT 0,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME DEFAULT NULL,
  completada TINYINT(1) DEFAULT 0,
  notas TEXT DEFAULT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY id_materia (id_materia),
  KEY idx_estudiante (id_estudiante),
  KEY idx_fecha (fecha_inicio),
  CONSTRAINT sesiones_pomodoro_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE,
  CONSTRAINT sesiones_pomodoro_ibfk_2 FOREIGN KEY (id_materia) REFERENCES materias (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS progreso_academico (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  fecha DATE NOT NULL,
  tareas_completadas INT DEFAULT 0,
  minutos_estudiados INT DEFAULT 0,
  sesiones_pomodoro INT DEFAULT 0,
  promedio_productividad DECIMAL(5,2) DEFAULT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_estudiante_fecha (id_estudiante, fecha),
  KEY idx_estudiante (id_estudiante),
  KEY idx_fecha (fecha),
  CONSTRAINT progreso_academico_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS password_resets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  used_at DATETIME DEFAULT NULL,
  KEY idx_token_hash (token_hash),
  KEY idx_student_id (student_id),
  CONSTRAINT fk_password_resets_student FOREIGN KEY (student_id) REFERENCES estudiantes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS calificaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT NOT NULL,
  tipo ENUM('parcial','taller','quiz','proyecto','laboratorio','final','otro') NOT NULL DEFAULT 'otro',
  descripcion VARCHAR(150),
  valor DECIMAL(3,2) NOT NULL,
  porcentaje DECIMAL(5,2) NOT NULL,
  fecha_evaluacion DATE,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  KEY idx_materia (id_materia),
  KEY idx_estudiante_materia (id_estudiante, id_materia),
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE,
  FOREIGN KEY (id_materia) REFERENCES materias(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS notificaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  tipo ENUM('tarea','clase','evento','sistema','general') NOT NULL DEFAULT 'general',
  titulo VARCHAR(150) NOT NULL,
  mensaje TEXT NULL,
  leida BOOLEAN DEFAULT FALSE,
  referencia_tipo VARCHAR(50) NULL,
  referencia_id INT NULL,
  fecha_programada DATETIME NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE,
  INDEX idx_estudiante (id_estudiante),
  INDEX idx_leida (leida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS preferencias_notificacion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL UNIQUE,
  notif_tareas BOOLEAN DEFAULT TRUE,
  notif_clases BOOLEAN DEFAULT TRUE,
  notif_generales BOOLEAN DEFAULT TRUE,
  minutos_antes_tarea INT DEFAULT 60,
  minutos_antes_clase INT DEFAULT 30,
  sonido_activo BOOLEAN DEFAULT TRUE,
  hora_silencio_inicio TIME NULL,
  hora_silencio_fin TIME NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
