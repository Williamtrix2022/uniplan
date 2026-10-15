# Plan de implementación — Sprint 4 (Funcionamiento sin conexión)

## Problema y alcance

Este sprint implementa MJ-11, la única mejora de `docs/mvp/UNIPLAN_EVOLUCION.md`
pendiente para el ciclo mayor **v2.0.0**: que el estudiante pueda consultar y
registrar materias, tareas, eventos, notas y sesiones Pomodoro sin conexión,
con sincronización al recuperarla. El detalle completo de bloqueantes y la
elección del motor local vive en `docs/OFFLINE_FIRST.md`; este documento solo
ordena el trabajo en fases y dependencias, siguiendo las 3 etapas del
documento de investigación (consulta sin conexión → registro sin conexión →
sincronización, sección 7.3).

## Estado actual validado (código vs plan)

### Ya existente y reutilizable

- Cuatro tablas ya tienen columna de última modificación y pueden servir de
  referencia de patrón para la migración de la Fase 0: `horarios`, `notas`,
  `calificaciones` y `preferencias_notificacion`.
- `AuthService.loadToken()`/`isAuthenticated()`
  (`mobile/lib/services/auth_service.dart:364-371,289-292`) ya existen — la
  restauración de sesión depende de conectarlos, no de construirlos.

### Brechas detectadas para cerrar Sprint 4

- El criterio "resolución de conflictos por fecha de última modificación" no
  es implementable hoy: `tareas`, `materias`, `eventos_calendario` y
  `notificaciones` solo tienen `fecha_creacion`
  (`backend/db/schema.sql:59,80,143,253`) — ninguna columna de última
  modificación.
- Sin conexión, el usuario no puede ni entrar: `SplashScreen`
  (`mobile/lib/screens/splash_screen.dart:55-65`) siempre va a
  `LoginScreen` sin condición (mismo defecto raíz que MJ-06 del Sprint 2).
- No hay `connectivity_plus` ni motor local (`sqflite`/`hive`/`drift`
  ausentes del `pubspec.yaml`); solo blobs JSON en `SharedPreferences` por
  provider, que se sobrescriben con la red en cada carga.

## Decisiones de diseño

Este sprint no puede empezar el trabajo de offline propiamente dicho sin
cerrar dos bloqueantes duros primero:

1. **Migración de `fecha_actualizacion`** en `tareas`, `materias`,
   `eventos_calendario` y `notificaciones`. Sin esta columna, el criterio de
   aceptación "resolución de conflictos por fecha de última modificación" no
   tiene sobre qué comparar — es un prerrequisito de datos, no de UI.
2. **Restauración de sesión en frío.** Si el Sprint 2 (MJ-06) no se cerró
   antes de este sprint, `SplashScreen` sigue enviando a todo el mundo a
   Login incondicionalmente, y un usuario sin conexión no puede ni llegar a
   la app para usar el modo offline. Se verifica el estado de esa corrección
   al abrir este sprint; si no está, se completa aquí antes de la Fase 1.

La elección del motor local (sqflite/hive/drift) y el detalle de los demás
bloqueantes **no se deciden en este documento** — ver
`docs/OFFLINE_FIRST.md` para el detalle completo de bloqueantes y elección de
motor local.

## Estrategia de ramas (Git)

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-4-offline
```

Sin PR por ahora — el usuario prueba la rama localmente antes de decidir el
paso siguiente.

## Plan técnico por fases

### Fase 0 — Bloqueantes (prerrequisito, no opcional)

- Backend: migración agregando `fecha_actualizacion` a las 4 tablas que no
  la tienen:

```sql
ALTER TABLE tareas
  ADD COLUMN fecha_actualizacion TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE materias
  ADD COLUMN fecha_actualizacion TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE eventos_calendario
  ADD COLUMN fecha_actualizacion TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE notificaciones
  ADD COLUMN fecha_actualizacion TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
```

- Mobile: verificar si la restauración de sesión en frío de MJ-06
  (Sprint 2) está completa; si no, conectar `SplashScreen` a
  `loadToken()`/`isAuthenticated()` aquí antes de continuar.

### Fase 1 — Consulta sin conexión

- Mobile: incorporar el motor local y la detección de conectividad que
  defina `docs/OFFLINE_FIRST.md`.
- Mobile: lectura con caché local para materias, tareas, eventos, notas y
  progreso, de forma que la app sea consultable sin red.

### Fase 2 — Registro sin conexión

- Mobile: cola de operaciones para crear y editar tareas, eventos y notas, y
  para completar sesiones Pomodoro mientras no hay conexión.
- Mobile: indicador visible de cambios pendientes por sincronizar.

### Fase 3 — Sincronización

- Backend: endpoint de sincronización incremental que resuelva conflictos
  usando la `fecha_actualizacion` agregada en la Fase 0, sin duplicar
  registros.
- Mobile: disparar la sincronización al recuperar la conexión y limpiar la
  cola de operaciones conforme se confirman.

## Verificación

```
cd mobile && flutter analyze
cd mobile && flutter test
cd backend && npm test
```

Regresión manual (sin CP numerado en `UNIPLAN_EVOLUCION.md` para MJ-11 —
verificar directamente contra los criterios de aceptación):

- [ ] Las 4 tablas (`tareas`, `materias`, `eventos_calendario`,
  `notificaciones`) tienen `fecha_actualizacion` y se actualiza en cada
  `UPDATE`.
- [ ] Un usuario con sesión válida llega a la app sin conexión (no se queda
  atascado en Login).
- [ ] Sin conexión, el estudiante puede consultar materias, tareas, eventos,
  notas y progreso.
- [ ] Sin conexión, puede crear y editar tareas, eventos y notas, y
  completar sesiones Pomodoro.
- [ ] Al recuperar la conexión, los cambios se sincronizan sin duplicar
  registros.
- [ ] La aplicación indica si existen cambios pendientes por sincronizar.
