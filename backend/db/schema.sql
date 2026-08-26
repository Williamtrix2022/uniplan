-- ============================================================
-- UNIPLAN — BASE DE DATOS (esquema + datos de prueba)
-- ============================================================
-- Archivo único: esquema completo (DDL) + datos de prueba de un
-- estudiante demo. Reemplaza a los antiguos backend/seeds/*.sql
-- (eliminados) y a docs/uniplan_db.md (dump real de producción,
-- usado solo para verificar que este esquema estuviera al día y
-- luego eliminado — nunca se versiona un dump con datos reales).
--
-- Uso: se aplica solo en una base nueva/vacía. `docker-compose.yml`
-- lo monta como script de inicialización de MySQL.
--
-- Si el esquema real de producción cambia, este archivo debe
-- actualizarse a mano — no hay migraciones automáticas todavía
-- (ver docs/PRODUCCION.md).
--
-- Estudiante demo: demo@uniplan.co / Uniplan2026
-- (hash bcrypt real, 10 rounds, igual que BCRYPT_ROUNDS en el backend)
--
-- IMPORTANTE — la sección de datos de prueba (después de "SEED DE
-- DATOS") NO es idempotente: si se corre dos veces sobre la misma
-- base crea un estudiante demo duplicado. Pensada para una base
-- nueva (`docker compose down -v && up`), no para reaplicar sobre
-- una base ya poblada.
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- ESQUEMA
-- ============================================================

-- ── estudiantes ─────────────────────────────────────────────────────────
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

-- ── materias ────────────────────────────────────────────────────────────
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

-- ── tareas ──────────────────────────────────────────────────────────────
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

-- ── horarios ────────────────────────────────────────────────────────────
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

-- ── notas ───────────────────────────────────────────────────────────────
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

-- ── eventos_calendario ──────────────────────────────────────────────────
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

-- ── sesiones_pomodoro ───────────────────────────────────────────────────
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

-- ── progreso_academico ──────────────────────────────────────────────────
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

-- ── password_resets ─────────────────────────────────────────────────────
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

-- ── calificaciones ──────────────────────────────────────────────────────
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

-- ── notificaciones ──────────────────────────────────────────────────────
-- Réplica exacta de backend/src/models/Notification.js#ensureTables()
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

-- ============================================================
-- SEED DE DATOS — estudiante demo (NO idempotente, ver aviso arriba)
-- ============================================================

START TRANSACTION;

-- ============ ESTUDIANTE DEMO ============
-- Contraseña en texto plano: Uniplan2026
INSERT INTO estudiantes (nombre, correo, contrasena, carrera, universidad, activo)
VALUES (
  'Camila Andrea Restrepo Martínez',
  'demo@uniplan.co',
  '$2a$10$hJZ5EUpePuhwcDBXOWdm9eXlve48Ye7/r9VBhUPqdEoPLbzYW3poG',
  'Ingeniería de Sistemas',
  'Universidad de Córdoba',
  TRUE
);

SET @student_id = LAST_INSERT_ID();

-- ============ MATERIAS ============
INSERT INTO materias (id_estudiante, nombre, codigo, profesor, semestre, creditos, horario, color, activo)
VALUES
  (@student_id, 'Cálculo Diferencial',              'MAT101', 'Luis Fernando Herrera',    2, 4, NULL, '#00D9A0', TRUE),
  (@student_id, 'Programación Orientada a Objetos',  'ISW205', 'Andrea Patricia Lozano',   3, 4, NULL, '#FF6B6B', TRUE),
  (@student_id, 'Bases de Datos',                    'ISW210', 'Carlos Mario Pérez',       3, 3, NULL, '#4D96FF', TRUE),
  (@student_id, 'Álgebra Lineal',                    'MAT102', 'Diana Carolina Mendoza',   2, 3, NULL, '#FFB84D', TRUE),
  (@student_id, 'Inglés IV',                         'IDM104', 'Jennifer Alexandra Torres',2, 2, NULL, '#9B5DE5', TRUE),
  (@student_id, 'Ética Profesional',                 'HUM301', 'Ricardo Andrés Salcedo',   3, 2, NULL, '#00BBF9', TRUE);

-- ============ TAREAS ============
INSERT INTO tareas (id_estudiante, id_materia, titulo, descripcion, fecha_entrega, prioridad, estado, recordatorio, es_proyecto, completada, fecha_completada, activo)
VALUES
  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   'Taller derivadas parciales',
   'Resolver ejercicios de derivadas parciales del capítulo 4 del libro guía.',
   '2026-06-20', 'alta', 'completada', FALSE, FALSE, TRUE, '2026-06-19', TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   'Quiz límites y continuidad',
   'Preparar quiz corto sobre límites laterales y continuidad de funciones.',
   '2026-07-02', 'media', 'completada', FALSE, FALSE, TRUE, '2026-07-01', TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   'Taller integrales dobles',
   'Ejercicios de integrales dobles en coordenadas rectangulares y polares.',
   '2026-07-22', 'alta', 'pendiente', TRUE, FALSE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   'Diagrama de clases sistema de biblioteca',
   'Modelar en UML el sistema de préstamos de la biblioteca universitaria.',
   '2026-06-25', 'alta', 'completada', FALSE, TRUE, TRUE, '2026-06-24', TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   'Implementación patrón Observer',
   'Implementar el patrón de diseño Observer en Java sobre un caso de notificaciones.',
   '2026-07-18', 'media', 'en_progreso', TRUE, FALSE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   'Proyecto final: sistema de gestión de inventario',
   'Desarrollar en equipo un sistema de inventario aplicando POO y persistencia en BD.',
   '2026-08-05', 'alta', 'pendiente', TRUE, TRUE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1),
   'Consulta SQL con JOINs múltiples',
   'Escribir consultas con INNER JOIN, LEFT JOIN y subconsultas sobre la BD académica.',
   '2026-06-28', 'media', 'completada', FALSE, FALSE, TRUE, '2026-06-27', TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1),
   'Modelo entidad-relación proyecto final',
   'Diseñar el modelo E-R normalizado hasta 3FN para el proyecto final del curso.',
   '2026-07-20', 'alta', 'pendiente', TRUE, FALSE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1),
   'Taller de matrices y determinantes',
   'Ejercicios de operaciones con matrices, determinantes y matriz inversa.',
   '2026-06-30', 'media', 'completada', FALSE, FALSE, TRUE, '2026-06-29', TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1),
   'Ejercicios de espacios vectoriales',
   'Demostrar propiedades de subespacios vectoriales y bases.',
   '2026-07-25', 'baja', 'pendiente', FALSE, FALSE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1),
   'Ensayo argumentativo: technology in education',
   'Escribir un ensayo de 500 palabras sobre el impacto de la tecnología en la educación.',
   '2026-07-17', 'media', 'pendiente', TRUE, FALSE, FALSE, NULL, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1),
   'Análisis de caso: dilemas éticos en ingeniería',
   'Analizar un caso real de conflicto ético en el ejercicio profesional de la ingeniería.',
   '2026-07-05', 'baja', 'completada', FALSE, FALSE, TRUE, '2026-07-04', TRUE);

-- ============ HORARIOS ============
INSERT INTO horarios (id_estudiante, id_materia, dia, hora_inicio, hora_fin, aula, activo)
VALUES
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1), 'lunes', '07:00:00', '09:00:00', 'Bloque 6 - 205', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'lunes', '09:00:00', '11:00:00', 'Bloque 4 - 302', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'lunes', '11:00:00', '13:00:00', 'Bloque 4 - 210', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1), 'martes', '07:00:00', '09:00:00', 'Bloque 6 - 108', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1), 'martes', '09:00:00', '11:00:00', 'Bloque 2 - Idiomas 3', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'martes', '15:00:00', '17:00:00', 'Bloque 4 - Lab 1', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1), 'miercoles', '07:00:00', '09:00:00', 'Bloque 6 - 205', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'miercoles', '09:00:00', '11:00:00', 'Bloque 4 - Lab 2', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1), 'miercoles', '11:00:00', '13:00:00', 'Bloque 3 - 401', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1), 'jueves', '07:00:00', '09:00:00', 'Bloque 6 - 108', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1), 'jueves', '09:00:00', '11:00:00', 'Bloque 2 - Idiomas 3', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1), 'viernes', '09:00:00', '11:00:00', 'Bloque 3 - 401', TRUE);

-- ============ NOTAS (APUNTES) ============
INSERT INTO notas (id_estudiante, id_materia, titulo, contenido, etiquetas, favorito, activo)
VALUES
  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   'Resumen: reglas de derivación',
   'Regla de la cadena: (f(g(x)))'' = f''(g(x)) * g''(x). Regla del producto: (fg)'' = f''g + fg''. Regla del cociente: (f/g)'' = (f''g - fg'') / g^2. Repasar con ejemplos antes del segundo parcial, especialmente derivadas implícitas.',
   'derivadas,resumen,parcial1',
   TRUE, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   'Principios SOLID aplicados en Java',
   'S: responsabilidad única por clase. O: abierto a extensión, cerrado a modificación. L: sustitución de Liskov entre subtipos. I: interfaces segregadas y específicas. D: depender de abstracciones, no de implementaciones concretas. Aplicar en el proyecto de inventario.',
   'poo,solid,buenas-practicas',
   TRUE, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1),
   'Diferencias entre INNER JOIN y LEFT JOIN',
   'INNER JOIN retorna solo las filas que coinciden en ambas tablas. LEFT JOIN retorna todas las filas de la tabla izquierda aunque no haya coincidencia en la derecha, rellenando con NULL. Muy útil para reportes donde algunos registros pueden no tener relación aún.',
   'sql,joins',
   FALSE, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1),
   'Método de Gauss-Jordan paso a paso',
   'Llevar la matriz aumentada a su forma escalonada reducida usando operaciones elementales de fila: intercambio de filas, multiplicación por escalar no nulo y suma de un múltiplo de una fila a otra. Sirve para resolver sistemas y calcular la inversa de una matriz.',
   'algebra,matrices',
   FALSE, TRUE),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1),
   'Código de ética del ingeniero de sistemas en Colombia',
   'Principios clave: responsabilidad social, confidencialidad de la información, competencia profesional continua y no aceptar proyectos fuera del área de idoneidad. Revisar la ley que regula el ejercicio de la ingeniería en Colombia (Ley 842 de 2003).',
   'etica,colegiatura',
   FALSE, TRUE);

-- ============ EVENTOS DE CALENDARIO ============
INSERT INTO eventos_calendario (id_estudiante, id_materia, titulo, descripcion, fecha, hora_inicio, hora_fin, tipo, ubicacion, recordatorio, minutos_antes_recordatorio, todo_el_dia, color)
VALUES
  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   'Segundo parcial Cálculo Diferencial', 'Segundo corte: derivadas, integrales dobles.',
   '2026-07-21', '07:00:00', '09:00:00', 'examen', 'Bloque 6 - 205', TRUE, 60, FALSE, '#00D9A0'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1),
   'Parcial Bases de Datos', 'Segundo corte: modelo relacional, normalización y SQL.',
   '2026-07-23', '09:00:00', '11:00:00', 'examen', 'Bloque 4 - 210', TRUE, 60, FALSE, '#4D96FF'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   'Entrega proyecto final POO', 'Entrega del sistema de gestión de inventario en la plataforma del curso.',
   '2026-08-05', NULL, NULL, 'tarea', NULL, TRUE, 120, TRUE, '#FF6B6B'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1),
   'Entrega ensayo Inglés IV', 'Subir el ensayo argumentativo a la plataforma antes de medianoche.',
   '2026-07-17', NULL, NULL, 'tarea', NULL, TRUE, 60, TRUE, '#9B5DE5'),

  (@student_id, NULL,
   'Semana de receso académico', 'No hay clases — semana de receso institucional.',
   '2026-07-28', NULL, NULL, 'evento', 'Universidad de Córdoba', FALSE, 30, TRUE, '#2196F3'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1),
   'Foro de ética y tecnología', 'Foro abierto sobre dilemas éticos en inteligencia artificial.',
   '2026-07-30', '14:00:00', '16:00:00', 'evento', 'Auditorio Central', FALSE, 30, FALSE, '#00BBF9');

-- ============ SESIONES POMODORO ============
INSERT INTO sesiones_pomodoro (id_estudiante, id_materia, duracion_trabajo, duracion_descanso, fecha_inicio, fecha_fin, ciclos_completados, tiempo_total_estudio, completada, notas)
VALUES
  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1),
   25, 5, '2026-07-10 08:00:00', '2026-07-10 09:30:00', 3, 75, TRUE,
   'Repaso de derivadas antes del parcial.'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1),
   25, 5, '2026-07-11 15:00:00', '2026-07-11 15:50:00', 2, 50, TRUE,
   'Práctica de POO: diagrama de clases del proyecto de inventario.'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1),
   25, 5, '2026-07-12 10:00:00', '2026-07-12 11:15:00', 3, 75, TRUE,
   'Consultas SQL avanzadas con JOINs y subconsultas.'),

  (@student_id,
   (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1),
   25, 5, '2026-07-13 16:00:00', '2026-07-13 16:50:00', 2, 50, TRUE,
   'Repaso de matrices y determinantes.');

-- ============ CALIFICACIONES ============
-- Mezcla intencional de resultados (para ejercitar la proyección de nota
-- necesaria):
--   - Programación OOP        -> promedio >= 4.0, 100% evaluado
--   - Ética Profesional       -> promedio >= 4.0, 90% evaluado, aprobación
--                                 ya garantizada en el 10% restante
--   - Cálculo, Álgebra Lineal,
--     Inglés IV                -> promedio entre 3.0 y 3.9, 100% evaluado
--   - Bases de Datos          -> promedio < 3.0, 90% evaluado, matemáticamente
--                                 imposible de aprobar en el 10% restante
INSERT INTO calificaciones (id_estudiante, id_materia, tipo, descripcion, valor, porcentaje, fecha_evaluacion, activo)
VALUES
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1), 'parcial', 'Parcial 1er corte', 3.40, 40.00, '2026-06-15', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1), 'taller', 'Taller derivadas', 3.60, 30.00, '2026-06-20', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Cálculo Diferencial' LIMIT 1), 'quiz', 'Quiz límites y continuidad', 3.30, 30.00, '2026-07-02', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'parcial', 'Parcial 1er corte', 4.50, 30.00, '2026-06-18', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'parcial', 'Parcial 2do corte', 4.30, 30.00, '2026-07-09', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'taller', 'Taller patrones de diseño', 4.60, 20.00, '2026-06-25', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Programación Orientada a Objetos' LIMIT 1), 'proyecto', 'Avance proyecto corte 1', 4.20, 20.00, '2026-07-01', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'parcial', 'Parcial 1er corte', 2.50, 30.00, '2026-06-22', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'taller', 'Taller consultas SQL', 2.80, 20.00, '2026-06-28', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'quiz', 'Quiz normalización', 2.00, 20.00, '2026-07-05', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Bases de Datos' LIMIT 1), 'laboratorio', 'Laboratorio JOINs múltiples', 3.00, 20.00, '2026-07-10', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1), 'parcial', 'Parcial 1er corte', 3.70, 40.00, '2026-06-16', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1), 'taller', 'Taller matrices y determinantes', 3.90, 30.00, '2026-06-30', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Álgebra Lineal' LIMIT 1), 'quiz', 'Quiz vectores', 3.50, 30.00, '2026-07-03', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1), 'parcial', 'Parcial 1er corte', 3.20, 40.00, '2026-06-19', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1), 'taller', 'Taller ensayo argumentativo', 3.60, 30.00, '2026-06-29', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Inglés IV' LIMIT 1), 'quiz', 'Quiz vocabulario académico', 3.40, 30.00, '2026-07-04', TRUE),

  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1), 'parcial', 'Parcial 1er corte', 4.30, 40.00, '2026-06-21', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1), 'taller', 'Taller casos éticos', 4.00, 30.00, '2026-07-01', TRUE),
  (@student_id, (SELECT id FROM materias WHERE id_estudiante = @student_id AND nombre = 'Ética Profesional' LIMIT 1), 'quiz', 'Quiz normativa profesional', 4.40, 20.00, '2026-07-08', TRUE);

-- ============ NOTIFICACIONES ============
-- Fechas relativas a NOW() a propósito: permite probar que el feed
-- respeta fecha_programada (lo pasado se ve, lo futuro no) y los 3
-- filtros de la UI (Todas / Clases / Eventos = tarea+sistema+general).
INSERT INTO notificaciones (id_estudiante, tipo, titulo, mensaje, leida, referencia_tipo, referencia_id, fecha_programada, activo)
VALUES
  (@student_id, 'clase', 'Clase próxima a iniciar', 'Cálculo Diferencial · 07:00 - 09:00',
   FALSE, 'clase', NULL, DATE_SUB(NOW(), INTERVAL 3 HOUR), TRUE),

  (@student_id, 'clase', 'Clase próxima a iniciar', 'Programación Orientada a Objetos · 09:00 - 11:00',
   FALSE, 'clase', NULL, DATE_ADD(NOW(), INTERVAL 1 DAY), TRUE),

  (@student_id, 'clase', 'Clase próxima a iniciar', 'Bases de Datos · 11:00 - 13:00',
   FALSE, 'clase', NULL, DATE_ADD(NOW(), INTERVAL 8 DAY), TRUE),

  (@student_id, 'tarea', 'Tarea próxima a vencer', 'Taller integrales dobles',
   TRUE, 'tarea', NULL, DATE_SUB(NOW(), INTERVAL 1 DAY), TRUE),

  (@student_id, 'tarea', 'Tarea próxima a vencer', 'Ejercicios de espacios vectoriales',
   FALSE, 'tarea', NULL, DATE_ADD(NOW(), INTERVAL 2 DAY), TRUE),

  (@student_id, 'sistema', 'Bienvenida a Uniplan', 'Tu cuenta fue creada correctamente.',
   TRUE, NULL, NULL, DATE_SUB(NOW(), INTERVAL 10 DAY), TRUE),

  (@student_id, 'general', 'Recordatorio de racha', 'Llevás varios días seguidos usando Uniplan. ¡Seguí así!',
   FALSE, NULL, NULL, DATE_SUB(NOW(), INTERVAL 2 HOUR), TRUE);

-- ============ PREFERENCIAS DE NOTIFICACIÓN ============
INSERT INTO preferencias_notificacion (id_estudiante, notif_tareas, notif_clases, notif_generales, minutos_antes_tarea, minutos_antes_clase, sonido_activo)
VALUES
  (@student_id, TRUE, TRUE, TRUE, 60, 30, TRUE);

COMMIT;
