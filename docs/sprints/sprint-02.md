# Plan de implementación — Sprint 2 (Gestión de Tareas)

## Problema y alcance
Construir y cerrar **Sprint 2** del módulo de tareas usando `UNIPLAN_MVP.md` como fuente de verdad, sin mezclar pendientes de Sprint 1 (por decisión de alcance). El objetivo es llevar Sprint 2 de su estado actual a una entrega lista para PR con funcionalidades completas de filtros, búsqueda, ordenamiento, selector de materia, animaciones y capa de estado/caché local.

## Estado actual validado (código vs MVP)
### Ya implementado (real)
- Backend Task CRUD: crear, listar, actualizar, eliminar, próximas, stats.
- Backend soporta filtro por `estado`, `prioridad` y `id_materia` vía query en `GET /api/tasks`.
- Mobile: pantalla base de lista, formulario crear/editar, swipe para eliminar, prioridad visual, checkbox de completar, refresco.
- Modelo `Task` con serialización/deserialización y soporte de materia (`id_materia`, `materia_nombre`).

### Brechas detectadas para cerrar Sprint 2
- Filtros UI en lista (hay botón con `TODO` pero sin implementación).
- Búsqueda de tareas.
- Ordenamiento explícito configurable desde UI.
- Selector de materia en formulario de tarea.
- `TaskFilter` widget reutilizable (no existe).
- Animaciones del módulo (transición de estado, completar, lista animada, skeleton loading).
- `TaskProvider` (state management reactivo), caché local y estadísticas en capa de estado.
- Ajuste funcional: endpoint/servicio actual de “completar” marca solo `TRUE`; falta comportamiento real de **toggle** (completar/desmarcar) para alineación completa al MVP.

## Decisión sobre planes previos
- **No borrar** `plan.md` del repositorio (Sprint 1), se mantiene como histórico.
- Este plan de Sprint 2 vive en el archivo de sesión (`.copilot/session-state/.../plan.md`) para planificación activa.

## Estrategia de ramas (Git)
### Rama umbrella del sprint
- `feature/sprint-2-task-management-completion`

### Sub-ramas recomendadas
1. `feature/s2-task-provider-state-cache`
2. `feature/s2-task-filters-search-sort`
3. `feature/s2-task-subject-selector`
4. `feature/s2-task-animations-skeleton`
5. `feature/s2-task-toggle-complete-backend`
6. `chore/s2-mvp-sync-docs`

### Flujo de trabajo recomendado
1. `git checkout main`
2. `git pull origin main`
3. `git checkout -b feature/sprint-2-task-management-completion`
4. Crear cada sub-rama desde la rama umbrella.
5. Merge de sub-ramas hacia la umbrella con commits pequeños.
6. PR final de la umbrella a `main`.

## Plan técnico por fases
### Fase 1 — Capa de estado y caché (base del sprint)
- Crear `TaskProvider` (ChangeNotifier o patrón ya usado en app) con:
  - `tasks`, `filteredTasks`, `isLoading`, `error`.
  - carga inicial, refresh, operaciones CRUD sincronizadas.
  - filtros, búsqueda y ordenamiento centralizados.
  - cálculo de estadísticas básicas.
- Integrar provider en `main.dart` y en `TasksScreen`.
- Agregar caché local mínima para tareas (persistencia liviana) y estrategia de invalidación al mutar datos.

### Fase 2 — Filtros, búsqueda y ordenamiento
- Implementar `TaskFilter` widget reutilizable.
- Conectar icono de filtros en `TasksScreen` a UI real (bottom sheet o panel).
- Agregar búsqueda por título/descripción.
- Agregar ordenamiento configurable (fecha, prioridad, estado).
- Asegurar convivencia entre tabs (Hoy/Semana/Próximamente/Proyectos) y filtros globales.

### Fase 3 — Selector de materia y relación tarea↔materia
- Crear servicio/modelo mínimo para materias en mobile (si aún no existe).
- Consumir `/api/subjects` para poblar selector en `TaskFormScreen`.
- Enviar `id_materia` al crear/editar tarea.
- Mostrar materia seleccionada en formulario y reflejarla en tarjetas/listados.

### Fase 4 — Ajuste backend toggle completo/incompleto
- Extender backend para soportar toggling real:
  - opción A: nuevo endpoint `PATCH /api/tasks/:id/toggle`.
  - opción B: reutilizar `/complete` con payload de estado.
- Actualizar `TaskService.completeTask` en mobile para usar toggle real.
- Mantener compatibilidad y permisos de usuario existentes.

### Fase 5 — Animaciones y carga progresiva
- Transición visual al cambiar estado de tarea.
- Animación al completar (feedback inmediato y no intrusivo).
- Lista animada al agregar/eliminar (`AnimatedList` o alternativa consistente).
- Skeleton loading en carga inicial/refresh.

### Fase 6 — Cierre de sprint y documentación
- Revisar `UNIPLAN_MVP.md` y actualizar estados reales de Sprint 2.
- Limpiar “Próximas 5 tareas” para reflejar el siguiente cuello de botella.
- Preparar PR final con checklist de cumplimiento de objetivo Sprint 2.

## Orden y dependencias
1. Fase 1 primero (foundation de estado).
2. Fase 2 y Fase 3 pueden avanzar en paralelo tras Fase 1.
3. Fase 4 en paralelo con Fase 2/3, pero cerrada antes de QA final.
4. Fase 5 después de tener comportamiento funcional estable.
5. Fase 6 al final.

## Definition of Done — Sprint 2
- CRUD + toggle real funcionando extremo a extremo.
- Filtros, búsqueda y ordenamiento operativos en UI.
- Selector de materia integrado y persistiendo `id_materia`.
- Provider de tareas activo con estado reactivo y caché local básica.
- Animaciones clave y skeleton loading implementados.
- `UNIPLAN_MVP.md` alineado al estado real de Sprint 2.

## Riesgos y mitigación
- Riesgo: acoplar demasiada lógica al widget de pantalla.  
  Mitigación: centralizar en `TaskProvider`.
- Riesgo: inconsistencias entre cache local y backend.  
  Mitigación: invalidación explícita tras mutaciones + refresh controlado.
- Riesgo: animaciones afecten rendimiento.  
  Mitigación: animaciones ligeras, medir en listas reales y ajustar.
