# Evaluación técnica — Funcionamiento sin conexión (offline-first)

> Documento de decisión para **MJ-11 / v2.0.0 / Sprint 4**. Responde a la
> sección 5.6 (marco referencial) y 7.3 (viabilidad) del documento de
> investigación. Se escribe **antes** de implementar y **antes** de publicar en
> Play Store (`docs/PLAY_STORE.md`), para decidir con evidencia si el modo
> offline va antes o después del lanzamiento.

Evidencia verificada en código al 2026-10-15. Toda afirmación cita
`archivo:línea`.

---

## 1. Qué funciona hoy sin conexión: nada de forma confiable

- `ApiService._send` siempre relanza la excepción
  (`mobile/lib/services/api_service.dart:97-99`); no hay retorno nulo ni
  fallback a caché en esta capa.
- `_handleError` traduce `SocketException` a `ApiException('Sin conexión a
  internet')` (`:173-183`) — es decir, el error se muestra lindo, pero la
  operación simplemente falla.
- Sí existe una caché, pero no es offline-first, es "pintar y luego pisar":
  `TaskProvider.loadTasks(useCache: true)` pinta el JSON cacheado y
  **siempre** llama a la red después (`task_provider.dart:77-100`); si la red
  falla, el error queda en `_error` pero lo que ya estaba en memoria se
  conserva — no hay una decisión explícita de "seguir usando la caché".
  El mismo patrón se repite en `schedule_provider.dart`, `grade_provider.dart`
  y `notification_provider.dart` (cada uno con su propia clave de
  `SharedPreferences`: `cached_tasks`, `cached_schedules`, `cached_grades`,
  `cached_notifications`).
- Las mutaciones (`createTask`, `updateTask`, `deleteTask`,
  `task_provider.dart:106-130`) son **online-only**: esperan la respuesta del
  servidor y relanzan el error si falla. No hay cola de operaciones
  pendientes en ningún provider.
- No hay detección de conectividad: `connectivity_plus` no está en
  `pubspec.yaml`. El único indicio de "sin red" es el string-matching sobre
  `SocketException` ya mencionado.

**Conclusión de esta sección:** no existe ningún offline real hoy, solo una
caché de lectura optimista sin estrategia de conflicto ni cola de escritura.

---

## 2. Los dos bloqueantes duros que el `.docx` no identifica

### 2.1. Sin columna de última modificación en las entidades más usadas

El criterio de aceptación del documento de investigación dice textualmente:
*"resolución de conflictos por fecha de última modificación"*. Verificación
sobre `backend/db/schema.sql`:

| Tabla | ¿Tiene `fecha_actualizacion` con `ON UPDATE`? | Línea |
|-------|---|---|
| `tareas` | ❌ No — solo `fecha_creacion` (+ `fecha_completada`) | `:80` |
| `materias` | ❌ No — solo `fecha_creacion` | `:59` |
| `eventos_calendario` | ❌ No — solo `fecha_creacion` | `:143` |
| `notificaciones` | ❌ No — solo `fecha_creacion` | `:253` |
| `horarios` | ✅ Sí | `:100` |
| `notas` | ✅ Sí | `:119` |
| `calificaciones` | ✅ Sí | `:232` |
| `preferencias_notificacion` | ✅ Sí | `:272` |

Las **cuatro entidades que el criterio de aceptación de MJ-11 menciona
explícitamente** ("tareas, eventos, notas y progreso" para consulta;
"tareas, eventos y notas" para registro) son justo las que **no** tienen
marca de última modificación, con la excepción de `notas` que sí la tiene.
Sin esa columna, "last-write-wins por fecha" no se puede implementar — no hay
fecha que comparar.

Tampoco hay marca temporal de borrado lógico: el patrón de soft-delete del
proyecto es `activo TINYINT(1)` sin fecha (visto en `Schedule`/`Subject`), así
que sincronizar una eliminación tampoco tiene con qué resolver el orden.

**Acción previa obligatoria:** migración que agregue
`fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE
CURRENT_TIMESTAMP` a `tareas`, `materias`, `eventos_calendario`,
`notificaciones`, y una columna de fecha de borrado lógico donde hoy solo hay
`activo`.

### 2.2. Sin conexión, el usuario no puede ni entrar

- `SplashScreen` (`mobile/lib/screens/splash_screen.dart:55-65`) espera 2500 ms
  y hace `pushReplacement` a `LoginScreen` **sin condición alguna** — no
  verifica si hay sesión ni si hay token.
- `AuthService.loadToken()` y `isAuthenticated()`
  (`mobile/lib/services/auth_service.dart:364-371,289-292`) existen pero
  **nunca se llaman** desde ningún archivo de `lib/`.
- El login mismo requiere red (`POST /auth/login`), así que un usuario sin
  conexión que abre la app por primera vez en el día queda bloqueado en la
  pantalla de login sin poder autenticarse ni con una sesión previa válida.

**Acción previa obligatoria:** esta es la misma corrección que ya está
planificada en Sprint 2 / MJ-06 (restaurar sesión en frío). **Debe estar
resuelta antes de empezar MJ-11** — si no, todo el trabajo de modo offline es
inútil porque la app nunca llega a mostrar datos sin red.

---

## 3. Motor de persistencia local — comparación

| Motor | A favor | En contra para este proyecto |
|-------|---------|-------------------------------|
| **sqflite** | SQL relacional, encaja 1:1 con el esquema MySQL existente (12 modelos Dart ya mapean filas de tablas relacionales); consultas de sincronización incremental (`WHERE fecha_actualizacion > ?`) son triviales de portar; comunidad y documentación maduras. | Requiere escribir el esquema local a mano y mantenerlo sincronizado con las migraciones del backend. |
| **drift** | Capa de tipado sobre sqflite, genera código, catches errores de esquema en compilación. | Curva de aprendizaje adicional (build_runner) para un equipo que hoy no usa code-gen en ningún otro lado del proyecto. |
| **hive**/**isar** | Más rápido para lecturas simples, sin SQL. | Modelo de datos no relacional — las consultas de `Task.getTasksBySubject`, `getSubjectAverage`, detección de conflictos de horario, etc. (hoy en SQL del lado del servidor) habría que reimplementarlas a mano en Dart; mayor riesgo de divergencia con el modelo del backend. |

**Recomendación: `sqflite`.** El dominio del proyecto (12 modelos, relaciones
materia↔tarea↔nota↔horario, consultas de agregación como promedios y
detección de conflictos) ya está modelado en SQL en el backend. Replicar ese
mismo modelo relacional en el cliente minimiza la lógica de traducción y deja
las consultas de sincronización (`WHERE fecha_actualizacion > ultima_sync`)
idénticas en ambos lados.

---

## 4. Diseño de la cola de operaciones y la sincronización incremental

**Cola de operaciones pendientes:** tabla local `operaciones_pendientes`
(`id`, `entidad`, `id_entidad_local`, `tipo` [`crear`/`actualizar`/`eliminar`],
`payload_json`, `fecha_creacion`, `intentos`). Cada mutación offline escribe
primero en la tabla local real (optimista) y encola una entrada aquí. Un
listener de conectividad (`connectivity_plus`) dispara el vaciado de la cola
en orden de creación cuando la red vuelve.

**Sincronización incremental:** nuevo endpoint
`GET /api/sync?since=<timestamp>` que devuelve, por entidad, los registros con
`fecha_actualizacion > since` (y los `activo = FALSE` recientes, para
propagar eliminaciones). El cliente guarda su propio
`ultima_sincronizacion` por entidad y lo usa como cursor.

**IDs temporales:** una tarea creada offline necesita un ID local negativo o
UUID hasta que el servidor confirme y devuelva el ID real; el cliente debe
reescribir las referencias (ej. `id_materia` de una tarea creada offline que
referencia una materia también creada offline) al drenar la cola.

---

## 5. Estrategia de conflictos — alcance real

**Resuelto:** last-write-wins comparando `fecha_actualizacion` del cliente
contra la del servidor al drenar la cola. Si el servidor tiene una versión más
reciente que la que el cliente editó offline, se descarta el cambio local y se
notifica al usuario (no se sobrescribe en silencio).

**No resuelto por este diseño (documentarlo como límite conocido, no
bloqueante):**
- Edición concurrente del mismo campo en dos dispositivos mientras ambos
  estaban offline — se resuelve por fecha, no por campo, así que un cambio
  más antiguo en un campo puede perderse aunque el más reciente solo tocara
  otro campo.
- Conflictos de horario (`detectConflicts` del backend) calculados **después**
  de sincronizar, nunca en el momento de creación offline — un usuario puede
  crear dos clases superpuestas sin conexión y descubrir el conflicto solo al
  reconectar.

---

## 6. Impacto en el backend

- Migraciones de la sección 2.1 (4 columnas `fecha_actualizacion`).
- Endpoint nuevo `GET /api/sync` por entidad o uno agregado con `since` global.
- Revisar `authMiddleware` para que el endpoint de sync siga exigiendo JWT
  válido — la sincronización no es una excepción de seguridad.
- Sin cambios al modelo de borrado lógico existente (`activo`), solo se le
  agrega fecha donde falte.

---

## 7. Matriz de riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Migración de las 4 columnas falla en producción con datos ya existentes | Baja | Alta | `ADD COLUMN ... DEFAULT CURRENT_TIMESTAMP` no requiere backfill manual; probar en staging con copia de datos reales primero |
| Cola de operaciones crece sin drenarse (usuario offline por días) | Media | Media | Límite de reintentos + UI que muestre "N cambios pendientes" (ya es criterio de aceptación de MJ-11) |
| IDs temporales mal reescritos al confirmar con el servidor | Media | Alta | Tests de integración específicos para el caso "materia + tarea creadas ambas offline en la misma sesión" |
| Sesión expira mientras el dispositivo estuvo offline mucho tiempo | Media | Alta | Requiere que el refresh token (30 días, `backend/src/services/tokenService.js:11-12`) siga siendo válido; si no, el usuario debe reautenticar al reconectar — documentar como comportamiento esperado, no bug |

---

## 8. Veredicto

Las tres etapas del documento de investigación (consulta → registro →
sincronización) son correctas como secuencia, **pero no pueden empezar sin
resolver primero** las dos precondiciones de la sección 2 (columnas de fecha +
restauración de sesión). Sin ellas, cualquier trabajo de UI o cola de
sincronización se construiría sobre una base que no puede cerrar su propio
criterio de aceptación.

**Condición de salida de cada etapa:**
1. **Consulta sin conexión** — sale cuando materias, tareas, eventos, notas y
   progreso se leen desde `sqflite` sin depender de la red, con los datos
   poblados por la primera sincronización exitosa.
2. **Registro sin conexión** — sale cuando crear/editar tareas, eventos,
   notas y completar sesiones Pomodoro funciona offline y queda en la cola.
3. **Sincronización** — sale cuando la cola se vacía automáticamente al
   reconectar, sin duplicar registros, con conflictos resueltos por fecha y
   un indicador visible de "cambios pendientes".

### ¿Modo offline antes o después de Play Store?

**Recomendación: después.** Argumento a favor de publicar primero (v1.1.0 o
v1.2.0 en Play Store, offline como v2.0.0 posterior):
- Los Sprints 1–3 (MJ-01 a MJ-10) ya corrigen defectos correctivos reales
  (estadísticas, racha) y mejoran usabilidad medible en el postest — tienen
  valor de publicación propio y no dependen del modo offline.
- El modo offline es la pieza de mayor esfuerzo (L) y mayor riesgo (migración
  de datos en producción, cola de sincronización) — bloquear el lanzamiento
  completo a que esto esté perfecto retrasa la recolección de evidencia del
  postest, que es el objetivo de investigación en curso.
- Publicar antes permite usar el postest real (con usuarios en producción)
  para validar si el offline es efectivamente la prioridad que el documento
  anticipa, o si otro hallazgo del postest pesa más.

Argumento a favor de offline primero: la justificación del propio documento
(sección 3) señala la conectividad intermitente como una condición frecuente
del contexto regional — si una parte relevante de los estudiantes participantes
del postest tiene conectividad limitada, medir su experiencia *sin* el modo
offline podría subestimar la utilidad real de la app. Esto es una decisión de
diseño de investigación, no solo técnica — **se recomienda confirmarlo con los
docentes directores de la propuesta antes de fijar el orden definitivo**, dado
que afecta directamente la validez de la medición del OE2.
