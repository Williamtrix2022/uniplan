-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database:  osorios-fastfood_uniplan_data
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `estudiantes`
--

DROP TABLE IF EXISTS `estudiantes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `estudiantes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `correo` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `contrasena` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `carrera` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `universidad` varchar(150) COLLATE utf8mb4_general_ci DEFAULT 'Universidad de Córdoba',
  `fecha_registro` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `correo` (`correo`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `estudiantes`
--

LOCK TABLES `estudiantes` WRITE;
/*!40000 ALTER TABLE `estudiantes` DISABLE KEYS */;
INSERT INTO `estudiantes` VALUES (1,'William Moya','william@unicordoba.edu.co','$2a$10$8beMKI75cE3OA1ryinOoOegvvr99wpjm2dfx.d8Yaj7Bsw1PecEze','Ingeniería de Sistemas','Universidad de Córdoba','2026-01-20 21:55:39',1),(2,'angel moya','angel@unicordoba.edu.co','$2a$10$uR/VYFFBmtEoW8Cq9Bv5cuXheA1KyLpZpPtHtuYKZZlYNVOqWPI4.','Ingeniería de Sistemas','Universidad de Córdoba','2026-01-21 20:59:08',1),(3,'angel','angel@gmail.com','$2a$10$hVUUc29EsPaPYbHH.SvgeeN9tGznvV93xbfO7tU0sHPBBtM9S4eTi',NULL,'Universidad de Córdoba','2026-01-21 21:34:07',1),(4,'angeldavid','angeldavid@gmail.com','$2a$10$P9QoMC/4Lsqz8wpaXhVLdeTj5mr0DVX3aZKyzhsasAi1rgazOH7jy',NULL,'Universidad de Córdoba','2026-01-25 01:54:39',1),(5,'prueba','prueba@gmail.com','$2a$10$tv3nAuyftYJAib.Jzia2ouft9ZPf7P/Id2l5chrrQa70/dYyTjf9C',NULL,'Universidad de Córdoba','2026-01-25 01:55:46',1),(6,'andres','andres@gmail.com','$2a$10$0QBcg1BzZbhXDqTSBfHp9.fGQy7WRDRyOzg5NRWdWPXWVHumQFDbW',NULL,'Universidad de Córdoba','2026-02-13 20:39:46',1),(7,'prueba1','prueba1@gmail.com','$2a$10$HO4/JvF2PF/knH/8iNUMC.AkoozJSPIMcBNfiDFxg9Oz4qKwK09Ci',NULL,'Universidad de Córdoba','2026-05-02 05:23:38',1),(8,'Jhon Quiceno','quicenojale@gmail.com','$2a$10$RMyfCOhqMGCYPP.4k/PSLO401czR6wqn9OUVFP.9KupbKuCA2t22O',NULL,'Universidad de Córdoba','2026-05-02 16:47:31',1);
/*!40000 ALTER TABLE `estudiantes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `eventos_calendario`
--

DROP TABLE IF EXISTS `eventos_calendario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eventos_calendario` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `id_materia` int DEFAULT NULL,
  `titulo` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_general_ci,
  `fecha` date NOT NULL,
  `hora_inicio` time DEFAULT NULL,
  `hora_fin` time DEFAULT NULL,
  `tipo` enum('clase','examen','tarea','evento','otro') COLLATE utf8mb4_general_ci DEFAULT 'evento',
  `ubicacion` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `recordatorio` tinyint(1) DEFAULT '0',
  `minutos_antes_recordatorio` int DEFAULT '30',
  `todo_el_dia` tinyint(1) DEFAULT '0',
  `color` varchar(7) COLLATE utf8mb4_general_ci DEFAULT '#2196F3',
  `activo` tinyint(1) DEFAULT '1',
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_materia` (`id_materia`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_fecha` (`fecha`),
  CONSTRAINT `eventos_calendario_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `eventos_calendario_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eventos_calendario`
--

LOCK TABLES `eventos_calendario` WRITE;
/*!40000 ALTER TABLE `eventos_calendario` DISABLE KEYS */;
INSERT INTO `eventos_calendario` VALUES (1,1,1,'Examen Final - Programación Web','Examen práctico de desarrollo web','2025-02-20','10:00:00','12:00:00','examen','Aula 301',1,60,0,'#F44336',1,'2026-01-20 23:54:21'),(2,5,NULL,'Clase de Fisica',NULL,'2026-01-29','10:00:00','00:00:00','clase','Salon 301',0,30,0,'#2196F3',0,'2026-01-28 22:32:05');
/*!40000 ALTER TABLE `eventos_calendario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `materias`
--

DROP TABLE IF EXISTS `materias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `materias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `codigo` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `profesor` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `semestre` int DEFAULT NULL,
  `creditos` int DEFAULT '3',
  `horario` text COLLATE utf8mb4_general_ci,
  `color` varchar(7) COLLATE utf8mb4_general_ci DEFAULT '#4CAF50',
  `activo` tinyint(1) DEFAULT '1',
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_estudiante` (`id_estudiante`),
  CONSTRAINT `materias_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `materias`
--

LOCK TABLES `materias` WRITE;
/*!40000 ALTER TABLE `materias` DISABLE KEYS */;
INSERT INTO `materias` VALUES (1,1,'Programación Web','SIS-301','Dr. García',5,4,'Lunes y Miércoles 10:00-12:00','#2196F3',1,'2026-01-20 22:46:49');
/*!40000 ALTER TABLE `materias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notas`
--

DROP TABLE IF EXISTS `notas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `id_materia` int DEFAULT NULL,
  `titulo` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `contenido` text COLLATE utf8mb4_general_ci NOT NULL,
  `etiquetas` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `favorito` tinyint(1) DEFAULT '0',
  `activo` tinyint(1) DEFAULT '1',
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_materia` (`id_materia`),
  CONSTRAINT `notas_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `notas_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notas`
--

LOCK TABLES `notas` WRITE;
/*!40000 ALTER TABLE `notas` DISABLE KEYS */;
INSERT INTO `notas` VALUES (1,1,1,'Apuntes de Arquitectura REST','API REST: Representational State Transfer. Usa HTTP methods: GET, POST, PUT, DELETE. Stateless: cada petición es independiente.','arquitectura, api, rest',1,1,'2026-01-20 23:11:42','2026-01-20 23:11:42');
/*!40000 ALTER TABLE `notas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `used_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_token_hash` (`token_hash`),
  KEY `idx_student_id` (`student_id`),
  CONSTRAINT `fk_password_resets_student` FOREIGN KEY (`student_id`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
INSERT INTO `password_resets` VALUES (1,8,'381db8702d8ed57cbb97c224a5e80a9624c0e0cee365b4d31630218c011a863a','2026-05-02 12:17:56',1,'2026-05-02 16:47:56','2026-05-02 12:02:59'),(2,8,'e739a2bd2bc8674ceec6ad099d324a44b40c8dfbdceb25cda26546b502c72921','2026-05-02 12:33:00',1,'2026-05-02 17:02:59','2026-05-02 12:06:20');
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `progreso_academico`
--

DROP TABLE IF EXISTS `progreso_academico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `progreso_academico` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `fecha` date NOT NULL,
  `tareas_completadas` int DEFAULT '0',
  `minutos_estudiados` int DEFAULT '0',
  `sesiones_pomodoro` int DEFAULT '0',
  `promedio_productividad` decimal(5,2) DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_estudiante_fecha` (`id_estudiante`,`fecha`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_fecha` (`fecha`),
  CONSTRAINT `progreso_academico_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `progreso_academico`
--

LOCK TABLES `progreso_academico` WRITE;
/*!40000 ALTER TABLE `progreso_academico` DISABLE KEYS */;
/*!40000 ALTER TABLE `progreso_academico` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesiones_pomodoro`
--

DROP TABLE IF EXISTS `sesiones_pomodoro`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesiones_pomodoro` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `id_materia` int DEFAULT NULL,
  `duracion_trabajo` int DEFAULT '25',
  `duracion_descanso` int DEFAULT '5',
  `ciclos_completados` int DEFAULT '0',
  `tiempo_total_estudio` int DEFAULT '0',
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `completada` tinyint(1) DEFAULT '0',
  `notas` text COLLATE utf8mb4_general_ci,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_materia` (`id_materia`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_fecha` (`fecha_inicio`),
  CONSTRAINT `sesiones_pomodoro_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sesiones_pomodoro_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesiones_pomodoro`
--

LOCK TABLES `sesiones_pomodoro` WRITE;
/*!40000 ALTER TABLE `sesiones_pomodoro` DISABLE KEYS */;
INSERT INTO `sesiones_pomodoro` VALUES (1,1,NULL,25,5,4,100,'2026-01-20 18:16:25','2026-01-20 18:19:52',1,NULL,'2026-01-20 23:16:25'),(2,1,1,25,5,0,0,'2026-01-20 18:18:16',NULL,0,'Sesión de estudio para el proyecto final','2026-01-20 23:18:16'),(3,5,NULL,25,5,0,0,'2026-01-26 20:51:42',NULL,0,NULL,'2026-01-27 01:51:42'),(4,5,NULL,25,5,0,0,'2026-01-26 20:51:58',NULL,0,NULL,'2026-01-27 01:51:58'),(5,5,NULL,25,5,0,0,'2026-01-26 20:52:10',NULL,0,NULL,'2026-01-27 01:52:10'),(6,5,NULL,25,5,0,0,'2026-01-26 20:52:55',NULL,0,NULL,'2026-01-27 01:52:55'),(7,5,NULL,25,5,0,0,'2026-01-26 20:53:04',NULL,0,NULL,'2026-01-27 01:53:04'),(8,5,NULL,25,5,0,0,'2026-01-27 23:38:46',NULL,0,NULL,'2026-01-28 04:38:46'),(9,7,NULL,25,5,0,0,'2026-05-02 00:23:45','2026-05-02 00:24:11',1,NULL,'2026-05-02 05:23:45');
/*!40000 ALTER TABLE `sesiones_pomodoro` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tareas`
--

DROP TABLE IF EXISTS `tareas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tareas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_estudiante` int NOT NULL,
  `id_materia` int DEFAULT NULL,
  `titulo` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_general_ci,
  `fecha_entrega` date NOT NULL,
  `prioridad` enum('baja','media','alta') COLLATE utf8mb4_general_ci DEFAULT 'media',
  `estado` enum('pendiente','en_progreso','completada') COLLATE utf8mb4_general_ci DEFAULT 'pendiente',
  `recordatorio` tinyint(1) DEFAULT '0',
  `fecha_recordatorio` datetime DEFAULT NULL,
  `completada` tinyint(1) DEFAULT '0',
  `fecha_completada` datetime DEFAULT NULL,
  `activo` tinyint(1) DEFAULT '1',
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_estudiante` (`id_estudiante`),
  KEY `idx_materia` (`id_materia`),
  KEY `idx_fecha_entrega` (`fecha_entrega`),
  CONSTRAINT `tareas_ibfk_1` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiantes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tareas_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tareas`
--

LOCK TABLES `tareas` WRITE;
/*!40000 ALTER TABLE `tareas` DISABLE KEYS */;
INSERT INTO `tareas` VALUES (1,1,1,'Proyecto Final - App Móvil','Desarrollar aplicación completa con Flutter','2025-02-15','alta','completada',0,NULL,1,'2026-01-20 17:55:54',1,'2026-01-20 22:48:30'),(2,1,NULL,'Math Homework','Capítulo 5 ejercicios','2025-01-25','alta','pendiente',0,NULL,0,NULL,1,'2026-01-25 03:07:45'),(3,5,NULL,'Proyecto 1','Analizar y estructurar el proyecto','2026-01-26','media','pendiente',0,NULL,0,NULL,0,'2026-01-27 00:45:34'),(4,5,NULL,'Proyecto 2','estructurar bien los procesos del proyecto','2026-01-26','alta','pendiente',0,NULL,0,NULL,0,'2026-01-27 00:46:46'),(5,5,NULL,'Estudiar matemáticas','Capítulo 5 y 6','2026-01-26','alta','completada',0,NULL,0,NULL,1,'2026-01-27 01:03:03'),(6,5,NULL,'Examen de Calculo','Estudiar derivadas e integrales','2026-01-27','alta','pendiente',0,NULL,0,NULL,1,'2026-01-27 01:07:15'),(7,5,NULL,'Proyecto de Base de Datos','Diseñar modelo ER','2026-01-30','media','pendiente',0,NULL,0,NULL,1,'2026-01-27 01:07:49'),(8,5,NULL,'Lectura Capítulo 8',NULL,'2026-02-05','media','pendiente',0,NULL,0,NULL,1,'2026-01-27 01:08:53'),(9,7,NULL,'repasar programación','puro excel','2026-05-09','media','pendiente',0,NULL,0,NULL,1,'2026-05-02 05:24:57');
/*!40000 ALTER TABLE `tareas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'uniplan_database'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-02 14:13:45
