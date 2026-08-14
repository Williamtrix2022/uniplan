# Plan de implementación — Sprint 5 (Notificaciones y Sincronización)

## Problema y alcance

Construir el módulo de **Notificaciones** desde 0, siguiendo `UNIPLAN_MVP.md` como fuente de verdad. El objetivo es llevar Sprint 5 de **0% (0/28)** a un núcleo funcional completo: recordatorios locales de tareas y clases, centro de notificaciones in-app, configuración de preferencias por tipo/horario/silencio, y persistencia sincronizable del historial entre dispositivos.

**Decisión de arquitectura central: motor de notificaciones 100% local (en el dispositivo), sin proveedor push externo.** El backend de Uniplan corre en **Vercel serverless** (`backend/server.js` exporta la app en vez de escuchar cuando `require.main !== module`), por lo que un `node-cron`/`setInterval` de larga vida no se ejecuta de forma confiable en producción — no hay proceso vivo entre requests. El dispositivo ya tiene todos los datos necesarios para calcular sus propios recordatorios (`fecha_entrega` de las tareas, `dia`/`hora_inicio` de los horarios), así que el scheduling real vive en Flutter vía `flutter_local_notifications`, no en el servidor. Esto es gratis, funciona offline y no depende de Firebase (hay un `google-services.json` a medio configurar en Android desde antes, pero sin paquetes Dart ni init — no se usa en este sprint).

El backend NO envía push; aporta el **feed persistido** (historial de notificaciones, sincronizable entre dispositivos) y las **preferencias** del usuario (qué tipos de notificación quiere, con cuántos minutos de antelación, y horas de silencio).

## Estado actual validado (código vs MVP)

### Ya existente y reutilizable
- **Backend**: patrón Model → Controller → Route sin capa de servicios por feature (`Grade.js` / `gradeController.js` / `gradeRoutes.js` como referencia exacta), envelope de respuesta `{ success, message?, data?, count? }`, soft delete vía `activo`.
- **Backend**: `authMiddleware` que adjunta `req.user = { id, correo }` desde el JWT; identidad siempre desde el token, nunca del body.
- **Backend**: patrón `CREATE TABLE IF NOT EXISTS` para agregar tablas sin runner de migraciones (`Student.ensurePasswordResetTable()` como referencia).
- **Backend**: tabla `tareas` con `fecha_entrega` y columnas `recordatorio`/`fecha_recordatorio` ya existentes (aunque `fecha_recordatorio` no se escribe desde el modelo); tabla `horarios` con `dia`/`hora_inicio` recurrentes semanales.
- **Mobile**: patrón completo de módulo (Model `fromJson/toJson` → Service sobre `ApiService` → `ChangeNotifier` Provider con cache en `SharedPreferences` → Screens → Widgets), validado en el módulo Grades.
- **Mobile**: `AppTheme`/`AppSizes` con paleta y tokens de espaciado/radio ya definidos.
- **Mobile**: dos puntos de entrada ya "stubbeados" esperando este sprint — la campanita en `home_screen.dart` (`// TODO: Notificaciones`) y el ítem "Notificaciones" en `profile_screen.dart` (SnackBar "Próximamente").

### Brechas detectadas para cerrar Sprint 5
- No existía tabla/modelo de notificaciones ni de preferencias.
- No existía API dedicada (`/api/notifications`).
- No existía ningún motor de notificaciones locales en el proyecto mobile (`flutter_local_notifications` no estaba en `pubspec.yaml`).
- No existía `NotificationProvider`, pantallas ni widgets de notificaciones.
- No existía lógica de cálculo de "cuándo programar un recordatorio" (fecha objetivo − minutos de antelación, respetando horas de silencio) en ningún lado del código.
- Los dos stubs de UI (campanita, ítem de perfil) no tenían destino.

## Decisión sobre diseño

**Local vs Push (FCM)**: se descartó Firebase Cloud Messaging para este sprint. Razón técnica: el backend serverless en Vercel no sostiene un proceso de disparo server-side, y agregar FCM sin ese disparador solo suma superficie de configuración (service account, tokens de dispositivo) sin resolver el problema real. El scheduling vive en el cliente.

**Backend sin cron real**: los endpoints de notificaciones son CRUD de feed + preferencias, no un motor de envío. `NotificationService`/jobs programados (`sendDailyReminders`, `sendClassNotifications`, etc.) del MVP original quedan **diferidos**, documentados como no viables en el hosting actual — igual criterio que la exportación PDF/Excel diferida en Sprints 3 y 4.

**IDs deterministas para notificaciones locales**: cada recordatorio programado usa un ID derivado de un string estable (`'tarea_<id>'`/`'clase_<id>'` hasheado), para poder cancelar y reprogramar sin duplicar notificaciones cuando cambian los datos o las preferencias.

**Función pura de scheduling**: la decisión de "¿programo esto, y para cuándo?" (fecha objetivo, minutos de antelación, horas de silencio) se aisló en una función pura sin I/O (`computeReminderTime`), separada del código que efectivamente llama al plugin. Es la lógica de negocio más importante del sprint y la más fácil de testear exhaustivamente sin mocks de plataforma.

## Estrategia de ramas (Git)

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-5-notifications
```

Sin PR por ahora — el usuario prueba la rama localmente (`flutter run` + `npm run dev`) antes de decidir el paso siguiente. Sin commits hasta validar manualmente la funcionalidad.

## Plan técnico por fases

### Fase 1 — Base de datos
```sql
CREATE TABLE IF NOT EXISTS notificaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  tipo ENUM('tarea','clase','sistema','general') NOT NULL DEFAULT 'general',
  titulo VARCHAR(150) NOT NULL,
  mensaje TEXT NULL,
  leida BOOLEAN DEFAULT FALSE,
  referencia_tipo VARCHAR(50) NULL,
  referencia_id INT NULL,
  fecha_programada DATETIME NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id) ON DELETE CASCADE
);

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
);
```
Mismo estilo de DDL que `calificaciones` (Sprint 4): `BOOLEAN`, `activo`, `fecha_creacion`/`fecha_actualizacion`, FKs con `ON DELETE CASCADE`. Entregado como `backend/seeds/sprint5_notifications_seed.sql` para ejecución manual en AlwaysData, y además creado en caliente vía `CREATE TABLE IF NOT EXISTS` desde `Notification.ensureTables()` al arrancar el servidor (mismo patrón que `Student.ensurePasswordResetTable()`).

### Fase 2 — API de notificaciones (backend)
**`backend/src/models/Notification.js`**
- `ensureTables()`, `create`, `findByStudent(id_estudiante, { tipo, leida })`, `findById`, `getUnreadCount`, `markAsRead`, `markAllAsRead`, `remove` (soft delete), `getPreferences` (crea defaults en el primer acceso, nunca 404), `updatePreferences`.
- Reintentos ante desconexión del MySQL remoto (mismo patrón que `Student.queryWithRetry`, replicado inline por no estar exportado).

**`backend/src/controllers/notificationController.js`**
- `getNotifications`, `getUnreadCount`, `markRead`, `markAllRead`, `deleteNotification`, `getPreferences`, `updatePreferences`.
- `id_estudiante` siempre desde `req.user.id`; ownership check (403) antes de mutar un registro puntual.

**`backend/src/routes/notificationRoutes.js`**
```
GET    /api/notifications
GET    /api/notifications/unread-count
GET    /api/notifications/preferences
PUT    /api/notifications/preferences
PATCH  /api/notifications/read-all
PATCH  /api/notifications/:id/read
DELETE /api/notifications/:id
```
Todas protegidas con `authMiddleware`; rutas literales (`/unread-count`, `/preferences`, `/read-all`) antes de `/:id`. Montadas en `backend/src/app.js` bajo `/api/notifications`.

### Fase 3 — Modelo y motor local (mobile)
- `mobile/lib/models/app_notification.dart`, `mobile/lib/models/notification_preferences.dart` — `fromJson`/`toJson`.
- `mobile/lib/services/local_notification_service.dart` — inicialización de `flutter_local_notifications` + `timezone`/`flutter_timezone`, permisos Android 13+, canales por tipo (tareas/clases/general), `scheduleAt`, `cancel`, `cancelAll`, IDs deterministas por clave estable.
- `mobile/lib/services/notification_scheduler.dart` — función pura `computeReminderTime` (fecha objetivo, minutos de antelación, horas de silencio con soporte de cruce de medianoche) + helper de próxima ocurrencia semanal para clases.
- `mobile/lib/services/notification_service.dart` — sobre `ApiService`, mismo patrón que `grade_service.dart`, para el feed y las preferencias.
- `mobile/lib/config/api_config.dart` — constantes de endpoints de notificaciones.

### Fase 4 — NotificationProvider y estado (mobile)
- `mobile/lib/providers/notification_provider.dart` — `ChangeNotifier` con cache local, `initialize/load/refresh`, `unreadCount`, `markRead`/`markAllRead`/`delete`, gestión de preferencias, y `rescheduleAll` (recalcula y reprograma recordatorios locales a partir de tareas/horarios/preferencias vigentes, cancelando y reprogramando por ID determinista para no duplicar).
- Registrado en el `MultiProvider` de `mobile/lib/main.dart`; `LocalNotificationService.initialize()` invocado al arranque.

### Fase 5 — Pantallas y widgets (mobile)
**`mobile/lib/screens/notifications/`**
- `notifications_screen.dart` — Centro de Notificaciones: lista, filtros por tipo, marcar leída/todas, eliminar, estados vacío/error/carga, `RefreshIndicator`.
- `notification_settings_screen.dart` — Ajustes: toggles por tipo, minutos de antelación, horas de silencio, persistido a API + reprogramación local.

**`mobile/lib/widgets/notifications/`**
- `notification_card.dart` — tarjeta de notificación (icono por tipo, indicador de no leída).
- Badge de no leídas sobre la campanita del Home.

**Entrada**: campanita de `home_screen.dart` → Centro de Notificaciones; ítem "Notificaciones" de `profile_screen.dart` → pantalla de Ajustes (reemplazando el SnackBar "Próximamente" en ambos casos).

### Fase 6 — Verificación
- Backend: suite Jest nueva (primera del proyecto) — modelo y controlador con `pool.execute`/modelo mockeado, 401 sin token, orden de rutas literal-antes-de-`:id` verificado.
- Mobile: `flutter analyze` sin errores nuevos; suite de tests nueva, con foco prioritario en `computeReminderTime` (casos borde: fecha vencida, cruce de medianoche en horas de silencio, sin horas de silencio configuradas) y en `NotificationProvider` con servicio falso.
- Revisión adversarial fresh-context (R1 Riesgo + R3 Confiabilidad + R2 Legibilidad) sobre autorización, condiciones de carrera en `getPreferences`, calidad de los tests, y consistencia con los patrones existentes — antes de cualquier commit.

### Fase 7 — Cierre de sprint y documentación
- Actualizar `UNIPLAN_MVP.md`: Sprint 5 a núcleo funcional completo (Push FCM y Jobs cron server-side diferidos, documentados con la justificación del serverless).
- `cleanupOldTasks` implementado como **utilitario CLI one-off invokable manualmente** (`backend/scripts/cleanup-old-tasks.js` + script npm `cleanup:tasks`) — no como job programado en el worker, porque el hosting serverless no sostiene un scheduler.
- Fuera de alcance del Sprint 5: **sonidos personalizados de notificación** — `flutter_local_notifications` en iOS requiere assets plugados fuera del alcance del MVP; Android lo permite sin un valor claro. Decisión de no hacerlo.
- Sin commit/push hasta que el usuario pruebe manualmente la app (restricción explícita de esta sesión).

## Orden y dependencias
1. **Fase 1 + Fase 2** (base de datos + API backend) en paralelo con **Fase 3 + Fase 4** (motor local + provider mobile), usando el contrato de API acordado de antemano — ambas mitades se implementaron en agentes separados sin dependencia bloqueante.
2. **Fase 5** (pantallas/widgets) depende de Fase 3 + Fase 4.
3. **Fase 6** (verificación) al cierre de las fases 2 y 5, con revisión adversarial fresh-context en paralelo (Riesgo, Confiabilidad, Legibilidad) más verificación funcional independiente.
4. **Fase 7** al final.

## Definition of Done — Sprint 5
- Backend: tablas `notificaciones` y `preferencias_notificacion` definidas (DDL entregado + `ensureTables()`), modelo + controlador + rutas operativas y testeadas.
- Mobile: motor de notificaciones locales inicializado, con permisos Android 13+ y canales por tipo.
- Mobile: `NotificationProvider` activo con cache local, reprogramación determinista sin duplicados.
- Mobile: Centro de Notificaciones y pantalla de Ajustes operativos, cableados a los stubs existentes (campanita + perfil).
- Mobile: función pura de cálculo de recordatorios (`computeReminderTime`) exhaustivamente testeada.
- Tests backend y mobile en verde (suite nueva en ambos lados).
- `UNIPLAN_MVP.md` actualizado confirmando el cierre del núcleo de Sprint 5.
- Push FCM y jobs cron server-side explícitamente diferidos (no cuentan como pendiente bloqueante).

## Riesgos y mitigación
- **Riesgo**: un `node-cron` o scheduler de larga vida no sobrevive en el hosting serverless (Vercel) del backend.
  **Mitigación**: el scheduling se movió enteramente al dispositivo; el backend solo persiste feed y preferencias. Documentado explícitamente como decisión de arquitectura, no como pendiente técnico.

- **Riesgo**: reprogramar notificaciones locales repetidamente (al cambiar tareas, horarios o preferencias) podría duplicar recordatorios.
  **Mitigación**: IDs deterministas por clave estable (`tarea_<id>`, `clase_<id>`) permiten cancelar-y-reprogramar de forma idempotente.

- **Riesgo**: las horas de silencio con cruce de medianoche (p. ej. 22:00–07:00) son una fuente común de bugs off-by-one.
  **Mitigación**: lógica aislada en una función pura (`computeReminderTime`) con tests dedicados a ese caso, revisada en la fase de confiabilidad antes de dar el sprint por cerrado.

- **Riesgo**: `getPreferences()` podría insertar una fila default duplicada si se llama concurrentemente para un usuario nuevo (choque contra el `UNIQUE` de `id_estudiante`).
  **Mitigación**: validado explícitamente en la revisión de confiabilidad fresh-context antes del cierre del sprint.

- **Riesgo**: sin capa de migraciones, las tablas nuevas dependen de que el usuario ejecute el SQL manualmente en AlwaysData (o de que `ensureTables()` corra en el primer arranque del backend).
  **Mitigación**: `CREATE TABLE IF NOT EXISTS` en ambos caminos, seed documentado con el mismo estilo que `sprint4_demo_seed.sql`.
