# Sprint 3 — Calendario, ayuda y temas

Branch: `feature/sprint-3-calendario-ayuda-temas`, creada desde `feature/sprint-2-acceso`
(no desde `dev`) porque el PR #53 (Sprint 2) aún no está mergeado y la Fase 2
de este sprint reutiliza el onboarding de Sprint 2. Rebasar sobre `dev` cuando
el PR #53 se mergee. Runner: `cd mobile && flutter analyze && flutter test`,
`cd backend && npm test`.

## Specs

- S1 (MJ-04): la pantalla de Calendario debe abrir en "Horario" en vez de "Eventos" (alcance reducido a pedido explícito del usuario del proyecto; no se tocan `CalendarEvent.tipo` ni `Schedule`).
- S2 (MJ-09): reemplazar el stub de Ayuda (`profile_screen.dart:445-450`) por una pantalla con FAQ por módulo principal + flujo "Reportar un problema o sugerencia" (selección de módulo, envío a `POST /api/reports`). Enlazar el onboarding de Sprint 2 desde esta pantalla.
- S3 (MJ-09, backend): tabla `reportes` nueva, modelo `Report.js`, controlador y ruta `POST /api/reports` (+ `GET` si se necesita para soporte interno), siguiendo el patrón de modelos existentes (`Task.js`, `Pomodoro.js`).
- S4 (MJ-10): `ThemeProvider` (ChangeNotifier, preferencia persistida en SharedPreferences) con modo claro/oscuro/sistema; completar `darkTheme` en `AppTheme`; migrar widgets que leen `AppTheme.*` como constantes estáticas a `Theme.of(context)`, empezando por `bottom_nav_bar.dart`; reemplazar el stub de "Temas" (`profile_screen.dart:416-421`) por el selector real; revisar `res/values-night/` en Android.

## Tasks

- T1 (S1): Cambiar `_viewIndex` inicial en `calendar_screen.dart` de 0 a 1 (abrir en Horario). Route: inline. Risk: none. Status: pending.
- T2 (S3): Backend — tabla `reportes`, modelo `Report.js`, ruta `POST /api/reports`. Route: inline. Risk: item 3 (nuevo endpoint/contrato) — aditivo, no rompe contratos existentes. Status: pending.
- T3 (S2): Mobile — pantalla de Ayuda con FAQ + reporte, enlace al onboarding. Route: inline. Risk: none. Status: pending.
- T4 (S4): `ThemeProvider` + `darkTheme` + migración de `AppTheme.*` estático a `Theme.of(context)` + selector real de tema. Route: TBD (posible writer si el alcance de migración de pantallas es grande). Risk: item 6 (cambio transversal — un error de migración podría dejar texto ilegible en modo oscuro sin que ningún test lo detecte). Status: pending.

## Log

- L1: Usuario pidió el PR de Sprint 2 a dev (creado: https://github.com/Williamtrix2022/uniplan/pull/53, aún no mergeado — su amigo lo prueba primero) y luego "empecemos con el sprint3".
