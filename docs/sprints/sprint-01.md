# Plan de implementación — Sprint 1 (Correcciones y visibilidad de materias)

## Problema y alcance

Este sprint cierra los hallazgos correctivos y de visibilidad más urgentes
detectados tras la validación de v1.0.0, usando `docs/mvp/UNIPLAN_EVOLUCION.md`
como fuente de verdad: MJ-01 (las estadísticas no se actualizan al completar
tareas), MJ-02 (la racha de Pomodoro no se actualiza), MJ-03+MJ-12 (invertir
la jerarquía Materias/Notas en el menú principal) y MJ-08 (términos y
condiciones sin contenido real detrás del checkbox). Las cuatro mejoras son
prioridad "Debe" o "Debería" para la versión **v1.1.0**.

## Estado actual validado (código vs plan)

### Ya existente y reutilizable

- `PATCH /api/tasks/:id/toggle` ya existe en el backend
  (`backend/src/routes/taskRoutes.js:37`, `taskController.toggleTaskComplete`)
  y está sin uso desde la app.
- `Task.getStats` (`backend/src/models/Task.js:194-211`) calcula las
  estadísticas en vivo sobre `tareas` y se agrega en
  `GET /api/dashboard` (`backend/src/controllers/dashboardController.js:12-73`).
- `ManageSubjectsScreen` (`mobile/lib/screens/grades/manage_subjects_screen.dart:12`)
  ya implementa crear/eliminar materia, con FAB → `_CreateSubjectDialog` (`:314`).
- `SubjectGradesScreen` (`mobile/lib/screens/grades/subject_grades_screen.dart:17`)
  ya filtra notas por `idMateria`.
- El checkbox de aceptación de términos ya existe y ya bloquea el envío del
  registro (`mobile/lib/screens/auth/register_screen.dart:30` `_acceptedTerms`,
  validación `:69-72`, widget `:284-291`).

### Brechas detectadas para cerrar Sprint 1

- `TaskProvider.toggleTask` y `TaskProvider.stats`
  (`mobile/lib/providers/task_provider.dart:131-159`, `:235-245`) son código
  muerto: ninguna pantalla los invoca. No existe checkbox de completar en
  ninguna lista; la única vía es el chip de estado dentro del formulario de
  edición (`mobile/lib/screens/tasks/task_form_screen.dart:471`), que llama
  `PUT /api/tasks/:id` (`mobile/lib/services/task_service.dart:132-137`), no
  el endpoint de `toggle`.
- Home (`mobile/lib/screens/home_screen.dart:147-206`) y Perfil
  (`mobile/lib/screens/profile_screen.dart:266-305`) solo refrescan sus
  contadores por navegación (`initState` + `.then()` tras un
  `Navigator.push`), nunca por un evento disparado por la mutación.
- `_saveSession(completed: true)` del Pomodoro solo se llama cuando
  `completedAllCycles` es verdadero, es decir
  `currentCycle >= cyclesBeforeLongBreak` (default 4,
  `mobile/lib/screens/pomodoro/pomodoro_screen.dart:235,245` y
  `mobile/lib/models/pomodoro_preferences.dart:13`). Terminar un solo
  pomodoro no persiste nada. Si el usuario cierra la pantalla a mitad de
  sesión (`dispose`, `pomodoro_screen.dart:84-89`), tampoco se guarda nada.
- No existe ningún cálculo de racha en el repositorio (grep de
  `racha|streak` en `backend/src` → cero resultados). La tarjeta "Racha
  actual" (`mobile/lib/screens/home_screen.dart:549-610`) en realidad muestra
  `sesiones_completadas` de una ventana móvil de 7 días (`Pomodoro.getStats`,
  `backend/src/models/Pomodoro.js:182,197`), no días consecutivos.
- "Notas" en el menú inferior (`mobile/lib/widgets/bottom_nav_bar.dart:47-50`,
  tab índice 3) en realidad abre `GradesScreen` ("Mis Notas") — es
  calificaciones, no apuntes. `ManageSubjectsScreen` no tiene destino de
  primer nivel: cuatro pantallas la empujan como paso intermedio
  (`grades_screen.dart:371`, `grade_form_screen.dart:79`,
  `schedule_form_screen.dart:69`, `task_form_screen.dart:187`). No existe
  `SubjectProvider`: cada pantalla instancia `SubjectService()` por su
  cuenta (al menos 4 instancias distintas).
- El texto "Términos y Condiciones" del registro es un `TextSpan` sin
  `recognizer` (`register_screen.dart:297-313`): no es tocable, no existe
  pantalla ni documento al que apunte, y Perfil no tiene ningún ítem de
  términos.

## Decisiones de diseño

- **No se escribe en `progreso_academico`.** La tabla existe
  (`backend/db/schema.sql:172-186`) pero ningún archivo de `backend/src` la
  lee ni la escribe; las estadísticas ya se calculan en vivo vía
  `Task.getStats`. Escribir ahí crearía una segunda fuente de verdad sin
  consumidor y sin sincronización garantizada. Se documenta esta decisión en
  el propio PR para que no se reabra como pendiente.
- **Pomodoro se persiste por ciclo real**, no al cerrar el set de
  `cyclesBeforeLongBreak`. La racha se calcula en el backend sobre sesiones
  `completada = TRUE` por día, no se reutiliza la ventana de 7 días existente
  para ese cálculo (se mantiene esa consulta para el conteo semanal, que es
  un indicador distinto).
- **Materias sustituye a Notas como tab de primer nivel**; las notas
  (calificaciones) pasan a vivir dentro de cada materia. No se construye
  apuntes de texto libre — ese módulo no existe hoy ni está en el alcance de
  MJ-03/MJ-12. Se introduce `SubjectProvider` siguiendo el mismo patrón que
  `GradeProvider`/`TaskProvider` (ChangeNotifier + caché en
  `SharedPreferences`) para eliminar las 4 instancias sueltas de
  `SubjectService()`.
- **Términos y condiciones**: se hace tocable el `TextSpan` existente con un
  `TapGestureRecognizer`, se crea una pantalla nueva con el documento real, y
  se migra `estudiantes` para guardar versión y fecha de aceptación por
  usuario — sin tocar el contrato de registro ya existente (el checkbox que
  bloquea el envío no se regresiona).

## Estrategia de ramas (Git)

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-1-correcciones-visibilidad-materias
```

Sin PR por ahora — el usuario prueba la rama localmente antes de decidir el
paso siguiente.

## Plan técnico por fases

### Fase 1 — MJ-01: estadísticas al completar tareas

- Mobile: agregar un control de completar real (checkbox o swipe) en
  `tasks_screen.dart` y en `home_screen.dart`, conectado al endpoint
  `PATCH /api/tasks/:id/toggle` ya existente.
- Mobile: revivir `TaskProvider.toggleTask`
  (`mobile/lib/providers/task_provider.dart:131-159`) como fuente única de
  verdad para completar/revertir tareas.
- Mobile: emitir un evento/callback desde `TaskProvider` que
  `home_screen.dart:147-206` y `profile_screen.dart:266-305` escuchen para
  refrescar sus contadores sin depender de la navegación.
- Decidir explícitamente el uso (o no) de `GET /api/tasks/stats`
  (`mobile/lib/config/api_config.dart:39`, hoy sin consumidor) para no dejar
  código apuntando a un endpoint fantasma.

### Fase 2 — MJ-02: racha de Pomodoro

- Mobile: mover la llamada de guardado al branch trabajo→descanso de
  `_onTimerComplete` (`mobile/lib/screens/pomodoro/pomodoro_screen.dart:200-264`),
  con `ciclos_completados` incrementando por ciclo real, no solo al cerrar
  el set de 4.
- Backend: nueva consulta en `backend/src/models/Pomodoro.js` que cuente
  días consecutivos con al menos una sesión `completada = TRUE`, terminando
  en hoy o ayer.
- Backend: exponer la racha desde `pomodoroController.js` (nuevo campo en la
  respuesta de stats, sin romper el contrato existente del conteo semanal).
- Mobile: corregir la tarjeta "Racha actual" en `home_screen.dart:549-610`
  para mostrar la racha real junto con el conteo semanal.

### Fase 3 — MJ-03 + MJ-12: Materias de primer nivel, Notas dentro de cada materia

- Mobile: sustituir el tab "Notas" (`mobile/lib/widgets/bottom_nav_bar.dart:47-50`,
  índice 3) por "Materias", apuntando a una pantalla de primer nivel que
  promueva o enriquezca `ManageSubjectsScreen`
  (`mobile/lib/screens/grades/manage_subjects_screen.dart:12`).
- Mobile: dentro de cada materia, mostrar sus notas reutilizando
  `SubjectGradesScreen` (`mobile/lib/screens/grades/subject_grades_screen.dart:17`).
- Mobile: crear `SubjectProvider` (ChangeNotifier + caché en
  `SharedPreferences`, mismo patrón que `GradeProvider`/`TaskProvider`) y
  migrar las 4 pantallas que hoy instancian `SubjectService()` suelto:
  `grades_screen.dart:371`, `grade_form_screen.dart:79`,
  `schedule_form_screen.dart:69`, `task_form_screen.dart:187`.
- Mobile: mantener accesos rápidos a "crear materia" desde los formularios de
  tarea y horario cuando no existan materias (empty state con CTA).

### Fase 4 — MJ-08: términos, condiciones y política de datos

- Mobile: redactar términos y política de tratamiento de datos (Ley 1581 de
  2012); crear pantalla nueva accesible desde el registro y desde Perfil.
- Mobile: agregar `TapGestureRecognizer` al `TextSpan` de
  `register_screen.dart:297-313` para que abra la pantalla nueva.
- Mobile: agregar ítem de términos en `profile_screen.dart`.
- Backend: migración sobre `estudiantes` para guardar versión y fecha de
  aceptación:

```sql
ALTER TABLE estudiantes
  ADD COLUMN version_terminos_aceptados VARCHAR(20) DEFAULT NULL,
  ADD COLUMN fecha_aceptacion_terminos TIMESTAMP NULL DEFAULT NULL;
```

- Backend: guardar `version_terminos_aceptados` y
  `fecha_aceptacion_terminos` en el flujo de registro existente, sin cambiar
  el contrato de los campos ya validados (`_acceptedTerms` sigue bloqueando
  el envío).

## Verificación

```
cd mobile && flutter analyze
cd mobile && flutter test
cd backend && npm test
```

Regresión manual:

- [ ] CP-008 y CP-013 (validación v1.0.0) — MJ-01.
- [ ] CP-011 (validación v1.0.0) — MJ-02.
- [ ] Al completar una tarea desde la lista o desde Home, el contador de
  tareas del perfil y del dashboard cambia sin salir de la pantalla.
- [ ] Al revertir una tarea a pendiente, los indicadores se recalculan igual.
- [ ] No queda código apuntando a `GET /api/tasks/stats` sin decisión
  explícita documentada.
- [ ] Al completar un ciclo de concentración (no los 4), el contador sube de
  inmediato.
- [ ] La racha aumenta una vez por día y se reinicia si pasa un día
  calendario sin ningún pomodoro completado.
- [ ] Las sesiones detenidas antes de tiempo no suman ni a la racha ni al
  conteo.
- [ ] Desde el menú inferior, "Materias" lleva a la lista de materias en un
  toque.
- [ ] Un usuario nuevo llega a "Nueva materia" en máximo dos toques desde el
  inicio.
- [ ] Dentro de una materia se ven sus notas; no hay acceso a notas sin pasar
  por una materia.
- [ ] Si no hay materias, los formularios de tarea y horario muestran un
  acceso directo para crearlas.
- [ ] No es posible crear una cuenta sin aceptar los términos (no
  regresionar).
- [ ] El enlace del registro abre el documento real de términos.
- [ ] Se almacena versión y fecha de aceptación por usuario.
- [ ] El documento de términos se puede consultar desde el perfil.
