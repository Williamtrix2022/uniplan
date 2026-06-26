# 🎓 Uniplan — Especificación Completa del MVP
> **Aplicación móvil para la organización académica y gestión del estudio universitario**
> Universidad de Córdoba · Ingeniería de Sistemas

---

## 📋 Leyenda de Estados

| Símbolo | Estado |
|---------|--------|
| ✅ | Completado |
| 🔄 | En Progreso |
| ⬜ | Pendiente |
| ❌ | Bloqueado |
| ⏸️ | Pausado |

---

## 📊 Progreso General del MVP

| Sprint | Módulo | Progreso Actual | Estado |
|--------|--------|----------------|--------|
| Sprint 1 | Autenticación y UI Base | 71% (25/35) | 🔄 En Progreso |
| Sprint 2 | Gestión de Tareas | 100% (41/41) | ✅ Completado |
| Sprint 3 | Gestión de Horarios | 89% (25/28) | ✅ Completado |
| Sprint 4 | Sistema de Calificaciones | 0% (0/33) | ⬜ Pendiente |
| Sprint 5 | Notificaciones y Sincronización | 0% (0/28) | ⬜ Pendiente |
| Sprint 6 | UI/UX Avanzado | 0% (0/30) | ⬜ Pendiente |
| Sprint 7 | Estadísticas, Tests y Docs | 5% (2/39) | 🔄 En Progreso |
| **TOTAL** | | **39% (92/234)** | 🔄 |

---

## 🏗️ ARQUITECTURA Y STACK TECNOLÓGICO

### Frontend
- ✅ Flutter (SDK móvil multiplataforma Android/iOS)
- ⬜ Gestión de estado con Provider
- ⬜ Navegación con rutas nombradas
- 🔄 Sistema de temas (claro/oscuro)
- 🔄 Widgets reutilizables centralizados

### Backend / Infraestructura
- ✅ API REST Node.js + Express + JWT implementada
- ✅ Base de datos MySQL conectada y en uso
- ✅ Middleware de autenticación JWT aplicado en rutas protegidas
- ✅ CRUDs principales implementados (students, subjects, tasks, notes, pomodoro, calendar, dashboard, schedules)
- ✅ CORS, parseo JSON y health check operativos
- 🔄 Notificaciones push/locales (pendiente implementación)
- 🔄 Jobs programados/automatizaciones (pendiente implementación)
- ⬜ Monitoreo avanzado (analytics/crash/performance)

> **Nota de seguimiento:** el stack activo del proyecto es **Node.js + Express + MySQL + JWT**.  
> Firebase no forma parte del alcance actual del MVP.

### Base de Datos — Esquema MySQL actual
- ✅ Tabla `estudiantes` (auth/perfil)
- ✅ Tabla `materias` (asignaturas por estudiante)
- ✅ Tabla `tareas` (gestión de pendientes y entregas)
- ✅ Tabla `notas` (apuntes y favoritos)
- ✅ Tabla `eventos_calendario` (agenda académica)
- ✅ Tabla `sesiones_pomodoro` (sesiones de estudio)
- ✅ Tabla `horarios` (bloques de clase recurrentes con detección de conflictos)
- 🔄 Tabla/estructura de `progreso_academico` y métricas extendidas
- ✅ Integración backend-modelos operativa con consultas SQL

---

## 🏃 SPRINT 1 — Autenticación y UI Base `Semanas 1-2`

### 🎨 Frontend — Autenticación

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Pantalla de Login con diseño mejorado | Alta | 4h |
| ✅ | Validación de formularios en Login | Alta | 2h |
| ✅ | Animaciones de entrada en Login | Media | 2h |
| ✅ | Pantalla de Registro | Alta | 4h |
| ✅ | Validación de formularios en Registro | Alta | 2h |
| ⬜ | Pantalla de Recuperación de Contraseña | Alta | 3h |
| ⬜ | Validación de email en Recuperación | Alta | 1h |
| ✅ | Mensajes de confirmación al usuario | Media | 1h |

### 🎨 Frontend — Navegación Principal

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Bottom Navigation Bar (barra inferior) | Alta | 3h |
| ✅ | Configurar rutas principales de la app | Alta | 2h |
| 🔄 | Transiciones animadas entre pantallas | Media | 2h |
| ✅ | Splash Screen animado (pantalla de carga) | Media | 3h |
| ⬜ | Onboarding para usuarios nuevos (primera vez) | Baja | 4h |

### 🎨 Frontend — Componentes Base Reutilizables

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | CustomButton (botón personalizado) | Alta | 2h |
| ✅ | CustomTextField (campo de texto personalizado) | Alta | 2h |
| ⬜ | CustomCard (tarjeta reutilizable) | Alta | 2h |
| ⬜ | LoadingIndicator (indicador de carga) | Alta | 1h |
| ⬜ | EmptyState (pantalla de estado vacío) | Media | 2h |
| ⬜ | ErrorState (pantalla de error) | Media | 2h |

### 🔧 Backend — Setup API Node.js + MySQL

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | API Express inicial creada y estructurada por módulos | Alta | 1h |
| ✅ | JWT Authentication configurada (login/register/profile) | Alta | 1h |
| ✅ | Base de datos MySQL configurada y conectada | Alta | 2h |
| ✅ | Modelos principales creados (Student, Task, Subject, Note, Pomodoro, Calendar) | Alta | 2h |
| ✅ | Rutas REST protegidas con middleware de auth | Alta | 2h |
| ✅ | Endpoints de estadísticas (dashboard/tasks/pomodoro/calendar) | Media | 1h |
| ✅ | Health check y middlewares globales (CORS, JSON, URL-encoded) | Media | 1h |
| ✅ | Estructura de proyecto documentada en backend/README | Baja | 1h |

### 🔧 Backend — AuthService

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | AuthService — Login con email/contraseña | Alta | 2h |
| ✅ | AuthService — Register (registro de usuario) | Alta | 2h |
| ✅ | AuthService — Logout (cerrar sesión) | Alta | 1h |
| ✅ | AuthService — Password Reset (recuperar contraseña) | Alta | 2h |
| 🔄 | AuthService — Update Profile (actualizar perfil; cambio de contraseña desde perfil listo) | Media | 2h |

### 🔧 Cliente Mobile — ApiService Base

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | ApiService — CRUD HTTP genérico (GET/POST/PUT/PATCH/DELETE) | Alta | 3h |
| ✅ | ApiService — Manejo de errores HTTP y excepciones de red | Alta | 2h |
| ⬜ | ApiService — Soporte offline | Baja | 3h |

> **🎯 Objetivo Sprint 1:** Flujo de autenticación funcional (login, registro, recuperación), navegación principal operativa y componentes base listos para siguientes sprints.

> **Progreso:** 🔄 25/35 tareas (71%)

---

## 🏃 SPRINT 2 — Gestión de Tareas `Semanas 3-4`

### 🎨 Frontend — Pantallas de Tareas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Lista de Tareas — UI base | Alta | 4h |
| ✅ | Lista de Tareas — Filtros (por estado, prioridad) | Alta | 3h |
| ✅ | Lista de Tareas — Búsqueda de tareas | Media | 2h |
| ✅ | Lista de Tareas — Ordenamiento | Media | 2h |
| ✅ | Detalle de Tarea — Formulario completo | Alta | 4h |
| ✅ | Detalle de Tarea — Selector de fecha de entrega | Alta | 2h |
| ✅ | Detalle de Tarea — Selector de prioridad (alta/media/baja) | Alta | 2h |
| ✅ | Detalle de Tarea — Selector de materia asociada | Media | 2h |
| ✅ | Modal Crear/Editar Tarea | Alta | 3h |
| ✅ | Validaciones en formulario de tarea | Alta | 2h |

### 🎨 Frontend — Widgets de Tareas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | TaskCard — Diseño base de la tarjeta | Alta | 3h |
| ✅ | TaskCard — Estados visuales (pendiente/completada) | Alta | 2h |
| ✅ | TaskCard — Checkbox interactivo | Alta | 2h |
| ✅ | TaskCard — Swipe actions (deslizar para eliminar/editar) | Media | 3h |
| ✅ | TaskCard — Indicador visual de prioridad | Media | 1h |
| ✅ | TaskFilter widget (filtro de tareas) | Media | 2h |
| ✅ | DatePicker personalizado | Media | 3h |
| ✅ | PrioritySelector (selector de prioridad) | Media | 2h |

### 🎨 Frontend — Animaciones de Tareas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Transición entre estados de tarea | Media | 2h |
| ✅ | Animación al completar una tarea | Media | 2h |
| ✅ | Lista animada al agregar/eliminar elementos | Baja | 3h |
| ✅ | Skeleton loading (carga progresiva) | Baja | 2h |

### 🔧 Backend — Task Model

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Definir Task Model (campos: título, descripción, fecha, estado, prioridad, id_materia) | Alta | 2h |
| ✅ | Definir estructura de tabla en MySQL para tareas | Alta | 2h |
| ✅ | Implementar `toJson()` (serialización del modelo) | Alta | 1h |
| ✅ | Implementar `fromJson()` (deserialización del modelo) | Alta | 1h |
| ✅ | Implementar `copyWith()` (para actualizar campos) | Media | 1h |

### 🔧 Backend — TaskService

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | `createTask()` — Crear tarea | Alta | 2h |
| ✅ | `updateTask()` — Actualizar tarea | Alta | 2h |
| ✅ | `deleteTask()` — Eliminar tarea | Alta | 2h |
| ✅ | `getTasks()` — Obtener todas las tareas | Alta | 2h |
| ✅ | `getTasksBySubject()` — Tareas por materia | Media | 2h |
| ✅ | `getTasksByStatus()` — Tareas por estado | Media | 2h |
| ✅ | `toggleTaskComplete()` — Marcar/desmarcar como completada | Alta | 2h |
| ✅ | `getUpcomingTasks()` — Tareas próximas a vencer | Media | 2h |

### 🔧 Backend — TaskProvider (State Management)

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Setup Provider base de tareas | Alta | 2h |
| ✅ | Gestión de estado reactivo (state management) | Alta | 3h |
| ✅ | Caché local de tareas | Media | 3h |
| ✅ | Lógica de filtrado y ordenamiento | Media | 2h |
| ✅ | Cálculo de estadísticas de tareas | Baja | 2h |

> **🎯 Objetivo Sprint 2:** Módulo de Gestión de Tareas 100% completo: CRUD, filtros, búsqueda, swipe, animaciones y caché local.

> **Progreso:** ✅ 41/41 tareas (100%)

---

## 🏃 SPRINT 3 — Gestión de Horarios `Semanas 5-6`

### 🎨 Frontend — Pantallas de Horario

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Vista Horario Semanal — Grid principal (`ScheduleScreen` + `ScheduleGrid`) | Alta | 5h |
| ✅ | Vista por día (`ScheduleDayView` — lista de clases con hora/duración) | Media | 3h |
| ✅ | Vista por semana completa (7 columnas con scroll sincronizado) | Media | 3h |
| ✅ | Scroll horizontal y vertical en el horario (controladores sincronizados) | Media | 2h |
| ✅ | Detalle de Clase (`ClassDetailScreen` — AppBar con color, datos e info) | Alta | 3h |
| ✅ | Formulario Crear/Editar Clase (`ScheduleFormScreen` — completo) | Alta | 4h |
| ✅ | Selector de días de la semana (`DaySelector` widget reutilizable) | Alta | 2h |
| ✅ | Selector de hora inicio y fin de clase (`showTimePicker` con ajuste automático) | Alta | 3h |
| ✅ | Color de materia para identificar bloques (heredado de `Subject.color`) | Media | 2h |
| ⬜ | Configuración de recordatorio por clase (diferido a Sprint 5 — Notificaciones) | Media | 2h |

### 🎨 Frontend — Widgets de Horario

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | ScheduleGrid widget (cuadrícula con líneas de hora, columnas por día, indicador de hora actual) | Alta | 4h |
| ✅ | ClassCard widget (tarjeta adaptativa: modo compacto/normal, borde de conflicto rojo) | Alta | 3h |
| ✅ | TimeSlot widget (etiqueta de hora lateral, 44 px de ancho) | Media | 2h |
| ✅ | DaySelector widget (chips animados, punto indicador de día actual) | Media | 2h |
| ✅ | WeekView widget (encabezado con rango de fechas, badge de conflictos, skeleton) | Media | 3h |

### 🔧 Backend — Modelos de Horario

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | Schedule Model (Node.js — 8 métodos estáticos CRUD + `detectConflicts`) | Alta | 2h |
| ✅ | Subject Model (pre-existente, validado con campos `color` y `profesor`) | Alta | 2h |
| ✅ | Tabla `horarios` en MySQL (`dia` ENUM, `hora_inicio`/`hora_fin` TIME, FK a materias) | Alta | 2h |
| ✅ | Flutter Schedule model — `fromJson` / `toJson` / `copyWith` + getters de conveniencia | Alta | 2h |

### 🔧 Backend — ScheduleService

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | `createSchedule()` — Crear bloque; HTTP 409 con lista de conflictos si hay superposición | Alta | 2h |
| ✅ | `updateSchedule()` — Actualizar; misma lógica de conflictos; `force:true` para sobreescribir | Alta | 2h |
| ✅ | `deleteSchedule()` — Soft delete (`activo = FALSE`) | Alta | 2h |
| ✅ | `getScheduleByDay()` — Filtrar por día de la semana | Alta | 2h |
| ✅ | `getWeekSchedule()` — Horario completo ordenado `lunes → domingo` con `FIELD()` | Alta | 2h |
| ✅ | `detectConflicts()` — Detección `horaInicio_A < horaFin_B AND horaFin_A > horaInicio_B` | Media | 3h |

### 📝 Exportación de Horario

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Exportar horario en formato PDF (diferido a Sprint 7) | Baja | 4h |
| ⬜ | Exportar horario como imagen con `RepaintBoundary` (diferido a Sprint 7) | Baja | 3h |
| ⬜ | Compartir horario con otros (diferido a Sprint 7) | Baja | 2h |

> **🎯 Objetivo Sprint 3:** Módulo de Horarios completo: vistas día/semana, widgets reutilizables, CRUD con detección de conflictos en frontend y backend, navegación completa y sección "Mi Horario" en el dashboard. Las exportaciones (Baja prioridad) se difieren al Sprint 7.

> **Progreso:** ✅ 25/28 tareas (89%) — núcleo 100% funcional

---

## 🏃 SPRINT 4 — Sistema de Calificaciones `Semanas 7-8`

### 🎨 Frontend — Pantallas de Calificaciones

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Dashboard de Calificaciones (pantalla principal) | Alta | 4h |
| ⬜ | Visualización de promedio general | Alta | 2h |
| ⬜ | Visualización de promedio por materia | Alta | 3h |
| ⬜ | Gráficas de rendimiento académico | Media | 4h |
| ⬜ | Tendencias y análisis de notas | Media | 3h |
| ⬜ | Detalle de calificaciones por materia | Alta | 3h |
| ⬜ | Lista de evaluaciones (parciales, talleres, etc.) | Alta | 3h |
| ⬜ | Formulario para agregar calificación | Alta | 3h |
| ⬜ | Selector de tipo de evaluación | Media | 2h |
| ⬜ | Input de nota numérica y porcentaje de peso | Alta | 2h |

### 🎨 Frontend — Widgets de Calificaciones

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | GradeCard widget (tarjeta de nota) | Alta | 3h |
| ⬜ | GradeChart — LineChart (gráfica de líneas) | Media | 4h |
| ⬜ | GradeChart — BarChart (gráfica de barras) | Media | 4h |
| ⬜ | SubjectGradesList widget (lista de notas por materia) | Alta | 3h |
| ⬜ | AverageIndicator widget (indicador de promedio) | Media | 2h |
| ⬜ | ProgressRing widget (anillo de progreso) | Media | 3h |

### 🔧 Backend — Modelos de Calificaciones

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Grade Model (id, tipo, valor, porcentaje, id_materia) | Alta | 2h |
| ⬜ | SubjectGrade Model (promedio, notas[], id_materia) | Alta | 2h |
| ⬜ | Estructura de tabla en MySQL | Alta | 2h |
| ⬜ | Conversiones `toMap()` / `fromMap()` | Alta | 2h |

### 🔧 Backend — GradeService

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | `addGrade()` — Registrar calificación | Alta | 2h |
| ⬜ | `updateGrade()` — Actualizar calificación | Alta | 2h |
| ⬜ | `deleteGrade()` — Eliminar calificación | Alta | 2h |
| ⬜ | `calculateAverage()` — Calcular promedio ponderado | Alta | 3h |
| ⬜ | `calculateProjectedGrade()` — Nota proyectada para aprobar | Media | 3h |
| ⬜ | `getGradesBySubject()` — Notas filtradas por materia | Alta | 2h |
| ⬜ | `generateReport()` — Generar reporte de calificaciones | Media | 4h |

### 📝 Exportación de Calificaciones

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Exportar reporte de notas en PDF | Media | 4h |
| ⬜ | Exportar reporte de notas en Excel | Media | 4h |
| ⬜ | Gráficas interactivas de rendimiento | Baja | 3h |

> **🎯 Objetivo Sprint 4:** Backend de calificaciones 100% funcional; dashboard con promedios visibles; formulario de registro de notas operativo; exportación PDF/Excel.

> **Progreso:** ⬜ 0/33 tareas (0%)

---

## 🏃 SPRINT 5 — Notificaciones y Sincronización `Semanas 9-10`

### 🎨 Frontend — Centro de Notificaciones

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Centro de Notificaciones — UI principal | Alta | 4h |
| ⬜ | Lista de notificaciones recibidas | Alta | 3h |
| ⬜ | Marcar notificación como leída | Alta | 2h |
| ⬜ | Filtros por tipo de notificación | Media | 2h |
| ⬜ | Pantalla de Configuración de Notificaciones | Alta | 3h |
| ⬜ | Configurar notificaciones por tipo | Media | 2h |
| ⬜ | Configurar horarios de notificación | Media | 2h |
| ⬜ | Configurar sonidos de notificación | Baja | 2h |

### 🔧 Backend — NotificationService

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | `scheduleNotification()` — Programar notificación local | Alta | 3h |
| ⬜ | `cancelNotification()` — Cancelar notificación | Alta | 2h |
| ⬜ | `sendPushNotification()` — Enviar push notification | Alta | 3h |
| ⬜ | `notifyTaskDue()` — Notificar tarea próxima a vencer | Alta | 2h |
| ⬜ | `notifyClassStarting()` — Notificar inicio de clase | Alta | 2h |
| ⬜ | Setup de notificaciones locales (flutter_local_notifications) | Alta | 3h |
| ⬜ | Implementar badges en icono de la app | Media | 2h |

### 🔧 Backend — Push Notifications (FCM opcional)

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Proveedor push configurado (FCM opcional) | Alta | 2h |
| ⬜ | Topics/canales por tipo de notificación | Media | 2h |
| ⬜ | Gestión de tokens de dispositivo | Alta | 2h |
| ⬜ | Sincronización de notificaciones con backend Node.js | Alta | 4h |

### 🔧 Backend — Jobs programados (cron/worker)

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Setup de scheduler/worker en backend | Alta | 2h |
| ⬜ | Job `sendDailyReminders` — Recordatorios diarios | Alta | 4h |
| ⬜ | Job `sendClassNotifications` — Alertas de clase | Alta | 4h |
| ⬜ | Job `cleanupOldTasks` — Limpiar tareas antiguas | Media | 3h |
| ⬜ | Job `calculateAverageOnGrade` — Recalcular promedios | Media | 3h |
| ⬜ | Deploy de jobs en entorno de producción | Alta | 1h |

> **🎯 Objetivo Sprint 5:** Sistema de notificaciones 100% operativo: push, locales, configuración por tipo/horario, sincronización en tiempo real.

> **Progreso:** ⬜ 0/28 tareas (0%)

---

## 🏃 SPRINT 6 — UI/UX Avanzado `Semanas 11-12`

### 🎨 Frontend — Modo Oscuro y Temas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Modo Oscuro — Paleta de colores definida | Alta | 3h |
| ⬜ | Modo Oscuro — Transición suave entre modos | Alta | 2h |
| ⬜ | Modo Oscuro — Persistencia (recordar preferencia) | Alta | 2h |
| ⬜ | Temas Personalizables — Selector de tema | Media | 4h |
| ⬜ | Temas predefinidos (3 o más opciones) | Media | 3h |
| ⬜ | Preview del tema en tiempo real | Media | 3h |

### 🎨 Frontend — Avatares y Perfil

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Subir foto de perfil desde galería/cámara | Alta | 3h |
| ⬜ | Avatares predeterminados para elegir | Media | 2h |
| ⬜ | Crop/recorte de imagen de perfil | Media | 3h |

### 🎨 Frontend — Animaciones Avanzadas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Hero animations entre pantallas | Media | 3h |
| ⬜ | Transiciones personalizadas entre rutas | Media | 4h |
| ⬜ | Micro-interacciones en botones y controles | Baja | 4h |
| ⬜ | Loading states animados | Media | 3h |
| ⬜ | Confetti al completar tareas 🎉 | Baja | 2h |

### 🎨 Frontend — Accesibilidad

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Tamaños de fuente ajustables por el usuario | Media | 3h |
| ⬜ | Modo de alto contraste | Media | 2h |
| ⬜ | Soporte para screen reader (TalkBack/VoiceOver) | Media | 4h |
| ⬜ | Navegación por teclado externo | Baja | 3h |

### 🔧 Backend — Optimizaciones de Rendimiento

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Caché local con Hive (persistencia offline) | Alta | 4h |
| ⬜ | Lazy loading de datos en listas largas | Alta | 3h |
| ⬜ | Compresión de imágenes antes de subir | Media | 3h |
| ⬜ | Paginación de listas (scroll infinito) | Media | 3h |

### 🔧 Backend — Cloud Storage

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Subir avatares a Cloud Storage | Alta | 3h |
| ⬜ | Optimización de imágenes en Storage | Media | 2h |
| ⬜ | CDN para assets estáticos | Baja | 2h |

> **🎯 Objetivo Sprint 6:** App pulida visualmente con modo oscuro, temas, hero animations, accesibilidad completa y optimizaciones de rendimiento.

> **Progreso:** ⬜ 0/30 tareas (0%)

---

## 🏃 SPRINT 7 — Estadísticas, Tests y Documentación `Semanas 13-14`

### 🎨 Frontend — Dashboard de Estadísticas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Gráfica de productividad semanal | Alta | 4h |
| ⬜ | Comparativa tareas completadas vs pendientes | Alta | 3h |
| ⬜ | Tiempo dedicado por materia | Media | 4h |
| ⬜ | Rachas de estudio (días consecutivos) | Media | 3h |
| ⬜ | Metas y logros del estudiante | Media | 4h |

### 🎨 Frontend — Widgets de Estadísticas

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | StatsCard widget (tarjeta de estadística) | Media | 3h |
| ⬜ | ProductivityChart widget (gráfica de productividad) | Media | 4h |
| ⬜ | GoalProgress widget (progreso hacia meta) | Media | 3h |
| ⬜ | AchievementBadge widget (insignia de logro) | Baja | 2h |
| ⬜ | WeeklyOverview widget (resumen semanal) | Media | 3h |

### 📝 Exportación de Datos

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Exportar estadísticas de horario en PDF | Media | 4h |
| ⬜ | Exportar calificaciones en Excel | Media | 4h |
| ⬜ | Exportar calificaciones en PDF | Media | 3h |
| ⬜ | Compartir estadísticas personales | Baja | 2h |
| ⬜ | Backup completo de datos del usuario | Media | 3h |

### 🔧 Backend — Analytics y Monitoreo

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Analytics de producto — eventos personalizados | Alta | 3h |
| ⬜ | Crash reporting (Sentry/alternativa) | Alta | 2h |
| ⬜ | Performance Monitoring configurado | Media | 2h |

### ✅ Tests

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ⬜ | Unit tests — Models (Task, Grade, Schedule, etc.) | Alta | 4h |
| ⬜ | Unit tests — Services (TaskService, GradeService, etc.) | Alta | 6h |
| ⬜ | Unit tests — Providers (TaskProvider, etc.) | Alta | 4h |
| ⬜ | Widget tests — Widgets comunes (CustomButton, CustomCard) | Alta | 4h |
| ⬜ | Widget tests — Widgets específicos (TaskCard, GradeCard) | Media | 4h |
| ⬜ | Integration tests — Flujo de autenticación | Alta | 4h |
| ⬜ | Integration tests — Flujo de gestión de tareas | Alta | 4h |
| ⬜ | E2E tests — Flujos completos de usuario | Media | 6h |
| ⬜ | Cobertura de tests mayor al 80% | Alta | 4h |

### 📚 Documentación

| Estado | Tarea | Prioridad | Horas |
|--------|-------|-----------|-------|
| ✅ | README completo del proyecto | Alta | 2h |
| ⬜ | PLAN_DESARROLLO documentado | Alta | 2h |
| ✅ | Documentación del Backend | Alta | 3h |
| ⬜ | Documentación del Frontend | Alta | 3h |
| ⬜ | Guía de contribución (CONTRIBUTING) | Alta | 2h |
| ⬜ | Documentación de la API | Alta | 3h |
| ⬜ | Documentación del código (dartdoc/comments) | Media | 4h |
| ⬜ | Manual de usuario final | Media | 4h |
| ⬜ | Video tutoriales de uso | Baja | 8h |

> **🎯 Objetivo Sprint 7:** App 100% completa con estadísticas, exports, cobertura de tests >80%, documentación final y lista para producción.

> **Progreso:** 🔄 2/39 tareas (5%)

---

## 🧩 MÓDULOS FUNCIONALES DEL MVP

Resumen de todos los módulos que debe tener Uniplan según la especificación de requisitos:

### Módulo 1 — Autenticación y Usuario
- ✅ RF1: Registro de usuario (nombre, correo, contraseña, universidad)
- ✅ RF2: Inicio de sesión con correo y contraseña
- ✅ RF10: Recuperación de contraseña por email (flujo activo por token)
- 🔄 RF9: Configuración del perfil de usuario (lectura + cambio de contraseña listos; edición de datos pendiente en mobile)

### Módulo 2 — Gestión Académica (Materias)
- 🔄 RF3: Gestión de materias (backend completo, frontend pendiente)

### Módulo 3 — Gestión de Tareas
- ✅ RF4: Gestión de tareas (título, fecha, prioridad, materia asociada)
- ✅ Completar/desmarcar tareas
- 🔄 Filtrar y buscar tareas

### Módulo 4 — Calendario Académico
- ✅ RF5: Visualización del calendario con actividades por fecha
- 🔄 Recordatorios de fechas de entrega y exámenes (datos listos, falta motor de notificación)

### Módulo 5 — Temporizador Pomodoro
- 🔄 RF6: Temporizador Pomodoro configurable
- ⬜ Notificaciones de descanso automáticas
- ✅ Registro de sesiones de estudio completadas

### Módulo 6 — Notas Académicas
- 🔄 RF7: Creación y organización de notas por materia (backend completo, frontend pendiente)

### Módulo 7 — Progreso Académico
- 🔄 RF8: Visualización de progreso con gráficos
- ✅ Estadísticas de tareas completadas
- ✅ Estadísticas de horas de estudio (sesiones Pomodoro)

### Módulo 8 — Gestión de Horarios
- ✅ RF11: Vista semanal (grid 7 columnas con scroll sincronizado y línea de hora actual)
- ✅ RF12: CRUD de bloques de clase (crear, editar, eliminar con confirmación)
- ✅ RF13: Detección y visualización de conflictos de horario (HTTP 409 + diálogo `force`)
- ✅ RF14: Vista por día con lista de clases, duración y aula
- ✅ RF15: Detalle de clase con acciones Editar y Eliminar
- ✅ Sección "Mi Horario" en HomeScreen con clases del día actual
- ⬜ RF16: Recordatorios de clase (Sprint 5 — Notificaciones)

### Módulo 9 — Sistema de Calificaciones *(adicional MVP+)*
- ⬜ Registro de calificaciones por evaluación
- ⬜ Cálculo automático de promedio ponderado
- ⬜ Proyección de nota final

---

## ✅ REQUISITOS NO FUNCIONALES A CUMPLIR

| ID | Requisito | Criterio de Aceptación | Estado |
|----|-----------|----------------------|--------|
| RNF1 | Usabilidad | Interfaz intuitiva validada con usuarios | ⬜ |
| RNF2 | Seguridad | Datos protegidos con JWT + middleware de autenticación + MySQL | 🔄 |
| RNF3 | Rendimiento | Tiempo de respuesta < 3 segundos en operaciones normales | ⬜ |
| RNF4 | Disponibilidad | Sistema disponible 24/7 en entorno desplegado (no local) | ⬜ |
| RNF5 | Compatibilidad | App funcional en Android e iOS | ⬜ |
| RNF6 | Escalabilidad | Arquitectura modular que permita agregar funciones | ⬜ |
| RNF7 | Portabilidad | Ejecutable en distintos dispositivos móviles | ⬜ |
| RNF8 | Mantenibilidad | Código modular, comentado y con tests >80% cobertura | ⬜ |

---

## 🎯 PRÓXIMAS 5 TAREAS PRIORITARIAS

> Actualizar esta sección semanalmente según avance del equipo

| # | Tarea | Sprint | Horas | Estado |
|---|-------|--------|-------|--------|
| 1 | Deploy backend Sprint 3 (schedule routes) a Vercel producción | Sprint 3 | 0.5h | ⬜ |
| 2 | Actualizar perfil de usuario (UI + consumo PUT /students/:id) | Sprint 1 | 4h | 🔄 |
| 3 | Dashboard de Calificaciones — pantalla principal | Sprint 4 | 4h | ⬜ |
| 4 | Componentes reutilizables faltantes (CustomCard, LoadingIndicator, EmptyState, ErrorState) | Sprint 1 | 7h | ⬜ |
| 5 | Grade Model + tabla MySQL para Sprint 4 | Sprint 4 | 4h | ⬜ |

---

## 📈 ESTADÍSTICAS DE TIEMPO

| Métrica | Valor |
|---------|-------|
| ⏱️ Tiempo total estimado | ~550 horas |
| ✅ Tiempo completado | ~175 horas |
| 🕐 Tiempo restante | ~375 horas |
| 📅 Semanas totales | 14 semanas / 7 Sprints |
| 📅 Semanas completadas | ~6 semanas (Sprints 1-3) |
| 📅 Semanas restantes | ~8 semanas |

---

## 💡 NOTAS DEL EQUIPO

- Actualizar los estados (✅ / 🔄 / ⬜ / ❌ / ⏸️) semanalmente
- Asignar responsables en cada reunión de planning
- Ajustar estimaciones de horas según experiencia real del equipo
- Agregar nuevas tareas según necesidades que surjan en el desarrollo
- Revisar y actualizar las "Próximas 5 Tareas Prioritarias" cada semana

---

## 🔄 Control de Versiones del Documento

| Fecha | Actualizado por | Cambios |
|-------|----------------|---------|
| 14 Feb 2026 | Equipo Uniplan | Versión inicial del plan |
| 29 Abr 2026 | Copilot CLI | Estados actualizados según implementación real (mobile + backend) para seguimiento operativo |
| 29 Abr 2026 | Copilot CLI | Corrección de estados inconsistentes (hecho/parcial/pendiente), porcentajes por sprint y prioridades inmediatas |
| 29 Abr 2026 | Copilot CLI | Alineación completa a stack real Node.js + Express + MySQL (sin Firebase), con estados ajustados a código actual |
| 2 May 2026 | Copilot CLI | Password reset marcado como completo (token funcional), RF10 actualizado y prioridades limpiadas del flujo ya terminado |
| 26 Jun 2026 | Claude Code | Sprint 3 completado: módulo de Horarios (ScheduleGrid, ClassCard, DaySelector, WeekView, ScheduleFormScreen, ClassDetailScreen, ScheduleDayView, ScheduleProvider, Schedule model, backend CRUD + detección de conflictos). Progreso global actualizado a 39% (92/234). |

---

<div align="center">

**💪 ¡Cada tarea completada es un paso más cerca del éxito! 🚀**

*Uniplan · Universidad de Córdoba · Ingeniería de Sistemas · 2025*

</div>
