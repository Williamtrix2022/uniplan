# Sprint 2 — Acceso

Branch: `feature/sprint-2-acceso` (from `dev`). Runner: `cd mobile && flutter analyze && flutter test`.

## Specs

- S1 (MJ-06): "Recordar sesión" se trata como corrección funcional, no solo visual. Se conecta `SplashScreen` a `loadToken()`/`isAuthenticated()` como parte de MJ-06; el rediseño visual del login no se considera completo sin esto.
- S2 (MJ-06): rediseño visual de `login_screen.dart` — contraste AA, jerarquía "Iniciar sesión" vs "Crear cuenta", mostrar/ocultar contraseña, indicador de carga con botón deshabilitado durante la validación.
- S3 (MJ-07): onboarding de 3-4 pantallas en la primera apertura, con flag en `SharedPreferences`; "Comenzar" lleva a "Crear cuenta". El enlace desde Ayuda queda pendiente para MJ-09 (Sprint 3), documentado, sin bloquear este sprint.
- S4 (MJ-05): dividir `register_screen.dart` (`Form` único de 4 campos) en pasos (cuenta → perfil académico), validación en línea, sin cambiar el contrato de la API de autenticación.

## Tasks

- T1 (S1): Conectar `SplashScreen._initializeApp` a `AuthService.isAuthenticated()` para decidir Home vs Login. Route: inline. Risk: item 2 (auth guard). Status: done.
- T2 (S2): Verificar rediseño visual del login. Hallazgo: contraste/jerarquía, mostrar/ocultar contraseña (`CustomTextField`) e indicador de carga con botón deshabilitado (`CustomButton`) ya estaban implementados antes de este sprint — sin brecha real que cerrar. Status: verified, no change needed.
- T3 (S3): Onboarding de 4 pantallas (`onboarding_screen.dart`) + `OnboardingService` (flag en SharedPreferences) + `SplashScreen` decide onboarding → sesión → login. "Saltar"/"Comenzar" llevan a `RegisterScreen`. Route: inline. Risk: none (pantalla nueva, no toca lógica existente salvo el enrutamiento ya cubierto por T1). Status: done.
- T4 (S4): `register_screen.dart` dividido en 2 pasos (cuenta → perfil académico) con `GlobalKey<FormState>` independiente por paso; universidad pasa de texto libre a `DropdownButtonFormField` con opción "Otra universidad" (texto libre condicional). Sin cambios en `AuthService.register` ni en el payload. Route: inline. Risk: none (mismo contrato de API, mismos validators, solo reestructuración de UI). Status: done.

## Log

- L1: Usuario pidió fusionar sprint1 a dev (hecho, push a origin/dev) y luego "empecemos" para iniciar Sprint 2 siguiendo `docs/sprints/sprint-02.md`.
- L2: Exploración de `login_screen.dart`, `custom_text_field.dart`, `custom_button.dart` mostró que los requisitos visuales de MJ-06 (contraste, jerarquía, toggle de contraseña, loading state) ya estaban cubiertos. El único defecto real de Fase 1 era la navegación incondicional en `SplashScreen`.
- L3: Usuario pidió terminar todo el sprint y reportar al final los cambios y cómo probarlos.
- L4: Verificación: `flutter analyze` completo → 60 issues, todos preexistentes (deprecaciones `withOpacity`/`value`, `avoid_print`, `prefer_const`), ninguno introducido por este sprint. `flutter test` completo → 82/82 tests pasan, incluyendo el smoke test de `MyApp()` que ejercita el nuevo `_initializeApp` de `SplashScreen` con llamadas reales a `SharedPreferences`/`flutter_secure_storage`.
