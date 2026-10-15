# Plan de implementación — Sprint 3 (Calendario, ayuda y temas)

## Problema y alcance

Este sprint cierra los hallazgos perfectivos restantes de
`docs/mvp/UNIPLAN_EVOLUCION.md` antes de abordar el modo offline: MJ-04
(reordenar Calendario, con alcance reducido), MJ-09 (sección de ayuda
funcional + reporte de problemas) y MJ-10 (temas de apariencia / modo
oscuro). Las tres mejoras llevan a la versión **v1.3.0**.

## Estado actual validado (código vs plan)

### Ya existente y reutilizable

- Calendario y Horario ya conviven en una sola pantalla con un selector
  (`mobile/lib/screens/calendar/calendar_screen.dart`); el FAB ya tiene
  comportamiento contextual según la pestaña activa.
- El ítem "Ayuda" de Perfil ya existe como entrada de menú, aunque hoy es un
  stub (`profile_screen.dart:445-450`, `SnackBar('Próximamente')`).
- El ítem "Temas" de Perfil ya existe como entrada de menú, también como
  stub idéntico (`profile_screen.dart:416-421`).
- Android ya tiene `res/values-night/` — falta verificar que sea consistente
  con el nuevo `darkTheme`, no construirlo desde cero.

### Brechas detectadas para cerrar Sprint 3

- `calendar_screen.dart:43` inicializa
  `int _viewIndex = 0; // 0 = Eventos, 1 = Horario` — la pantalla abre
  siempre en Eventos. El toggle visual es un
  `SegmentedPillControl(labels: ['Eventos', 'Horario'])` (`:229-232`).
- No existe ninguna FAQ ni flujo de reporte de problemas; el stub de Ayuda no
  tiene contenido detrás.
- No existe ninguna base de theming dinámico: sin `darkTheme`, sin
  `ThemeMode`, sin provider, sin preferencia persistida
  (`mobile/lib/config/theme.dart:42-44` define solo `AppTheme.lightTheme`;
  grep de `ThemeMode|darkTheme|ThemeProvider` en `lib/` → cero resultados).
  Los widgets leen colores como constantes estáticas
  (`AppTheme.primaryColor`, etc. — ej. `bottom_nav_bar.dart:21,26,27`) en vez
  de `Theme.of(context)`.

## Decisiones de diseño

- **MJ-04 queda reducido a un cambio de orden por defecto**, a pedido
  explícito del usuario del proyecto. No se separan los modelos `Schedule` y
  `CalendarEvent`: la superposición conceptual de `CalendarEvent.tipo: 'clase'`
  con los bloques recurrentes de `Schedule` queda explícitamente fuera de
  alcance de esta mejora y de este sprint. Solo se invierte el valor inicial
  de `_viewIndex` y, si corresponde visualmente, el orden de las etiquetas
  del `SegmentedPillControl`.
- **MJ-10 se reclasifica de esfuerzo M a L** porque no hay ninguna base de
  theming sobre la que construir: agregar un `darkTheme` sin migrar los
  widgets que leen `AppTheme.*` como constantes estáticas no se propagaría a
  la UI. Es un refactor transversal que toca cada widget themed, no solo una
  pantalla nueva de preferencias.
- **MJ-09 introduce la primera tabla y endpoint nuevos de este ciclo**
  (`reportes` / `/api/reports`), y reutiliza el onboarding del Sprint 2
  (MJ-07) como contenido accesible desde Ayuda — cerrando la dependencia que
  quedó documentada como pendiente en `docs/sprints/sprint-02.md`.

## Estrategia de ramas (Git)

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-3-calendario-ayuda-temas
```

Sin PR por ahora — el usuario prueba la rama localmente antes de decidir el
paso siguiente.

## Plan técnico por fases

### Fase 1 — MJ-04: orden del Calendario (alcance reducido)

- Mobile: en `mobile/lib/screens/calendar/calendar_screen.dart:43`, cambiar
  `_viewIndex = 0` a `_viewIndex = 1` para que la pantalla abra en Horario.
- Mobile: si corresponde visualmente, invertir el orden de las etiquetas del
  `SegmentedPillControl` en `:229-232` para que "Horario" aparezca primero.
- Sin cambios en formularios, modelos ni endpoints. No se toca
  `CalendarEvent.tipo` ni `Schedule`.

### Fase 2 — MJ-09: ayuda funcional y reporte de problemas

- Mobile: reemplazar el stub de `profile_screen.dart:445-450` por una
  pantalla de ayuda nueva con FAQ por módulo principal y guía rápida.
- Mobile: agregar el flujo "Reportar un problema o sugerencia" dentro de esa
  pantalla, con selección de módulo de origen y envío a `POST /api/reports`.
- Mobile: enlazar el onboarding del Sprint 2 (MJ-07) desde esta pantalla de
  ayuda, para que sea accesible de nuevo fuera de la primera apertura.
- Backend: nueva tabla `reportes`:

```sql
CREATE TABLE IF NOT EXISTS reportes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT NOT NULL,
  modulo VARCHAR(50) NOT NULL,
  mensaje TEXT NOT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_estudiante (id_estudiante),
  CONSTRAINT reportes_ibfk_1 FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

- Backend: nuevo modelo `Report.js`, controlador y ruta `POST /api/reports`
  (más un `GET` si se necesita listar para soporte interno), siguiendo el
  mismo patrón de los modelos existentes (`Task.js`, `Pomodoro.js`).

### Fase 3 — MJ-10: temas de apariencia (modo oscuro)

- Mobile: crear `ThemeProvider` (`ChangeNotifier`, preferencia persistida en
  `SharedPreferences`), con modo claro/oscuro/según sistema.
- Mobile: completar `darkTheme` en `AppTheme` (`mobile/lib/config/theme.dart`,
  hoy solo define `lightTheme` en `:42-44`).
- Mobile: migrar los widgets que leen `AppTheme.*` como constantes
  estáticas a `Theme.of(context)`, empezando por
  `bottom_nav_bar.dart:21,26,27` y auditando pantalla por pantalla el resto
  de la app.
- Mobile: reemplazar el stub de `profile_screen.dart:416-421` por el
  selector real de tema.
- Mobile/Android: revisar que `res/values-night/` sea consistente con el
  `darkTheme` nuevo.

## Verificación

```
cd mobile && flutter analyze
cd mobile && flutter test
cd backend && npm test
```

Regresión manual (sin CP numerado en `UNIPLAN_EVOLUCION.md` para estos
ítems — verificar directamente contra los criterios de aceptación):

- [ ] Al entrar a Calendario, la vista inicial es Horario.
- [ ] El usuario puede cambiar a Eventos con un toque, igual que antes.
- [ ] El FAB conserva su comportamiento contextual según la pestaña activa.
- [ ] Existe al menos una FAQ por módulo principal.
- [ ] Los reportes enviados quedan registrados con fecha y módulo.
- [ ] El onboarding es accesible de nuevo desde Ayuda.
- [ ] El cambio de tema se aplica de inmediato en todas las pantallas, no
  solo las migradas parcialmente.
- [ ] La preferencia de tema se conserva al cerrar y abrir la aplicación.
- [ ] Ningún texto queda ilegible en modo oscuro (auditoría manual pantalla
  por pantalla).
