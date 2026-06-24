# Plan de implementación — Sprint 3 (Gestión de Horarios)

## Problema y alcance
Construir el módulo de **Gestión de Horarios** desde 0, siguiendo `UNIPLAN_MVP.md` como fuente de verdad. El objetivo es llevar Sprint 3 de **0% (0/31)** a un cierre completo con vistas de día/semana, widgets reutilizables, backend de horarios, detección de conflictos y exportación.

El horario semanal académico es un concepto separado del calendario de eventos: representa la **grilla repetitiva de clases semanales** (Lunes 8-10 AM Álgebra, Martes 2-4 PM Física, etc.), no eventos puntuales.

## Estado actual validado (código vs MVP)

### Ya existente y reutilizable
- **Backend**: Modelo `Subject` completo con campos `profesor`, `horario` (JSON), `color` y CRUD operativo.
- **Backend**: Modelo `Calendar` con soporte de eventos tipo `'clase'`, `eventos_calendario` tabla activa.
- **Mobile**: `CalendarEvent` model con `tipo`, `horaInicio`, `horaFin`, `color`, `materiaNombre`.
- **Mobile**: `CalendarService` con CRUD y filtros por tipo/fecha/materia.
- **Mobile**: `SubjectService` con `getSubjects()`, `createSubject()`, `deleteSubject()`.
- **Mobile**: `TaskProvider` como patrón de referencia para `ScheduleProvider` (ChangeNotifier + cache local).
- **Mobile**: Pantalla `CalendarScreen` con `table_calendar`, vista mensual, eventos del día.
- **Mobile**: `EventFormScreen` para crear/editar eventos.

### Brechas detectadas para cerrar Sprint 3
- No existe modelo/tabla de **horarios recurrentes** (horario semanal con días de la semana).
- No existe API dedicada para horarios (`/api/schedules`).
- No existe `ScheduleProvider` ni cache local de horarios.
- No existe grilla visual semanal (`ScheduleGrid`, `WeekView`).
- No existe vista por día del horario semanal.
- No existe detección de conflictos de horario.
- No existe exportación PDF/imagen del horario.
- El `Subject` model backend tiene campo `horario` como JSON opaco — hay que migrarlo a una tabla dedicada o usarlo como respaldo.

## Decisión sobre diseño

**Tabla separada vs campo JSON en Subject:** Se usará **tabla dedicada `horarios`** con fila por bloque horario (día, hora_inicio, hora_fin, id_materia, aula). Esto permite:
- Consultas nativas por día/semana sin parsear JSON.
- Detección de conflictos con SQL (`WHERE dia = ? AND hora_inicio < ? AND hora_fin > ?`).
- CRUD independiente sin tocar la materia.
- El campo `horario` en `materias` queda como histórico/legado.

## Estrategia de ramas (Git)

### Rama umbrella del sprint
- `feature/sprint-3-schedule-management`

### Sub-ramas recomendadas
1. `feature/s3-schedule-model-migration` — Tabla `horarios` + migración + modelo
2. `feature/s3-schedule-api` — CRUD rutas + controlador + ScheduleService backend
3. `feature/s3-schedule-widgets` — ScheduleGrid, ClassCard, TimeSlot, DaySelector, WeekView
4. `feature/s3-schedule-screens` — ScheduleScreen, vista día, vista semana, formulario crear/editar
5. `feature/s3-schedule-provider` — ScheduleProvider + cache local + integración con SubjectProvider
6. `feature/s3-conflict-detection` — Detección visual de conflictos en UI
7. `feature/s3-schedule-export` — Exportación PDF/imagen + compartir
8. `chore/s3-mvp-sync-docs` — Actualizar UNIPLAN_MVP.md y cierre

### Flujo de trabajo recomendado
1. `git checkout main`
2. `git pull origin main`
3. `git checkout -b feature/sprint-3-schedule-management`
4. Crear sub-ramas desde la umbrella.
5. Merge de sub-ramas hacia la umbrella con commits atómicos.
6. PR final de la umbrella a `main`.

## Plan técnico por fases

### Fase 1 — Modelo de base de datos + migración
**Backend**

- Crear tabla `horarios` con migración SQL:
  ```sql
  CREATE TABLE horarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_materia INT NOT NULL,
    dia ENUM('lunes','martes','miercoles','jueves','viernes','sabado','domingo') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    aula VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id),
    FOREIGN KEY (id_materia) REFERENCES materias(id)
  );
  ```
- Crear `backend/src/models/Schedule.js` con métodos:
  - `create(data)` — Insertar bloque horario
  - `findByStudent(id_estudiante, filters)` — Obtener horarios con JOIN a materias (nombre, color, profesor)
  - `findById(id)` — Obtener un bloque
  - `findByDay(id_estudiante, dia)` — Horarios de un día específico
  - `findWeekSchedule(id_estudiante)` — Horario semanal completo (lunes a domingo)
  - `update(id, data)` — Actualizar bloque
  - `delete(id)` — Soft delete
  - `detectConflicts(id_estudiante, dia, hora_inicio, hora_fin, excludeId?)` — Detectar superposición

### Fase 2 — API de horarios (backend)
**Backend — `scheduleController.js`**
- `createSchedule(req, res)` — Crear bloque con validación de conflictos
- `getMySchedules(req, res)` — Obtener horarios con filtros (dia, id_materia)
- `getScheduleByDay(req, res)` — Horario de un día específico
- `getWeekSchedule(req, res)` — Horario semanal completo
- `getScheduleById(req, res)` — Un bloque específico
- `updateSchedule(req, res)` — Actualizar con re-detección de conflictos
- `deleteSchedule(req, res)` — Eliminar bloque
- `getScheduleConflicts(req, res)` — Listar todos los conflictos del estudiante

**Backend — `scheduleRoutes.js`**
```
POST   /api/schedules
GET    /api/schedules
GET    /api/schedules/day/:dia
GET    /api/schedules/week
GET    /api/schedules/conflicts
GET    /api/schedules/:id
PUT    /api/schedules/:id
DELETE /api/schedules/:id
```

**Backend — `scheduleService.js`** (capa de lógica)
- `createSchedule(data)` + validación de conflictos antes de insertar
- `getWeekSchedule(id_estudiante)` — Ordenado por día y hora
- `detectAndReportConflicts(id_estudiante)` — Escanear todo el horario en busca de superposiciones
- Todas las rutas protegidas con `authMiddleware`

### Fase 3 — Widgets base de horario (mobile)
**Mobile — Nuevos archivos en `mobile/lib/widgets/schedule/`:**
1. **`schedule_grid.dart`** — `ScheduleGrid` widget:
   - Grilla con días como columnas (o filas, según diseño) y horas como filas
   - Celdas que contienen bloques de clase
   - Scroll horizontal y vertical sincronizado
   - Altura de hora configurable (ej. 60px por hora)
   - Línea de hora actual (opcional, mejora)

2. **`class_card.dart`** — `ClassCard` widget:
   - Tarjeta que representa un bloque de clase dentro del grid
   - Muestra: nombre materia, aula, profesor (opcional)
   - Color de fondo según color de materia
   - Borde izquierdo con el color de materia (mayor contraste)
   - Texto truncado si el bloque es muy angosto
   - `onTap` para ver detalle / editar

3. **`time_slot.dart`** — `TimeSlot` widget:
   - Etiqueta de hora (ej. "8:00", "9:00") para el eje Y del grid
   - Formato de 12h o 24h según locale

4. **`day_selector.dart`** — `DaySelector` widget:
   - Fila horizontal de días de la semana
   - Día actual resaltado
   - `onDaySelected` callback para cambiar vista
   - Versión compacta para vista semana, versión expandida para vista día

5. **`week_view.dart`** — `WeekView` widget:
   - Contenedor que integra `ScheduleGrid` + `DaySelector`
   - Vista completa de la semana laboral (lunes a viernes o lunes a sábado)
   - Scroll horizontal para ver todos los días

### Fase 4 — Pantallas de horario (mobile)
**Mobile — Nuevos archivos en `mobile/lib/screens/schedule/`:**

1. **`schedule_screen.dart`** — Pantalla principal de horarios:
   - `WeekView` como contenido principal
   - Tabs para alternar entre vista semana y vista día
   - FAB para agregar nuevo bloque de clase
   - Pull-to-refresh
   - Bottom sheet de filtro por materia
   - Integración con BottomNavBar existente (reemplazar o agregar pestaña)

2. **`schedule_day_view.dart`** — Vista por día:
   - `DaySelector` + grid vertical de un solo día
   - Lista de clases del día con horarios
   - Scroll vertical

3. **`class_detail_screen.dart`** — Detalle de clase:
   - Información completa: materia, aula, horario, profesor
   - Editar / Eliminar acciones
   - Color de materia como acento visual
   - Botón para ver en el mapa (si aplica)

4. **`schedule_form_screen.dart`** — Crear/Editar bloque de clase:
   - Selector de materia (desde `SubjectService`)
   - Selector de día de la semana (Lun-Dom)
   - Selector de hora inicio y hora fin (`TimePicker`)
   - Campo de aula
   - Detección de conflictos en tiempo real al seleccionar horario
   - Validación: hora_fin > hora_inicio, materia obligatoria

### Fase 5 — ScheduleProvider y estado (mobile)
**Mobile — `mobile/lib/providers/schedule_provider.dart`:**
- `ChangeNotifier` siguiendo el patrón de `TaskProvider`
- Estado: `schedules`, `selectedDay`, `currentView` (week/day), `isLoading`, `error`, `conflicts`
- Acciones: `loadWeek()`, `loadDay(dia)`, `createSchedule()`, `updateSchedule()`, `deleteSchedule()`
- Caché local con `SharedPreferences` (lista de horarios serializada)
- Detección de conflictos del lado mobile (refuerzo)
- Integración con `SubjectProvider` para mapear materia a color

### Fase 6 — Detección de conflictos (UI)
- Al crear/editar un bloque:
  - Si hay superposición con otro bloque existente, mostrar alerta visual: "Este horario se superpone con [Materia] (Lunes 10:00-12:00)"
  - Opciones: ignorar y guardar, o cancelar y ajustar
- En la grilla semanal: bloques que se superponen se muestran con un patrón de advertencia (borde rojo, tooltip)
- Badge de conflictos en la pantalla principal de horarios

### Fase 7 — Exportación de horario
**Mobile (opciones):**
1. **PDF** — Usar `pdf` package + `printing` package:
   - Generar PDF con la grilla semanal
   - Incluir nombre de materias, colores, aula
   - Encabezado con nombre del estudiante y semestre
2. **Imagen** — Capturar widget como imagen (`RepaintBoundary` + `RenderRepaintBoundary.toImage()`):
   - Guardar en galería o compartir
3. **Compartir** — Compartir imagen/PDF vía share sheet nativo (`share_plus`)

### Fase 8 — Cierre de sprint y documentación
- Revisar `UNIPLAN_MVP.md` y marcar Sprint 3 como completado (31/31)
- Actualizar "Próximas 5 tareas prioritarias" apuntando a Sprint 4
- Preparar PR final con checklist de cumplimiento

## Orden y dependencias
1. **Fase 1 + Fase 2** primero (backend: modelo + API) — pueden ir en paralelo
2. **Fase 3** (widgets) después de Fase 1, puede empezar con datos mockeados
3. **Fase 4** (pantallas) después de Fase 2 + Fase 3
4. **Fase 5** (provider) después de Fase 2, puede integrarse en paralelo con Fase 4
5. **Fase 6** (conflictos UI) después de Fase 4 + Fase 5
6. **Fase 7** (exportación) al final, después de tener el horario funcional
7. **Fase 8** al cierre

## Definition of Done — Sprint 3
- Backend: tabla `horarios` creada, modelo + controlador + rutas operativas, detección de conflictos funcional
- Mobile: `ScheduleGrid`, `ClassCard`, `TimeSlot`, `DaySelector`, `WeekView` implementados y reutilizables
- Mobile: Vista semana y vista día funcionales con scroll horizontal y vertical
- Mobile: Formulario crear/editar bloque con selector de materia, día, hora inicio/fin, aula y detección de conflictos en tiempo real
- Mobile: `ScheduleProvider` activo con ChangeNotifier, caché local y estado reactivo
- Mobile: Exportación PDF básica del horario semanal
- Mobile: Integración con BottomNavBar o entrada dedicada desde el menú principal
- `UNIPLAN_MVP.md` actualizado con Sprint 3 al 100%

## Riesgos y mitigación
- **Riesgo**: La grilla semanal es técnicamente compleja (scroll síncrono X/Y, solapamiento visual de bloques).
  **Mitigación**: Prototipar el `ScheduleGrid` con datos mockeados primero, usar `CustomScrollView` con `SliverPersistentHeader` para fijar encabezados.

- **Riesgo**: Confusión entre `CalendarEvent` existente (eventos puntuales) y `Schedule` (bloques recurrentes).
  **Mitigación**: Nomenclatura clara: `Schedule` = horario semanal recurrente, `CalendarEvent` = eventos en fecha específica. El schedule alimentará sugerencias al calendario pero no se mezcla.

- **Riesgo**: Detección de conflictos puede tener falsos positivos (ej. una materia que ocupa 2 bloques contiguos).
  **Mitigación**: El `detectConflicts` permite `excludeId` para omitir el propio registro al editar, y el umbral de conflicto es superposición estricta (no bloques consecutivos).

- **Riesgo**: Exportación PDF puede ser pesada de implementar.
  **Mitigación**: Priorizar exportación como imagen primero (más simple, usa herramientas de Flutter sin packages externos pesados), PDF queda como mejora si el tiempo lo permite.
