# Plan de implementación — Sprint 2 (Acceso)

## Problema y alcance

Con las correcciones de visibilidad del Sprint 1 cerradas, este sprint ataca
el módulo de Acceso completo, según `docs/mvp/UNIPLAN_EVOLUCION.md`: MJ-05
(registro de usuario más intuitivo), MJ-06 (rediseño moderno del inicio de
sesión, que incluye arreglar "recordar sesión") y MJ-07 (onboarding antes del
registro). Las tres mejoras son prioridad "Debería" para la versión
**v1.2.0**.

## Estado actual validado (código vs plan)

### Ya existente y reutilizable

- Login, registro y recuperación de contraseña ya son funcionales en la app.
- `AuthService.loadToken()` y `AuthService.isAuthenticated()`
  (`mobile/lib/services/auth_service.dart:364-371,289-292`) ya están
  implementados — solo falta invocarlos desde el flujo de arranque.
- El checkbox de aceptación de términos del registro (Sprint 1, MJ-08) ya
  bloquea el envío; este sprint no toca ese contrato.

### Brechas detectadas para cerrar Sprint 2

- El registro es un único `Form` (`mobile/lib/screens/auth/register_screen.dart:21,158`)
  con 4 campos simultáneos, sin pasos. Esto coincide con la dimensión peor
  valorada en la validación de v1.0.0: protección frente a errores (72,5 %).
- "Recordar sesión" está roto de raíz: `AuthService.loadToken()` y
  `isAuthenticated()` están definidos pero nunca se llaman.
  `SplashScreen` (`mobile/lib/screens/splash_screen.dart:55-65`) espera
  2500 ms y hace `pushReplacement` a `LoginScreen` sin condición — un usuario
  con sesión válida vuelve a ver el login cada vez que abre la app.
- No existe ningún onboarding ni flag de primera apertura. Grep de
  `onboard|welcome|bienvenid|tutorial` en `lib/` → una sola coincidencia
  textual sin relación (`login_screen.dart:256`, literal "Bienvenido de
  nuevo").

## Decisiones de diseño

- **"Recordar sesión" se trata como corrección funcional, no solo visual.**
  Se conecta `SplashScreen` a `loadToken()`/`isAuthenticated()` como parte de
  MJ-06; el rediseño visual del login no se considera completo sin esto,
  porque es la causa raíz del hallazgo H04 además de un defecto de
  comportamiento.
- **El onboarding se muestra solo en la primera apertura**, controlado por un
  flag en `SharedPreferences`, y queda accesible después desde Ayuda — ese
  punto de acceso lo construye MJ-09 en el Sprint 3; aquí solo se deja el
  enlace pendiente documentado, no se bloquea el cierre del sprint por una
  dependencia de un sprint futuro.
- **MJ-05 no cambia el contrato de la API de autenticación.** El registro
  por pasos es una reestructuración de la UI (cuenta → perfil académico) con
  validación en línea, no un cambio de payload.

## Estrategia de ramas (Git)

```
git checkout dev
git pull origin dev
git checkout -b feature/sprint-2-acceso
```

Sin PR por ahora — el usuario prueba la rama localmente antes de decidir el
paso siguiente.

## Plan técnico por fases

### Fase 1 — MJ-06: rediseño del login y restauración de sesión

- Mobile: rediseño visual de `login_screen.dart` — contraste AA, jerarquía
  "Iniciar sesión" vs "Crear cuenta", mostrar/ocultar contraseña, indicador
  de carga con botón deshabilitado durante la validación.
- Mobile: en `splash_screen.dart:55-65`, reemplazar el `pushReplacement`
  incondicional a `LoginScreen` por una decisión basada en
  `AuthService.isAuthenticated()`/`loadToken()`: sesión válida → Home,
  sesión inválida o ausente → Login.
- No se modifica `auth_service.dart` más allá de invocar lo ya existente; sin
  cambios de contrato con el backend.

### Fase 2 — MJ-07: onboarding antes del registro

- Mobile: construir secuencia de 3–4 pantallas nuevas (organiza materias y
  tareas · planifica con el calendario · estudia con Pomodoro · mide tu
  progreso), con botones "Saltar"/"Comenzar".
- Mobile: flag de primera apertura en `SharedPreferences`; la ruta inicial de
  `splash_screen.dart` decide entre onboarding (primera vez) y la lógica de
  sesión de la Fase 1 (aperturas siguientes).
- Mobile: "Comenzar" al final del onboarding lleva a "Crear cuenta"
  (`register_screen.dart`).
- El acceso posterior al onboarding desde Ayuda queda como dependencia
  explícita de MJ-09 (Sprint 3); se documenta en el PR de este sprint para no
  perderla.

### Fase 3 — MJ-05: registro por pasos

- Mobile: dividir `register_screen.dart:21,158` en pasos (cuenta → perfil
  académico) en lugar del `Form` único con 4 campos simultáneos.
- Mobile: validación en línea por campo, indicador de seguridad de
  contraseña, mensajes de error específicos antes de enviar, listas de
  selección en vez de texto libre donde aplique (p. ej. carrera/universidad).
- Sin cambios en la API de autenticación.

## Verificación

```
cd mobile && flutter analyze
cd mobile && flutter test
cd backend && npm test
```

Regresión manual:

- [ ] CP-001 (validación v1.0.0) — MJ-05.
- [ ] CP-002, CP-003, CP-004 (validación v1.0.0) — MJ-06.
- [ ] Cada campo inválido del registro muestra un mensaje específico antes de
  enviar.
- [ ] El registro completo toma menos de 90 segundos en prueba con usuarios.
- [ ] Contraste de textos y botones del login cumple WCAG 2.1 nivel AA.
- [ ] Con un token válido guardado, abrir la app no pasa por Login.
- [ ] Durante la validación del login se muestra un indicador de carga y el
  botón se deshabilita.
- [ ] El onboarding aparece solo en la primera apertura.
- [ ] El onboarding se puede omitir en cualquier momento.
- [ ] Al finalizar el onboarding, se llega a "Crear cuenta".
