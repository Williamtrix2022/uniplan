# 🎓 Uniplan — Evaluación y Evolución (post-MVP)
> **Aplicación móvil para la organización académica y gestión del estudio universitario**
> Universidad de Córdoba · Ingeniería de Sistemas

---

## 📋 Por qué este documento reemplaza a `UNIPLAN_MVP.md`

UNIPLAN v1.0.0 fue construido, documentado y validado funcionalmente (17 casos
de prueba de caja negra, 100 % aprobados; SUS global 4,19/5 con un grupo piloto
de 15 estudiantes). El proyecto entró en una fase distinta: **evaluación con
estudiantes reales** (diseño cuasiexperimental de un solo grupo, pretest–postest,
6–8 semanas) y **evolución del software a partir de esa evidencia**, no de
supuestos del equipo.

Fuente de este documento: `UNIPLAN_Evaluacion_y_Evolucion_Propuesta_de_Investigacion.docx`
(Anexo B: backlog de funcionalidades) + verificación directa del código en
`mobile/` y `backend/` al **2026-10-15**. Versión actual en producción:
**v1.0.5+6**. Registro: Dirección Nacional de Derecho de Autor de Colombia,
Libro–Tomo–Partida **13-108-364** (20 may 2026).

Convención de este documento: toda afirmación sobre el código cita
`archivo:línea`. Donde el `.docx` supone algo que el código contradice, se
marca explícitamente como **⚠️ Desviación del documento de investigación**.

---

## 🎯 Objetivo específico que rige esta fase (OE3)

> *"Diseñar e implementar mejoras funcionales y de experiencia de usuario en
> UNIPLAN a partir de los resultados obtenidos durante su evaluación con
> estudiantes universitarios."*

Principio rector: **las mejoras se derivan de evidencia (hallazgos de pruebas
con estudiantes + postest + datos reales de uso), no de intuición del equipo.**
Se priorizan con MoSCoW (Debe / Debería / Podría) y esfuerzo S/M/L.

---

## 🧩 Hallazgos (H01–H12)

Los H01–H11 son del documento de investigación (Tabla 7, sección 7.1). **H12 es
nuevo**, aportado por el usuario del proyecto y confirmado por el código — no
está en el `.docx` todavía.

| ID | Hallazgo | Módulo | Tipo de mantenimiento |
|----|----------|--------|------------------------|
| H01 | El campo para crear una materia está muy oculto (en el horario y dentro de otros formularios). | Materias / Horario | Perfectivo |
| H02 | Se requiere cambiar el orden entre evento y horario. | Calendario | Perfectivo |
| H03 | El registro de usuario debe ser más intuitivo (UX/UI). | Acceso | Perfectivo |
| H04 | El inicio de sesión debe verse más moderno e intuitivo. | Acceso | Perfectivo |
| H05 | No existe un recorrido de bienvenida (onboarding) que explique cómo usar la aplicación antes de registrarse. | Acceso | Perfectivo |
| H06 | No se presentan términos y condiciones. | Acceso / Perfil | Adaptativo |
| H07 | La sección de ayuda requiere contenido. | Perfil | Perfectivo |
| H08 | La opción de temas requiere implementación. | Perfil | Perfectivo |
| H09 | Las tareas completadas no actualizan las estadísticas. | Tareas / Progreso | Correctivo |
| H10 | Al terminar un Pomodoro no se actualiza la racha. | Pomodoro / Inicio | Correctivo |
| H11 | La aplicación depende de la conexión a internet para funcionar. | Transversal | Adaptativo |
| **H12** ⚠️ | El menú principal expone **"Notas"** (calificaciones) como ítem de primer nivel; no existe **"Materias"**. El flujo correcto es Materias en el menú, con Notas dentro de cada materia — es la jerarquía inversa a la actual. No está en el `.docx`. | Materias / Notas | Perfectivo |

---

## 📦 Backlog priorizado (MJ-01…MJ-12)

Prioridad MoSCoW, esfuerzo (S = ≤1 día, M = 2–4 días, L = >4 días), versión
objetivo.

| ID | Mejora | Hallazgo | Prioridad | Esfuerzo | Versión |
|----|--------|----------|-----------|----------|---------|
| MJ-01 | Actualizar las estadísticas al completar tareas | H09 | Debe | S | v1.1.0 |
| MJ-02 | Actualizar la racha al terminar un Pomodoro | H10 | Debe | S–M | v1.1.0 |
| MJ-03 | Hacer visible la creación de materias | H01 | Debe | S | v1.1.0 |
| MJ-04 | Reordenar Calendario: Horario primero, Eventos después | H02 | Debería | S | v1.3.0 |
| MJ-05 | Registro de usuario más intuitivo | H03 | Debería | M | v1.2.0 |
| MJ-06 | Rediseño moderno del inicio de sesión | H04 | Debería | M | v1.2.0 |
| MJ-07 | Onboarding antes del registro | H05 | Debería | M | v1.2.0 |
| MJ-08 | Términos, condiciones y política de datos | H06 | Debe | S–M | v1.1.0 |
| MJ-09 | Sección de ayuda funcional + reporte de problemas | H07 | Podría | S | v1.3.0 |
| MJ-10 | Temas de apariencia (modo oscuro) | H08 | Podría | M→**L** ⚠️ | v1.3.0 |
| MJ-11 | Funcionamiento sin conexión (modo offline) | H11 | Debería | L | v2.0.0 |
| **MJ-12** ⚠️ | Invertir jerarquía: "Materias" en el menú principal, "Notas" dentro de cada materia | H12 | Debería | M | v1.1.0 |

> ⚠️ MJ-10 se reclasifica de esfuerzo **M a L**: ver su ficha — requiere
> `ThemeMode` + provider + migrar widgets que hoy leen colores estáticos, no
> solo una pantalla de preferencias.

**Sprint 5 (requerimientos del postest) queda fuera de este backlog.** Depende
de datos que todavía no existen (el postest no se aplicó). Se documentará
cuando haya evidencia — no se inventan tareas con estado antes de tiempo.

---

## 📝 Especificación de las mejoras

Cada ficha sigue el formato del Anexo B.4 del documento de investigación:
hallazgo de origen, historia de usuario, situación actual, solución propuesta,
criterios de aceptación, componentes afectados. Donde la exploración del código
corrigió un supuesto del `.docx`, se indica con ⚠️.

### MJ-01. Actualizar las estadísticas al completar tareas
| | |
|---|---|
| Hallazgo | H09 |
| Tipo · prioridad | Correctivo · Debe · S · v1.1.0 (Sprint 1) |
| Historia de usuario | Como estudiante, quiero que al marcar una tarea como completada se actualicen mis estadísticas, para ver mi avance real sin reiniciar la aplicación. |

**Situación actual (verificada en código, no en `.docx`):**
- ⚠️ El documento asume que falta escribir en una tabla de progreso. **Falso**:
  `progreso_academico` existe en `backend/db/schema.sql:172-186` pero **ningún
  archivo de `backend/src` la lee ni la escribe**. Las estadísticas se calculan
  en vivo sobre `tareas` vía `Task.getStats` (`backend/src/models/Task.js:194-211`)
  y se agregan en `GET /api/dashboard` (`backend/src/controllers/dashboardController.js:12-73`).
- No existe checkbox de completar en ninguna lista. La única vía de la UI es el
  chip de estado dentro del formulario de edición
  (`mobile/lib/screens/tasks/task_form_screen.dart:471`), que llama
  `_taskService.updateTask(...)` → `PUT /api/tasks/:id`
  (`mobile/lib/services/task_service.dart:132-137`).
- `TaskProvider.toggleTask` y `TaskProvider.stats`
  (`mobile/lib/providers/task_provider.dart:131-159`, `:235-245`) son **código
  muerto** — ninguna pantalla los invoca. El endpoint
  `PATCH /api/tasks/:id/toggle` ya existe en el backend
  (`backend/src/routes/taskRoutes.js:37`, `taskController.toggleTaskComplete`)
  y está sin uso.
- Home (`home_screen.dart:147-206`) y Perfil (`profile_screen.dart:266-305`)
  solo refrescan sus contadores por navegación (`initState` + `.then()` tras un
  `Navigator.push`), nunca por un evento disparado por la mutación.

**Solución propuesta:** agregar un control de completar real (checkbox o swipe)
en la lista de tareas y en Home, conectado al endpoint `toggle` existente;
revivir `TaskProvider.toggleTask` como fuente única de verdad (o reemplazarlo
si el provider deja de ser el patrón, ver MJ-03); emitir un evento/callback que
Home y Perfil escuchen para refrescar sus contadores sin depender de la
navegación. **No** se escribe en `progreso_academico` — se documenta por qué
en el propio PR, para que no se reabra como pendiente.

**Criterios de aceptación:**
1. Al completar una tarea desde la lista o desde Home, el contador de tareas
   del perfil y del dashboard cambia sin salir de la pantalla.
2. Al revertir una tarea a pendiente, los indicadores se recalculan igual.
3. `GET /api/tasks/stats` (hoy sin uso desde la app,
   `mobile/lib/config/api_config.dart:39`) se conecta o se decide
   explícitamente no usarlo, pero no queda código muerto apuntando a un
   endpoint fantasma.
4. Regresión manual sobre los casos CP-008 y CP-013 de la validación v1.0.0.

**Componentes afectados:** `TaskProvider`, `task_form_screen.dart`,
`tasks_screen.dart`, `home_screen.dart`, `profile_screen.dart`, endpoint
`PATCH /api/tasks/:id/toggle` (ya existe, solo falta consumirlo).

---

### MJ-02. Actualizar la racha al terminar un Pomodoro
| | |
|---|---|
| Hallazgo | H10 |
| Tipo · prioridad | Correctivo · Debe · S–M · v1.1.0 (Sprint 1) |
| Historia de usuario | Como estudiante, quiero que mi racha y mis pomodoros de la semana aumenten al terminar una sesión, para que mi esfuerzo quede registrado. |

**Situación actual (más grave que lo descrito en el `.docx`):**
- ⚠️ El documento dice que "la tarjeta no cambia al terminar un Pomodoro".
  La causa raíz es peor: `_saveSession(completed: true)` solo se llama cuando
  `completedAllCycles` es verdadero, es decir
  `currentCycle >= cyclesBeforeLongBreak` (default 4,
  `mobile/lib/screens/pomodoro/pomodoro_screen.dart:235,245` y
  `mobile/lib/models/pomodoro_preferences.dart:13`). **Terminar un solo
  pomodoro no persiste absolutamente nada.**
- Si el usuario cierra la pantalla a mitad de sesión (`dispose`,
  `pomodoro_screen.dart:84-89`), tampoco se guarda nada — ni como abandonada.
- ⚠️ No existe ningún cálculo de racha en el repositorio. Grep de
  `racha|streak` en `backend/src` → cero resultados. La tarjeta "Racha actual"
  (`home_screen.dart:549-610`) en realidad muestra `sesiones_completadas` de
  una **ventana móvil de 7 días** (`Pomodoro.getStats`,
  `backend/src/models/Pomodoro.js:182,197`), no una racha de días consecutivos.

**Solución propuesta:**
1. Persistir cada ciclo de concentración completado al llegar a 0, no solo al
   cerrar el set de 4 ciclos — mover la llamada de guardado al branch
   trabajo→descanso de `_onTimerComplete`
   (`pomodoro_screen.dart:200-264`), con `ciclos_completados` incrementando por
   ciclo real.
2. Implementar racha real en el backend: nueva consulta en
   `backend/src/models/Pomodoro.js` que cuente días consecutivos con al menos
   una sesión `completada = TRUE`, terminando en hoy o ayer.
3. Corregir la tarjeta de Home para mostrar la racha real junto con (o en vez
   de) el conteo semanal, sin cambiar el nombre visible a los usuarios sin
   avisar en el postest.

**Criterios de aceptación:**
1. Al completar un ciclo de concentración (no los 4), el contador sube de
   inmediato.
2. La racha aumenta una vez por día y se reinicia si pasa un día calendario sin
   ningún pomodoro completado.
3. Las sesiones detenidas antes de tiempo no suman ni a la racha ni al conteo.
4. Regresión manual sobre el caso CP-011.

**Componentes afectados:** `pomodoro_screen.dart`, `Pomodoro.js`,
`pomodoroController.js`, `home_screen.dart` (tarjeta de racha).

---

### MJ-03 + MJ-12. Materias de primer nivel, Notas dentro de cada materia
| | |
|---|---|
| Hallazgo | H01 + H12 ⚠️ |
| Tipo · prioridad | Perfectivo · Debe/Debería · S + M · v1.1.0 (Sprint 1) |
| Historia de usuario | Como estudiante, quiero encontrar fácilmente dónde crear y ver mis materias, y encontrar las notas de cada una dentro de ella — no al revés. |

**Situación actual:**
- "Notas" en el menú inferior (`mobile/lib/widgets/bottom_nav_bar.dart:47-50`,
  tab índice 3) en realidad abre `GradesScreen` ("Mis Notas") —
  **es el módulo de calificaciones, no de apuntes**. No existe ninguna
  función de apuntes de texto en Flutter, aunque el backend sí tiene tabla
  `notas`/`Note.js` sin consumidor.
- `ManageSubjectsScreen` (`mobile/lib/screens/grades/manage_subjects_screen.dart:12`)
  **ya existe y ya funciona** — crear/eliminar materia, FAB → `_CreateSubjectDialog`
  (`:314`). El problema no es construirla, es que no tiene destino de primer
  nivel: cuatro pantallas distintas la empujan como paso intermedio
  (`grades_screen.dart:371`, `grade_form_screen.dart:79`,
  `schedule_form_screen.dart:69`, `task_form_screen.dart:187`).
- No hay `SubjectProvider`: cada pantalla instancia `SubjectService()` por su
  cuenta (al menos 4 instancias distintas).

**Solución propuesta:**
1. Sustituir el tab "Notas" del menú inferior por **"Materias"**
   (`bottom_nav_bar.dart`), apuntando a una pantalla de materias de primer
   nivel que promueva `ManageSubjectsScreen` (o la reemplace con una versión
   enriquecida: lista + acceso a notas + acceso a tareas de esa materia).
2. Dentro de cada materia, mostrar sus notas — reutilizando
   `SubjectGradesScreen` (`mobile/lib/screens/grades/subject_grades_screen.dart:17`),
   que ya filtra por `idMateria`.
3. Crear `SubjectProvider` (patrón `ChangeNotifier` + caché en
   `SharedPreferences`, igual a `GradeProvider`/`TaskProvider`) y migrar las 4
   pantallas que hoy instancian `SubjectService()` suelto.
4. Mantener accesos rápidos a "crear materia" desde los formularios de tarea y
   horario cuando no existan materias (empty state con CTA).

**Criterios de aceptación:**
1. Desde el menú inferior, "Materias" lleva a la lista de materias en un toque.
2. Un usuario nuevo llega a "Nueva materia" en máximo dos toques desde el
   inicio.
3. Dentro de una materia se ven sus notas; no hay acceso a notas sin pasar por
   una materia.
4. Si no hay materias, los formularios de tarea y horario muestran un acceso
   directo para crearlas.
5. Prueba con 5 usuarios: al menos 4 encuentran "crear materia" sin ayuda.

**Componentes afectados:** `bottom_nav_bar.dart`, `ManageSubjectsScreen`,
`SubjectGradesScreen`, `SubjectProvider` (nuevo), `grades_screen.dart`,
`grade_form_screen.dart`, `schedule_form_screen.dart`, `task_form_screen.dart`.

---

### MJ-04. Reordenar Calendario: Horario primero, Eventos después
| | |
|---|---|
| Hallazgo | H02 |
| Tipo · prioridad | Perfectivo · Debería · S · v1.3.0 (Sprint 3) |
| Historia de usuario | Como estudiante, quiero que al entrar a Calendario vea primero mi horario de clases, y pueda cambiar a eventos puntuales cuando lo necesite. |

**Alcance reducido a pedido explícito del usuario:** no se separan los modelos
`Schedule` y `CalendarEvent` (quedan como están, incluida la superposición de
`CalendarEvent.tipo: 'clase'` con los bloques recurrentes de `Schedule` — fuera
de alcance de esta mejora). El cambio es puramente de **orden por defecto**.

**Situación actual:** `calendar_screen.dart:43` inicializa
`int _viewIndex = 0; // 0 = Eventos, 1 = Horario` — la pantalla abre siempre en
Eventos. El toggle visual es un `SegmentedPillControl(labels: ['Eventos', 'Horario'])`
(`:229-232`).

**Solución propuesta:** invertir el valor inicial de `_viewIndex` a `1`
(Horario) y, si corresponde visualmente, el orden de las etiquetas del
`SegmentedPillControl` para que "Horario" aparezca primero. Sin cambios en los
formularios, modelos o endpoints.

**Criterios de aceptación:**
1. Al entrar a Calendario, la vista inicial es Horario.
2. El usuario puede cambiar a Eventos con un toque, igual que antes.
3. El FAB conserva su comportamiento contextual (según la pestaña activa).

**Componentes afectados:** `mobile/lib/screens/calendar/calendar_screen.dart`
(solo).

---

### MJ-05. Registro de usuario más intuitivo
| | |
|---|---|
| Hallazgo | H03 |
| Tipo · prioridad | Perfectivo · Debería · M · v1.2.0 (Sprint 2) |
| Historia de usuario | Como nuevo usuario, quiero un registro corto y claro, para crear mi cuenta sin errores ni dudas. |

**Situación actual:** un único `Form` (`register_screen.dart:21,158`) con 4
campos simultáneos, sin pasos. Esto coincide con la dimensión peor valorada en
la validación de v1.0.0: protección frente a errores (72,5 %).

**Solución propuesta:** registro por pasos (cuenta → perfil académico),
validación en línea, indicador de seguridad de contraseña, mensajes de error
específicos, listas de selección en vez de texto libre donde aplique.

**Criterios de aceptación:**
1. Cada campo inválido muestra un mensaje específico antes de enviar.
2. El registro completo toma menos de 90 segundos en prueba con usuarios.
3. Regresión sobre CP-001.

**Componentes afectados:** `mobile/lib/screens/auth/register_screen.dart`,
API de autenticación (sin cambios de contrato).

---

### MJ-06. Rediseño moderno del inicio de sesión
| | |
|---|---|
| Hallazgo | H04 |
| Tipo · prioridad | Perfectivo · Debería · M · v1.2.0 (Sprint 2) |
| Historia de usuario | Como estudiante, quiero una pantalla de inicio de sesión moderna y clara, para ingresar rápido y con confianza. |

**Situación actual — "Recordar sesión" no es solo visual:**
- ⚠️ El documento lo trata como un ítem más del rediseño. En el código,
  **"recordar sesión" está roto de raíz**: `AuthService.loadToken()` y
  `isAuthenticated()` (`mobile/lib/services/auth_service.dart:364-371,289-292`)
  están definidos pero **nunca se llaman**. `SplashScreen`
  (`mobile/lib/screens/splash_screen.dart:55-65`) espera 2500 ms y hace
  `pushReplacement` a `LoginScreen` sin condición — un usuario con sesión
  válida vuelve a ver el login cada vez que abre la app.

**Solución propuesta:** rediseño visual (contraste AA, jerarquía
"Iniciar sesión" vs "Crear cuenta", mostrar/ocultar contraseña, indicador de
carga) **más** conectar `SplashScreen` a `loadToken()`/`isAuthenticated()` para
que una sesión válida salte directo a Home.

**Criterios de aceptación:**
1. Contraste de textos y botones cumple WCAG 2.1 nivel AA.
2. Con un token válido guardado, abrir la app no pasa por Login.
3. Durante la validación se muestra un indicador de carga y el botón se
   deshabilita.
4. Regresión sobre CP-002, CP-003, CP-004.

**Componentes afectados:** `login_screen.dart`, `splash_screen.dart`,
`auth_service.dart` (solo conectar lo existente, sin nuevo contrato).

---

### MJ-07. Onboarding antes del registro
| | |
|---|---|
| Hallazgo | H05 |
| Tipo · prioridad | Perfectivo · Debería · M · v1.2.0 (Sprint 2) |
| Historia de usuario | Como usuario nuevo, quiero ver en pocas pantallas qué hace UNIPLAN y cómo usarlo, para decidir registrarme con claridad. |

**Situación actual:** no existe ningún onboarding ni flag de primera apertura.
Grep de `onboard|welcome|bienvenid|tutorial` en `lib/` → una sola coincidencia
textual sin relación (`login_screen.dart:256`, literal "Bienvenido de nuevo").

**Solución propuesta:** secuencia de 3–4 pantallas (organiza materias y
tareas · planifica con el calendario · estudia con Pomodoro · mide tu
progreso), con "Saltar"/"Comenzar", mostrada solo la primera vez (flag en
`SharedPreferences`), con acceso posterior desde Ayuda (MJ-09).

**Criterios de aceptación:**
1. Aparece solo en la primera apertura.
2. Se puede omitir en cualquier momento.
3. Al finalizar, lleva a "Crear cuenta".

**Componentes afectados:** pantallas nuevas de bienvenida,
`SharedPreferences` (flag), `splash_screen.dart` (ruta inicial).

---

### MJ-08. Términos, condiciones y política de datos
| | |
|---|---|
| Hallazgo | H06 |
| Tipo · prioridad | Adaptativo · Debe · S–M · v1.1.0 (Sprint 1) |
| Historia de usuario | Como usuario, quiero conocer y aceptar cómo se usan mis datos, para registrarme con confianza. |

**Situación actual — está más avanzado de lo que dice el `.docx`:**
- ⚠️ El documento afirma "la aplicación no presenta términos y condiciones".
  **Parcialmente cierto**: el checkbox de aceptación **ya existe y ya bloquea
  el envío** (`register_screen.dart:30` `_acceptedTerms`, validación `:69-72`,
  widget `:284-291`). Lo que falta es el contenido: el texto
  "Términos y Condiciones" es un `TextSpan` sin `recognizer` (`:297-313`) —
  **no es tocable**, no existe pantalla ni documento al que apunte, y Perfil no
  tiene ningún ítem de términos.

**Solución propuesta:** redactar términos y política de tratamiento de datos
(Ley 1581 de 2012); crear pantalla/documento accesible; hacer tocable el
`TextSpan` del registro; migración sobre `estudiantes` para guardar versión y
fecha de aceptación; agregar el ítem en Perfil.

**Criterios de aceptación:**
1. No es posible crear una cuenta sin aceptar los términos (ya cumplido, no
   regresionar).
2. El enlace del registro abre el documento real.
3. Se almacena versión y fecha de aceptación por usuario.
4. El documento se puede consultar desde el perfil.

**Componentes afectados:** `register_screen.dart`, pantalla nueva de
términos, migración sobre `estudiantes`, `profile_screen.dart`.

---

### MJ-09. Sección de ayuda funcional + reporte de problemas
| | |
|---|---|
| Hallazgo | H07 |
| Tipo · prioridad | Perfectivo · Podría · S · v1.3.0 (Sprint 3) |
| Historia de usuario | Como estudiante, quiero resolver mis dudas dentro de la aplicación y poder reportar un problema, para no depender de otra persona. |

**Situación actual:** el ítem "Ayuda" de Perfil es un stub —
`SnackBar('Próximamente')` (`profile_screen.dart:445-450`).

**Solución propuesta:** preguntas frecuentes por módulo, guía rápida, y
**"Reportar un problema o sugerencia"** (primer punto de la lista de mejoras
del usuario del proyecto) — tabla y endpoint nuevos de reportes con fecha y
módulo de origen.

**Criterios de aceptación:**
1. Existe al menos una FAQ por módulo principal.
2. Los reportes enviados quedan registrados con fecha y módulo.
3. El onboarding (MJ-07) es accesible de nuevo desde aquí.

**Componentes afectados:** `profile_screen.dart`, pantalla de ayuda nueva,
tabla `reportes` (nueva), endpoint `/api/reports`.

---

### MJ-10. Temas de apariencia (modo oscuro)
| | |
|---|---|
| Hallazgo | H08 |
| Tipo · prioridad | Perfectivo · Podría · ~~M~~ **L** ⚠️ · v1.3.0 (Sprint 3) |
| Historia de usuario | Como estudiante, quiero elegir entre modo claro y oscuro, para usar la aplicación cómodamente en cualquier momento del día. |

**⚠️ Desviación del documento — esfuerzo reclasificado de M a L:**
No existe ninguna base para construir sobre: sin `darkTheme`, sin `ThemeMode`,
sin provider, sin preferencia persistida
(`mobile/lib/config/theme.dart:42-44` define solo `AppTheme.lightTheme`; grep
de `ThemeMode|darkTheme|ThemeProvider` en `lib/` → cero resultados). Peor aún:
los widgets leen colores como constantes estáticas (`AppTheme.primaryColor`,
etc. — ej. `bottom_nav_bar.dart:21,26,27`) en vez de `Theme.of(context)`, así
que agregar un `darkTheme` **no se propagaría** sin migrar cada widget. El
ítem de Perfil es hoy un stub idéntico al de Ayuda
(`profile_screen.dart:416-421`).

**Solución propuesta:** `ThemeProvider` (`ChangeNotifier`, persistido en
`SharedPreferences`); `darkTheme` completo en `AppTheme`; migrar los widgets
de constantes estáticas a `Theme.of(context)`; modo claro/oscuro/según sistema;
revisar que `res/values-night/` (ya existe en Android) sea consistente.

**Criterios de aceptación:**
1. El cambio de tema se aplica de inmediato en todas las pantallas, no solo
   las migradas parcialmente.
2. La preferencia se conserva al cerrar y abrir la aplicación.
3. Ningún texto queda ilegible en modo oscuro (auditoría manual pantalla por
   pantalla).

**Componentes afectados:** `theme.dart`, `ThemeProvider` (nuevo), **todos**
los widgets que hoy referencian `AppTheme.*` directamente.

---

### MJ-11. Funcionamiento sin conexión (modo offline)
| | |
|---|---|
| Hallazgo | H11 |
| Tipo · prioridad | Adaptativo · Debería · L · v2.0.0 (Sprint 4) |
| Historia de usuario | Como estudiante, quiero consultar y registrar mis tareas, eventos, notas y sesiones Pomodoro sin conexión, para usar UNIPLAN en cualquier lugar. |

Ver el detalle completo, bloqueantes y veredicto en
**[`docs/OFFLINE_FIRST.md`](../OFFLINE_FIRST.md)**. Resumen de los dos
bloqueantes que el `.docx` no identifica:

1. ⚠️ El criterio "resolución de conflictos por fecha de última modificación"
   no es implementable hoy: `tareas`, `materias`, `eventos_calendario` y
   `notificaciones` solo tienen `fecha_creacion`
   (`backend/db/schema.sql:59,80,143,253`) — ninguna columna de última
   modificación. Solo `horarios`, `notas`, `calificaciones` y
   `preferencias_notificacion` sí la tienen.
2. ⚠️ Sin conexión, el usuario no puede ni entrar: `SplashScreen` siempre va a
   `LoginScreen` (ver MJ-06), y no hay `connectivity_plus` ni motor local
   (`sqflite`/`hive`/`drift` ausentes del `pubspec.yaml`; solo blobs JSON en
   `SharedPreferences` por provider, que se sobrescriben con la red en cada
   carga).

**Criterios de aceptación (del documento, sujetos al análisis de
`OFFLINE_FIRST.md`):**
1. Sin conexión, el estudiante puede consultar materias, tareas, eventos,
   notas y progreso.
2. Sin conexión, puede crear y editar tareas, eventos y notas, y completar
   sesiones Pomodoro.
3. Al recuperar la conexión, los cambios se sincronizan sin duplicar registros.
4. La aplicación indica si existen cambios pendientes por sincronizar.

**Componentes afectados:** motor local nuevo, `connectivity_plus`, cola de
operaciones, endpoint de sincronización incremental, migraciones de
`fecha_actualizacion` en 4 tablas, restauración de sesión en frío.

---

## 🗺️ Mapa de sprints

| Sprint | Mejoras | Versión | Documento |
|--------|---------|---------|-----------|
| Sprint 1 | MJ-01, MJ-02, MJ-03, MJ-08, MJ-12 | v1.1.0 | `docs/sprints/sprint-01.md` |
| Sprint 2 | MJ-05, MJ-06, MJ-07 | v1.2.0 | `docs/sprints/sprint-02.md` |
| Sprint 3 | MJ-04, MJ-09, MJ-10 | v1.3.0 | `docs/sprints/sprint-03.md` |
| Sprint 4 | MJ-11 | v2.0.0 | `docs/sprints/sprint-04.md` |
| Sprint 5 | Requerimientos del postest | v2.1.0 | **no creado** — depende de evidencia aún no recolectada |

Después del Sprint 4: ver `docs/PLAY_STORE.md` para la publicación.

---

## 🏗️ Estado real del código por módulo (2026-10-15)

| Módulo | Estado |
|--------|--------|
| Navegación | Sin shell ni rutas nombradas. 4 pantallas duplican `BottomNavBar`, cambian de tab con `pushAndRemoveUntil(..., (route) => false)` — destruye estado. |
| Auth | Login/Registro/Recuperación funcionales. Registro de un solo paso. Checkbox de términos ya bloquea envío, pero el enlace no es tocable. "Recordar sesión" roto (`loadToken()` nunca se llama). |
| Materias/Notas | `ManageSubjectsScreen` funcional pero enterrada. "Notas" = calificaciones, no apuntes. Sin `SubjectProvider`. |
| Tareas | CRUD completo. Toggle de completar existe en backend, sin uso desde la app. `TaskProvider.toggleTask` es código muerto. |
| Calendario/Horario | Mezclados en una pantalla con toggle; abre en Eventos. `CalendarEvent.tipo` admite `'clase'`, superpuesto conceptualmente con `Schedule`. |
| Pomodoro | Timer funcional, pero solo persiste al completar el set de 4 ciclos, no por ciclo. Sin cálculo de racha en ningún lado. |
| Perfil | Cambiar contraseña, Pomodoro config y Notificaciones reales. Temas y Ayuda son stubs `SnackBar`. |
| Temas | Solo modo claro. Sin infraestructura de theming dinámico. |
| Offline | Sin motor local real, sin detección de conectividad, sin cola de escritura. |
| Release Android | Firma condicional (release si existe `key.properties`, que existe). CI solo genera APK, nunca AAB. Sin ícono adaptativo. iOS es plantilla sin configurar. |

---

## ✅ Requisitos no funcionales de esta fase

| ID | Requisito | Criterio de aceptación |
|----|-----------|------------------------|
| RNF-E1 | Usabilidad | SUS ≥ 68 en el postest (referencia: 4,19/5 ≈ 79,8 % en v1.0.0) |
| RNF-E2 | Regresión | Los casos CP-001 a CP-017 de la validación v1.0.0 siguen pasando tras cada sprint |
| RNF-E3 | Accesibilidad | Contraste WCAG 2.1 AA en toda pantalla rediseñada (login, registro, onboarding) |
| RNF-E4 | Evidencia | Ninguna mejora fuera de MJ-01…MJ-12 se implementa sin hallazgo o dato de uso que la respalde (principio OE3) |

---

## 📊 Indicadores de uso a extraer para la investigación

(Anexo C.5 del documento — para que las consultas SQL del análisis estén
documentadas desde ya.)

| Indicador | Descripción | Tabla origen |
|-----------|-------------|--------------|
| Materias registradas | Número de materias creadas por el participante | `materias` |
| Tareas registradas | Número de tareas y evaluaciones creadas en el periodo | `tareas` |
| % tareas completadas | Completadas / registradas × 100 | `tareas` |
| Sesiones Pomodoro | Número de sesiones de concentración completadas | `sesiones_pomodoro` |
| Minutos de estudio | Suma de duración de sesiones completadas | `sesiones_pomodoro` |
| Días con actividad | Días con ≥1 registro de tarea o sesión | `tareas`, `sesiones_pomodoro` |

---

## 🔄 Control de versiones del documento

| Fecha | Actualizado por | Cambios |
|-------|------------------|---------|
| 15 Oct 2026 | Claude Code | Documento creado en reemplazo de `UNIPLAN_MVP.md`, a partir de `UNIPLAN_Evaluacion_y_Evolucion_Propuesta_de_Investigacion.docx` + verificación de código. Se agregó H12/MJ-12 (no presente en el `.docx`). MJ-04 reducido a solo-orden y MJ-10 reclasificado de esfuerzo M a L a partir de la exploración. |

---

<div align="center">

*Uniplan · Universidad de Córdoba · Ingeniería de Sistemas · 2026*

</div>
