-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: mysql-osorios-fastfood.alwaysdata.net
-- Generation Time: Jun 24, 2026 at 11:23 PM
-- Server version: 10.11.18-MariaDB
-- PHP Version: 8.4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `osorios-fastfood_uniplan_data`
--

-- --------------------------------------------------------

--
-- Table structure for table `estudiantes`
--

CREATE TABLE `estudiantes` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `contrasena` varchar(255) NOT NULL,
  `carrera` varchar(100) DEFAULT NULL,
  `universidad` varchar(150) DEFAULT 'Universidad de Córdoba',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  `activo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `estudiantes`
--

INSERT INTO `estudiantes` (`id`, `nombre`, `correo`, `contrasena`, `carrera`, `universidad`, `fecha_registro`, `activo`) VALUES
(1, 'William Moya', 'william@unicordoba.edu.co', '$2a$10$8beMKI75cE3OA1ryinOoOegvvr99wpjm2dfx.d8Yaj7Bsw1PecEze', 'Ingeniería de Sistemas', 'Universidad de Córdoba', '2026-01-20 21:55:39', 1),
(2, 'angel moya', 'angel@unicordoba.edu.co', '$2a$10$uR/VYFFBmtEoW8Cq9Bv5cuXheA1KyLpZpPtHtuYKZZlYNVOqWPI4.', 'Ingeniería de Sistemas', 'Universidad de Córdoba', '2026-01-21 20:59:08', 1),
(3, 'angel', 'angel@gmail.com', '$2a$10$hVUUc29EsPaPYbHH.SvgeeN9tGznvV93xbfO7tU0sHPBBtM9S4eTi', NULL, 'Universidad de Córdoba', '2026-01-21 21:34:07', 1),
(4, 'angeldavid', 'angeldavid@gmail.com', '$2a$10$P9QoMC/4Lsqz8wpaXhVLdeTj5mr0DVX3aZKyzhsasAi1rgazOH7jy', NULL, 'Universidad de Córdoba', '2026-01-25 01:54:39', 1),
(5, 'prueba', 'prueba@gmail.com', '$2a$10$tv3nAuyftYJAib.Jzia2ouft9ZPf7P/Id2l5chrrQa70/dYyTjf9C', NULL, 'Universidad de Córdoba', '2026-01-25 01:55:46', 1),
(6, 'andres', 'andres@gmail.com', '$2a$10$0QBcg1BzZbhXDqTSBfHp9.fGQy7WRDRyOzg5NRWdWPXWVHumQFDbW', NULL, 'Universidad de Córdoba', '2026-02-13 20:39:46', 1),
(7, 'prueba1', 'prueba1@gmail.com', '$2a$10$HO4/JvF2PF/knH/8iNUMC.AkoozJSPIMcBNfiDFxg9Oz4qKwK09Ci', NULL, 'Universidad de Córdoba', '2026-05-02 05:23:38', 1),
(8, 'Jhon Quiceno', 'quicenojale@gmail.com', '$2a$10$ab3mLHHsrzJiKZvqn6lbnOajcxKgqIHGQXANwxWPfDNNq8Iu3twh2', NULL, 'Universidad de Córdoba', '2026-05-02 16:47:31', 1);

-- --------------------------------------------------------

--
-- Table structure for table `eventos_calendario`
--

CREATE TABLE `eventos_calendario` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `id_materia` int(11) DEFAULT NULL,
  `titulo` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `fecha` date NOT NULL,
  `hora_inicio` time DEFAULT NULL,
  `hora_fin` time DEFAULT NULL,
  `tipo` enum('clase','examen','tarea','evento','otro') DEFAULT 'evento',
  `ubicacion` varchar(150) DEFAULT NULL,
  `recordatorio` tinyint(1) DEFAULT 0,
  `minutos_antes_recordatorio` int(11) DEFAULT 30,
  `todo_el_dia` tinyint(1) DEFAULT 0,
  `color` varchar(7) DEFAULT '#2196F3',
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `eventos_calendario`
--

INSERT INTO `eventos_calendario` (`id`, `id_estudiante`, `id_materia`, `titulo`, `descripcion`, `fecha`, `hora_inicio`, `hora_fin`, `tipo`, `ubicacion`, `recordatorio`, `minutos_antes_recordatorio`, `todo_el_dia`, `color`, `activo`, `fecha_creacion`) VALUES
(1, 1, 1, 'Examen Final - Programación Web', 'Examen práctico de desarrollo web', '2025-02-20', '10:00:00', '12:00:00', 'examen', 'Aula 301', 1, 60, 0, '#F44336', 1, '2026-01-20 23:54:21'),
(2, 5, NULL, 'Clase de Fisica', NULL, '2026-01-29', '10:00:00', '00:00:00', 'clase', 'Salon 301', 0, 30, 0, '#2196F3', 0, '2026-01-28 22:32:05'),
(3, 8, NULL, 'parcial de métodos numéricos', 'todos los fundamentos', '2026-05-14', NULL, NULL, 'evento', NULL, 0, 30, 1, '#F44336', 1, '2026-05-07 15:08:48'),
(4, 8, NULL, 'clase de calculo', NULL, '2026-06-06', NULL, NULL, 'examen', 'Aula 203', 0, 30, 1, '#4CAF50', 1, '2026-06-07 02:37:15'),
(5, 8, NULL, 'examen de programación', 'bucles', '2026-06-17', '19:00:00', '20:00:00', 'examen', 'salón 203', 0, 30, 0, '#4CAF50', 1, '2026-06-07 02:49:53');

-- --------------------------------------------------------

--
-- Table structure for table `horarios`
--

CREATE TABLE `horarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_estudiante` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `dia` enum('lunes','martes','miercoles','jueves','viernes','sabado','domingo') NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL,
  `aula` varchar(100) DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_materia` (`id_materia`),
  KEY `idx_estudiante_dia` (`id_estudiante`,`dia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `materias`
--

CREATE TABLE `materias` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `codigo` varchar(20) DEFAULT NULL,
  `profesor` varchar(100) DEFAULT NULL,
  `semestre` int(11) DEFAULT NULL,
  `creditos` int(11) DEFAULT 3,
  `horario` text DEFAULT NULL,
  `color` varchar(7) DEFAULT '#4CAF50',
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `materias`
--

INSERT INTO `materias` (`id`, `id_estudiante`, `nombre`, `codigo`, `profesor`, `semestre`, `creditos`, `horario`, `color`, `activo`, `fecha_creacion`) VALUES
(1, 1, 'Programación Web', 'SIS-301', 'Dr. García', 5, 4, 'Lunes y Miércoles 10:00-12:00', '#2196F3', 1, '2026-01-20 22:46:49'),
(4, 8, 'Inglés', '1234', NULL, NULL, 3, NULL, '#4CAF50', 1, '2026-05-05 23:19:16'),
(7, 8, 'sociales', '9999', NULL, NULL, 3, NULL, '#4CAF50', 1, '2026-05-06 22:43:48'),
(10, 8, 'matemáticas', NULL, NULL, NULL, 3, NULL, '#4CAF50', 1, '2026-05-07 04:38:54'),
(11, 8, 'prueba', '1234', NULL, NULL, 3, NULL, '#4CAF50', 1, '2026-06-07 05:32:54');

-- --------------------------------------------------------

--
-- Table structure for table `notas`
--

CREATE TABLE `notas` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `id_materia` int(11) DEFAULT NULL,
  `titulo` varchar(150) NOT NULL,
  `contenido` text NOT NULL,
  `etiquetas` varchar(255) DEFAULT NULL,
  `favorito` tinyint(1) DEFAULT 0,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notas`
--

INSERT INTO `notas` (`id`, `id_estudiante`, `id_materia`, `titulo`, `contenido`, `etiquetas`, `favorito`, `activo`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 1, 1, 'Apuntes de Arquitectura REST', 'API REST: Representational State Transfer. Usa HTTP methods: GET, POST, PUT, DELETE. Stateless: cada petición es independiente.', 'arquitectura, api, rest', 1, 1, '2026-01-20 23:11:42', '2026-01-20 23:11:42');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `used_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `student_id`, `token_hash`, `expires_at`, `used`, `created_at`, `used_at`) VALUES
(1, 8, '381db8702d8ed57cbb97c224a5e80a9624c0e0cee365b4d31630218c011a863a', '2026-05-02 12:17:56', 1, '2026-05-02 16:47:56', '2026-05-02 12:02:59'),
(2, 8, 'e739a2bd2bc8674ceec6ad099d324a44b40c8dfbdceb25cda26546b502c72921', '2026-05-02 12:33:00', 1, '2026-05-02 17:02:59', '2026-05-02 12:06:20'),
(3, 8, '5ee1fbf612d33575f03331b09a3490e8c44f1ceaca00696babb59036b368b72a', '2026-05-06 19:16:44', 1, '2026-05-06 23:46:46', '2026-05-07 01:46:51'),
(4, 8, '6253c8cfbb17b114c34ddbceb8e8a24e44c22f261f9ff095202739d630193d23', '2026-05-06 19:16:50', 1, '2026-05-06 23:46:51', '2026-05-07 02:09:12'),
(5, 8, '754e870de3e65f342a0e7c6d671af7e889238b195444c87576e1cdea6a798fe7', '2026-05-06 19:39:12', 1, '2026-05-07 00:09:13', '2026-05-07 02:10:41'),
(6, 8, '6472c4fd3f011d5ddb3953567f3e542f2e76488c819410e7bec61d5408151e67', '2026-05-06 19:40:40', 0, '2026-05-07 00:10:41', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `progreso_academico`
--

CREATE TABLE `progreso_academico` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `tareas_completadas` int(11) DEFAULT 0,
  `minutos_estudiados` int(11) DEFAULT 0,
  `sesiones_pomodoro` int(11) DEFAULT 0,
  `promedio_productividad` decimal(5,2) DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sesiones_pomodoro`
--

CREATE TABLE `sesiones_pomodoro` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `id_materia` int(11) DEFAULT NULL,
  `duracion_trabajo` int(11) DEFAULT 25,
  `duracion_descanso` int(11) DEFAULT 5,
  `ciclos_completados` int(11) DEFAULT 0,
  `tiempo_total_estudio` int(11) DEFAULT 0,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `completada` tinyint(1) DEFAULT 0,
  `notas` text DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sesiones_pomodoro`
--

INSERT INTO `sesiones_pomodoro` (`id`, `id_estudiante`, `id_materia`, `duracion_trabajo`, `duracion_descanso`, `ciclos_completados`, `tiempo_total_estudio`, `fecha_inicio`, `fecha_fin`, `completada`, `notas`, `fecha_creacion`) VALUES
(1, 1, NULL, 25, 5, 4, 100, '2026-01-20 18:16:25', '2026-01-20 18:19:52', 1, NULL, '2026-01-20 23:16:25'),
(2, 1, 1, 25, 5, 0, 0, '2026-01-20 18:18:16', NULL, 0, 'Sesión de estudio para el proyecto final', '2026-01-20 23:18:16'),
(3, 5, NULL, 25, 5, 0, 0, '2026-01-26 20:51:42', NULL, 0, NULL, '2026-01-27 01:51:42'),
(4, 5, NULL, 25, 5, 0, 0, '2026-01-26 20:51:58', NULL, 0, NULL, '2026-01-27 01:51:58'),
(5, 5, NULL, 25, 5, 0, 0, '2026-01-26 20:52:10', NULL, 0, NULL, '2026-01-27 01:52:10'),
(6, 5, NULL, 25, 5, 0, 0, '2026-01-26 20:52:55', NULL, 0, NULL, '2026-01-27 01:52:55'),
(7, 5, NULL, 25, 5, 0, 0, '2026-01-26 20:53:04', NULL, 0, NULL, '2026-01-27 01:53:04'),
(8, 5, NULL, 25, 5, 0, 0, '2026-01-27 23:38:46', NULL, 0, NULL, '2026-01-28 04:38:46'),
(9, 7, NULL, 25, 5, 0, 0, '2026-05-02 00:23:45', '2026-05-02 00:24:11', 1, NULL, '2026-05-02 05:23:45'),
(10, 8, NULL, 25, 5, 0, 0, '2026-05-05 16:57:37', NULL, 0, NULL, '2026-05-05 21:57:36'),
(11, 8, NULL, 25, 5, 0, 0, '2026-05-05 16:57:50', NULL, 0, NULL, '2026-05-05 21:57:49'),
(12, 8, NULL, 25, 5, 0, 0, '2026-05-06 18:52:29', NULL, 0, NULL, '2026-05-06 23:52:30'),
(13, 8, NULL, 25, 5, 0, 0, '2026-05-06 19:20:18', NULL, 0, NULL, '2026-05-07 00:20:19'),
(14, 8, 7, 25, 5, 0, 0, '2026-06-16 15:25:37', NULL, 0, NULL, '2026-06-16 20:25:35'),
(15, 8, 7, 25, 5, 0, 0, '2026-06-16 15:25:38', NULL, 0, NULL, '2026-06-16 20:25:36'),
(16, 8, 7, 25, 5, 0, 0, '2026-06-16 15:26:26', '2026-06-16 22:26:30', 1, NULL, '2026-06-16 20:26:23');

-- --------------------------------------------------------

--
-- Table structure for table `tareas`
--

CREATE TABLE `tareas` (
  `id` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `id_materia` int(11) DEFAULT NULL,
  `titulo` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `fecha_entrega` date NOT NULL,
  `prioridad` enum('baja','media','alta') DEFAULT 'media',
  `es_proyecto` tinyint(1) NOT NULL DEFAULT 0,
  `estado` enum('pendiente','en_progreso','completada') DEFAULT 'pendiente',
  `recordatorio` tinyint(1) DEFAULT 0,
  `fecha_recordatorio` datetime DEFAULT NULL,
  `completada` tinyint(1) DEFAULT 0,
  `fecha_completada` datetime DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tareas`
--

INSERT INTO `tareas` (`id`, `id_estudiante`, `id_materia`, `titulo`, `descripcion`, `fecha_entrega`, `prioridad`, `es_proyecto`, `estado`, `recordatorio`, `fecha_recordatorio`, `completada`, `fecha_completada`, `activo`, `fecha_creacion`) VALUES
(1, 1, 1, 'Proyecto Final - App Móvil', 'Desarrollar aplicación completa con Flutter', '2025-02-15', 'alta', 0, 'completada', 0, NULL, 1, '2026-01-20 17:55:54', 1, '2026-01-20 22:48:30'),
(2, 1, NULL, 'Math Homework', 'Capítulo 5 ejercicios', '2025-01-25', 'alta', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-01-25 03:07:45'),
(3, 5, NULL, 'Proyecto 1', 'Analizar y estructurar el proyecto', '2026-01-26', 'media', 0, 'pendiente', 0, NULL, 0, NULL, 0, '2026-01-27 00:45:34'),
(4, 5, NULL, 'Proyecto 2', 'estructurar bien los procesos del proyecto', '2026-01-26', 'alta', 0, 'pendiente', 0, NULL, 0, NULL, 0, '2026-01-27 00:46:46'),
(5, 5, NULL, 'Estudiar matemáticas', 'Capítulo 5 y 6', '2026-01-26', 'alta', 0, 'completada', 0, NULL, 0, NULL, 1, '2026-01-27 01:03:03'),
(6, 5, NULL, 'Examen de Calculo', 'Estudiar derivadas e integrales', '2026-01-27', 'alta', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-01-27 01:07:15'),
(7, 5, NULL, 'Proyecto de Base de Datos', 'Diseñar modelo ER', '2026-01-30', 'media', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-01-27 01:07:49'),
(8, 5, NULL, 'Lectura Capítulo 8', NULL, '2026-02-05', 'media', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-01-27 01:08:53'),
(9, 7, NULL, 'repasar programación', 'puro excel', '2026-05-09', 'media', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-05-02 05:24:57'),
(10, 8, 4, 'examen de metodologia', 'próxima semana', '2026-05-08', 'media', 0, 'completada', 0, NULL, 1, '2026-06-06 20:20:27', 0, '2026-05-05 21:52:40'),
(11, 8, 4, 'prueba', 'prueba', '2026-05-05', 'alta', 0, 'completada', 0, NULL, 1, '2026-06-06 20:20:26', 0, '2026-05-05 21:56:34'),
(12, 8, 4, 'Estudiar parcial', 'los objetivos', '2026-05-08', 'baja', 1, 'completada', 0, NULL, 0, NULL, 0, '2026-05-06 23:48:57'),
(13, 8, NULL, 'Taller emprendimiento', 'toca hacerla antes del jueves 26 de mayo.', '2026-05-06', 'media', 0, 'pendiente', 0, NULL, 0, NULL, 0, '2026-05-07 00:22:53'),
(14, 8, 7, 'prueba técnica', 'todos los conceptos', '2026-05-28', 'alta', 0, 'pendiente', 0, NULL, 0, NULL, 0, '2026-05-07 21:37:00'),
(15, 8, NULL, 'aprendizaje computacional', 'taller en weka', '2026-05-09', 'alta', 0, 'completada', 0, NULL, 1, '2026-06-06 20:20:34', 0, '2026-05-08 16:26:31'),
(16, 8, 7, 'hacer trabajo de For y Eva', 'todo el trabajo final', '2026-06-13', 'baja', 0, 'pendiente', 0, NULL, 0, NULL, 1, '2026-06-07 02:38:52'),
(17, 8, 11, 'hjkk', 'dufhc', '2026-06-07', 'baja', 0, 'pendiente', 0, NULL, 0, NULL, 0, '2026-06-07 05:33:10');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `estudiantes`
--
ALTER TABLE `estudiantes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indexes for table `eventos_calendario`
--
ALTER TABLE `eventos_calendario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_materia` (`id_materia`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_fecha` (`fecha`);

--
-- Indexes for table `materias`
--
ALTER TABLE `materias`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_estudiante` (`id_estudiante`);

--
-- Indexes for table `notas`
--
ALTER TABLE `notas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_materia` (`id_materia`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_token_hash` (`token_hash`),
  ADD KEY `idx_student_id` (`student_id`);

--
-- Indexes for table `progreso_academico`
--
ALTER TABLE `progreso_academico`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_estudiante_fecha` (`id_estudiante`,`fecha`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_fecha` (`fecha`);

--
-- Indexes for table `sesiones_pomodoro`
--
ALTER TABLE `sesiones_pomodoro`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_materia` (`id_materia`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_fecha` (`fecha_inicio`);

--
-- Indexes for table `horarios`
--
ALTER TABLE `horarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_materia` (`id_materia`),
  ADD KEY `idx_estudiante_dia` (`id_estudiante`,`dia`);

--
-- Indexes for table `tareas`
--
ALTER TABLE `tareas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_estudiante` (`id_estudiante`),
  ADD KEY `idx_materia` (`id_materia`),
  ADD KEY `idx_fecha_entrega` (`fecha_entrega`),
  ADD KEY `idx_tareas_es_proyecto` (`es_proyecto`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `estudiantes`
--
ALTER TABLE `estudiantes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `eventos_calendario`
--
ALTER TABLE `eventos_calendario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `materias`
--
ALTER TABLE `materias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `notas`
--
ALTER TABLE `notas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `progreso_academico`
--
ALTER TABLE `progreso_academico`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sesiones_pomodoro`
--
ALTER TABLE `sesiones_pomodoro`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `horarios`
--
ALTER TABLE `horarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tareas`
--
ALTER TABLE `tareas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `eventos_calendario`
--
ALTER TABLE `eventos_calendario`
  ADD CONSTRAINT `eventos_calendario_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `eventos_calendario_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `materias`
--
ALTER TABLE `materias`
  ADD CONSTRAINT `materias_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notas`
--
ALTER TABLE `notas`
  ADD CONSTRAINT `notas_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notas_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `fk_password_resets_student` FOREIGN KEY (`student_id`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `progreso_academico`
--
ALTER TABLE `progreso_academico`
  ADD CONSTRAINT `progreso_academico_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sesiones_pomodoro`
--
ALTER TABLE `sesiones_pomodoro`
  ADD CONSTRAINT `sesiones_pomodoro_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `sesiones_pomodoro_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `horarios`
--
ALTER TABLE `horarios`
  ADD CONSTRAINT `horarios_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `horarios_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tareas`
--
ALTER TABLE `tareas`
  ADD CONSTRAINT `tareas_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tareas_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
