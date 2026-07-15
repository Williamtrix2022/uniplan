# Plan de implementación — Sprint 4 (Sistema de Calificaciones)

## Problema y alcance
Construir el módulo de **Sistema de Calificaciones** desde 0, siguiendo `UNIPLAN_MVP.md` como fuente de verdad. El objetivo es llevar Sprint 4 de **0% (0/33)** a un núcleo funcional completo: registro de calificaciones por evaluación, cálculo de promedio ponderado por materia y general, proyección de nota necesaria para aprobar, dashboard visual y gráficas de rendimiento.

Las calificaciones (`calificaciones`) son un concepto separado de las notas académicas (`notas`, tabla ya existente = apuntes/notas de estudio). Este sprint introduce evaluaciones numéricas (parciales, talleres, quices, proyectos, laboratorios) con un valor sobre 5.0 y un porcentaje de peso dentro de la materia.

**Escala de calificación**: 0.0 a 5.0, nota mínima de aprobación **3.0** (estándar Universidad de Córdoba). Bandas de color: rojo `<3.0`, amarillo `3.0–3.9`, verde `≥4.0`.

## Estado actual validado (código vs MVP)

### Ya existente y reutilizable
- **Backend**: patrón Model → Controller → Route sin capa de servicios por feature (`Schedule.js` / `scheduleController.js` / `scheduleRoutes.js` como referencia exacta).
- **Backend**: `authMiddleware` que adjunta `req.user = { id, correo }` desde el JWT.
- **Backend**: tabla `materias` con `color`, `profesor`, `creditos` — punto de FK para `calificaciones`.
- **Mobile**: patrón completo de módulo (Model `fromJson/toJson/copyWith` → Service sobre `ApiService` → `ChangeNotifier` Provider con cache en `SharedPreferences` → Screens → Widgets), validado en el módulo Schedule.
- **Mobile**: `AppTheme`/`AppSizes` con paleta y tokens de espaciado/radio ya definidos, incluidas bandas semánticas (`success`, `warning`, `error`).
- **Mobile**: técnica de `CustomPainter` para el anillo del Pomodoro en `home_screen.dart`, reutilizada para el `ProgressRing` de calificaciones.
- **Mobile**: sección "Mi Horario" en el dashboard (`_buildScheduleSection`) como patrón de entrada para la nueva sección "Mis Calificaciones".

### Brechas detectadas para cerrar Sprint 4
- No existía tabla/modelo de calificaciones (`calificaciones`).
- No existía API dedicada (`/api/grades`).
- No existía `GradeProvider` ni cache local de calificaciones.
- No existía ninguna librería de gráficas en el proyecto mobile (`fl_chart` no estaba en `pubspec.yaml`).
- No existían pantallas ni widgets de calificaciones (dashboard, detalle por materia, formulario, tarjetas, gráficas).
- No existía lógica de promedio ponderado ni de proyección de nota final en ningún lado del código.

## Decisión sobre diseño

**Tabla dedicada `calificaciones` vs. reutilizar `notas`:** se descartó reutilizar la tabla `notas` (apuntes de texto, sin campos numéricos) y se creó una tabla nueva con `valor DECIMAL(3,2)` y `porcentaje DECIMAL(5,2)`, siguiendo el mismo estilo de DDL que `horarios` (Sprint 3): PK autoincremental, FKs a `estudiantes`/`materias`, soft delete vía `activo`, timestamps automáticos.

**Cálculo en el Model, no en un GradeService separado:** el codebase no tiene capa de servicios por feature (solo `mailService` es una excepción global). Se mantuvo el patrón existente: la lógica de promedio ponderado y proyección vive como métodos estáticos en `Grade.js`, y el controlador orquesta/valida — igual que `Schedule.detectConflicts()`.

**Exportación PDF/Excel diferida a Sprint 7**, replicando la decisión ya tomada en Sprint 3 con la exportación de horarios. El núcleo (registro, cálculo, dashboard, gráficas) queda 100% funcional sin bloquear el sprint por una feature de prioridad Media/Baja.

## Estrategia de ramas (Git)

Dado que el objetivo de este sprint era una prueba rápida con un compañero (sin PR), se trabajó directo sobre una única rama umbrella creada desde `dev`, sin sub-ramas:

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-4-grades-system
```

Cierre: commit único con convención `feat(grades): ...` + `git push origin feature/sprint-4-grades-system`. Sin PR — el compañero prueba corriendo la rama localmente (`flutter run`), ya que el pipeline de distribución por Firebase (`.github/workflows/firebase-distribution.yml`) solo se dispara con push a `main`.

## Plan técnico por fases

### Fase 1 — Base de datos
```sql
CREATE TABLE calificaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  id_materia INT NOT NULL,
  tipo ENUM('parcial','taller','quiz','proyecto','laboratorio','final','otro') NOT NULL DEFAULT 'otro',
  descripcion VARCHAR(150),
  valor DECIMAL(3,2) NOT NULL,
  porcentaje DECIMAL(5,2) NOT NULL,
  fecha_evaluacion DATE,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id),
  FOREIGN KEY (id_materia) REFERENCES materias(id)
);
```
`fecha_creacion`/`fecha_actualizacion` se usan (en vez de `created_at`/`updated_at`) para mantener la convención real ya usada en `horarios` y `notas`, verificada contra el dump real de la base de datos de producción.

Al no existir un runner de migraciones en el proyecto (igual que en Sprint 3), la tabla se entrega como script SQL (`backend/seeds/sprint4_demo_seed.sql`, incluido junto al seed de datos demo) para ejecutar manualmente en la consola de AlwaysData.

### Fase 2 — API de calificaciones (backend)
**`backend/src/models/Grade.js`**
- `create(data)`, `findByStudent(id_estudiante)`, `findById(id)`, `findBySubject(id_estudiante, id_materia)`, `update(id, fields)`, `delete(id)` (soft delete), todos con JOIN a `materias` para `materia_nombre`/`materia_color`.
- `getSubjectAverage(id_estudiante, id_materia)` — promedio ponderado `SUM(valor*porcentaje)/SUM(porcentaje)`.
- `getGeneralAverage(id_estudiante)` — promedio general como media de los promedios por materia.
- `getProjectedGrade(id_estudiante, id_materia, targetAverage=3.0)` — nota necesaria en el porcentaje restante para alcanzar la nota objetivo, con manejo de casos borde (materia sin evaluaciones, 100% ya acumulado, imposible matemáticamente aprobar si supera 5.0).

**`backend/src/controllers/gradeController.js`**
- `createGrade`, `getMyGrades`, `getGradeById`, `getGradesBySubject`, `updateGrade`, `deleteGrade`, `getSummary` (dashboard: promedio general + lista de materias con su promedio y banda de color), `getSubjectProjection`.
- `id_estudiante` siempre tomado de `req.user.id` (JWT), nunca del body. Verificación de ownership (403) antes de mutar/leer un registro puntual.

**`backend/src/routes/gradeRoutes.js`**
```
POST   /api/grades
GET    /api/grades
GET    /api/grades/summary
GET    /api/grades/subject/:id
GET    /api/grades/subject/:id/projection
GET    /api/grades/:id
PUT    /api/grades/:id
DELETE /api/grades/:id
```
Todas protegidas con `authMiddleware`; rutas literales declaradas antes de `/:id`. Montadas en `backend/src/app.js` bajo `/api/grades`.

### Fase 3 — Modelo y servicio (mobile)
- `mobile/lib/models/grade.dart` — `Grade`, `SubjectAverage`, `GradesSummary`, `SubjectProjection`, con parseo defensivo de los `DECIMAL` que MySQL devuelve como string (`valor`, `porcentaje`), getters de banda de color y estado de aprobación.
- `mobile/lib/services/grade_service.dart` — sobre `ApiService`, mismo patrón que `schedule_service.dart`.
- `mobile/lib/config/api_config.dart` — constantes de endpoints de calificaciones.

### Fase 4 — GradeProvider y estado (mobile)
- `mobile/lib/providers/grade_provider.dart` — `ChangeNotifier` con cache local (`SharedPreferences`, clave `cached_grades`), `initialize/load/createGrade/updateGrade/deleteGrade/refresh`, resumen de dashboard vía `loadSummary()`.
- Registrado en el `MultiProvider` de `mobile/lib/main.dart`.

### Fase 5 — Pantallas y widgets (mobile)
**`mobile/lib/screens/grades/`**
- `grades_screen.dart` — Dashboard: promedio general (`AverageIndicator` + `ProgressRing`), lista de materias con su promedio, gráfica de tendencia, FAB para nueva calificación.
- `subject_grades_screen.dart` — Detalle por materia: promedio ponderado, tarjeta de proyección ("necesitás sacar X para aprobar" / ya aprobada / matemáticamente imposible), lista de evaluaciones, gráfica de barras por tipo.
- `grade_form_screen.dart` — Crear/editar: selector de materia, selector de tipo de evaluación, input de nota (0–5) y porcentaje (0–100), descripción y fecha opcionales.

**`mobile/lib/widgets/grades/`**
- `grade_card.dart`, `average_indicator.dart`, `progress_ring.dart`, `grade_chart.dart` (`GradeLineChart` + `GradeBarChart` con `fl_chart`), `subject_grades_list.dart`.

**Entrada**: sección "Mis Calificaciones" agregada al dashboard (`home_screen.dart`), con banner de promedio general y "Ver todo →" hacia `GradesScreen`.

### Fase 6 — Datos simulados (demo)
Script SQL autocontenido (`backend/seeds/sprint4_demo_seed.sql`) con un estudiante demo de Ingeniería de Sistemas (`demo@uniplan.co` / `Uniplan2026`, hash bcrypt real generado con el mismo costo que usa el backend) y datos coherentes en **todos** los módulos existentes (materias, tareas, horarios, notas, eventos de calendario, sesiones Pomodoro) más ~20 calificaciones distribuidas entre 6 materias, diseñadas para mostrar los tres estados visuales (verde, amarillo, rojo) y al menos una materia con evaluaciones pendientes para ejercitar la proyección de nota.

### Fase 7 — Verificación
- Backend: verificación de sintaxis/carga de módulos (`node -c`, `require` en seco) — no se ejecutó contra la base real porque la tabla se crea manualmente en AlwaysData.
- Mobile: `flutter pub get` y `flutter analyze` sin errores nuevos en los archivos de calificaciones (solo deuda técnica preexistente en archivos no tocados).
- Revisión adversarial fresh-context (R1 Riesgo + R3 Confiabilidad) sobre el cálculo de promedios/proyección, validación de inputs y autorización antes del commit.

### Fase 8 — Cierre de sprint y documentación
- Actualizar `UNIPLAN_MVP.md`: Sprint 4 a núcleo funcional completo (export diferida a Sprint 7, igual que Sprint 3).
- Actualizar "Próximas 5 tareas prioritarias".
- Commit + push de la rama `feature/sprint-4-grades-system`. Sin PR.

## Orden y dependencias
1. **Fase 1 + Fase 2** (base de datos + API backend) en paralelo con el diseño de Fase 3.
2. **Fase 3 + Fase 4** (modelo/servicio/provider mobile) dependen del contrato de API definido en Fase 2, pero se construyeron en paralelo con el backend usando el contrato acordado de antemano (no bloqueante).
3. **Fase 5** (pantallas/widgets) depende de Fase 3 + Fase 4.
4. **Fase 6** (datos demo) es independiente, solo depende del esquema de Fase 1.
5. **Fase 7** (verificación) al cierre de las fases 2, 5 y 6.
6. **Fase 8** al final.

## Definition of Done — Sprint 4
- Backend: tabla `calificaciones` definida (DDL entregado), modelo + controlador + rutas operativas, promedio ponderado y proyección de nota funcionando.
- Mobile: `GradeProvider` activo con cache local y estado reactivo.
- Mobile: Dashboard de calificaciones con promedio general y por materia visibles, con bandas de color.
- Mobile: Formulario de registro/edición de calificación operativo con validación de rango.
- Mobile: Gráficas de línea y barras con `fl_chart`.
- Mobile: Entrada visible desde el Home ("Mis Calificaciones").
- Datos simulados de un estudiante completo entregados como SQL para AlwaysData.
- `UNIPLAN_MVP.md` actualizado confirmando el cierre del núcleo de Sprint 4.
- Exportación PDF/Excel explícitamente diferida a Sprint 7 (no cuenta como pendiente bloqueante).

## Riesgos y mitigación
- **Riesgo**: los campos `DECIMAL` de MySQL llegan como string vía `mysql2`, pudiendo causar concatenación en vez de suma si no se parsean bien tanto en backend (JS) como en mobile (Dart).
  **Mitigación**: parseo explícito a número en ambos lados; verificado en revisión de confiabilidad antes del commit.

- **Riesgo**: la proyección de nota puede dar resultados sin sentido si `porcentaje_acumulado` ya es 100% o si el peso restante es 0.
  **Mitigación**: `getProjectedGrade` maneja explícitamente los casos borde (materia ya cerrada, imposible matemáticamente si la nota necesaria supera 5.0).

- **Riesgo**: sin capa de migraciones, la tabla `calificaciones` y los datos demo dependen de que el usuario ejecute el SQL manualmente en AlwaysData; un error de copiado podría dejar la tabla a medio crear.
  **Mitigación**: script único, idempotente en su DDL (`CREATE TABLE IF NOT EXISTS`), con comentarios claros y verificado sintácticamente antes de entregar.

- **Riesgo**: sin PR ni CI, no hay pipeline de distribución (Firebase) para que el compañero pruebe un APK directamente.
  **Mitigación**: documentado que la prueba se hace corriendo la rama localmente con `flutter run`, no hace falta merge a `main`.
