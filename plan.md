# Plan de implementación — Sprint 1 (Autenticación y UI Base)

## Problema
Completar Sprint 1 desde **69% (24/35)** hasta **35/35** con foco en autenticación completa, UX base consistente y componentes reutilizables listos para escalar los siguientes sprints.

## Estado actual validado (mobile + backend)
- Implementado: login, registro, logout, splash, navegación principal base, `AuthService`/`ApiService`, backend Node.js + Express + MySQL + JWT, endpoint de actualización de estudiante (`PUT /api/students/:id`).
- Pendiente real para cerrar Sprint 1:
  1. Recuperación de contraseña (UI + endpoint + integración mobile).
  2. Actualización de perfil real en mobile (hoy está mockeada).
  3. Onboarding de primera ejecución.
  4. Componentes base faltantes (`CustomCard`, `LoadingIndicator`, `EmptyState`, `ErrorState`).
  5. Estandarización de transiciones animadas.
  6. Soporte offline base en capa `ApiService` (alcance MVP de Sprint 1).

## Decisiones cerradas
- Stack oficial para Sprint 1: **Node.js + Express + MySQL + JWT**.
- Recuperación de contraseña: **flujo con correo real** (token seguro + expiración + envío SMTP).

## Estrategia de ramas
- Rama principal de trabajo del sprint:
  - `feature/sprint-1-auth-ui-base-completion`
- Sub-ramas recomendadas:
  1. `feature/s1-password-reset-mvp`
  2. `feature/s1-profile-update-mobile`
  3. `feature/s1-onboarding-first-run`
  4. `feature/s1-shared-ui-components`
  5. `feature/s1-screen-transitions`
  6. `feature/s1-offline-foundation`
  7. `chore/s1-mvp-sync-docs`

## Flujo recomendado de git
1. `git checkout main`
2. `git pull origin main`
3. `git checkout -b feature/sprint-1-auth-ui-base-completion`
4. Implementar por bloques (sub-ramas o commits atómicos).
5. Merge final a la rama principal del sprint.
6. Actualizar `UNIPLAN_MVP.md` al cerrar cada bloque.

## Plan técnico por fases

### Fase 1 — Password Reset con correo real (backend + mobile)
**Backend**
- Crear endpoint público `POST /api/auth/forgot-password`.
- Crear endpoint público `POST /api/auth/reset-password`.
- Archivo: `backend\src\controllers\authController.js`
  - Nuevo método `forgotPassword(req, res)`:
    - Valida formato de correo.
    - Busca usuario por correo.
    - Genera token de recuperación seguro (random + hash) con expiración (ej. 15-30 min).
    - Guarda hash + expiración en BD asociado al usuario.
    - Envía correo real con enlace/código de recuperación.
    - Respuesta segura: no revelar si el correo existe.
  - Nuevo método `resetPassword(req, res)`:
    - Valida token + nueva contraseña.
    - Verifica hash y expiración.
    - Actualiza contraseña (bcrypt), invalida token y registra fecha de cambio.
- Archivo: `backend\src\routes\authRoutes.js`
  - Registrar ruta `router.post('/forgot-password', authController.forgotPassword);`
  - Registrar ruta `router.post('/reset-password', authController.resetPassword);`
- Variables de entorno nuevas en `backend\.env` / `.env.example`:
  - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`
  - `RESET_PASSWORD_URL` (deep link o URL web)
- Ajustes BD:
  - Agregar columnas/token table para recuperación (`reset_token_hash`, `reset_token_expires_at`) o tabla dedicada.

**Mobile**
- Crear pantalla `mobile\lib\screens\auth\forgot_password_screen.dart`.
- Crear pantalla `mobile\lib\screens\auth\reset_password_screen.dart` (si usarás flujo con código/token manual).
- En `mobile\lib\screens\auth\login_screen.dart`:
  - Conectar botón “¿Olvidaste tu contraseña?” a la nueva pantalla.
- En `mobile\lib\services\auth_service.dart`:
  - Agregar método `forgotPassword({required String email})` consumiendo nuevo endpoint.
  - Agregar método `resetPassword({required String token, required String newPassword})`.
- En `mobile\lib\config\api_config.dart`:
  - Agregar constante endpoint `forgotPassword`.
  - Agregar constante endpoint `resetPassword`.
- Integración de enlace de recuperación:
  - Manejar deep link/URL para abrir pantalla de nueva contraseña con token precargado.

### Fase 2 — Update Profile real en mobile
**Mobile**
- En `mobile\lib\services\auth_service.dart`:
  - Agregar método `updateProfile({required int id, required String nombre, required String carrera, required String universidad})` usando `PUT /api/students/:id`.
  - Mantener sincronización de token/sesión y refresco de perfil.
- En `mobile\lib\screens\profile\edit_profile_screen.dart`:
  - Reemplazar mock (`Future.delayed`) por llamada real al servicio.
  - Cargar `id` de perfil autenticado y enviar `PUT`.
  - Manejar errores 400/403/500 con mensajes claros.

### Fase 3 — Componentes base reutilizables
**Mobile (nuevos archivos)**
- `mobile\lib\widgets\common\custom_card.dart`
- `mobile\lib\widgets\common\loading_indicator.dart`
- `mobile\lib\widgets\common\empty_state.dart`
- `mobile\lib\widgets\common\error_state.dart`

**Integración mínima obligatoria**
- Reemplazar estados vacíos/carga ad-hoc en:
  - `screens\tasks\tasks_screen.dart`
  - `screens\calendar\calendar_screen.dart`
  - `screens\profile\profile_screen.dart`

### Fase 4 — Onboarding primera ejecución
**Mobile**
- Crear `mobile\lib\screens\auth\onboarding_screen.dart`.
- En `mobile\lib\screens\splash_screen.dart`:
  - Agregar decisión de ruta por bandera `SharedPreferences` (`has_seen_onboarding`).
  - Secuencia: `Splash -> Onboarding (primera vez) -> Login/Home`.
- Guardar bandera al finalizar onboarding.

### Fase 5 — Transiciones animadas consistentes
**Mobile**
- Crear helper de navegación/transición:
  - `mobile\lib\config\navigation_transitions.dart` (o helper equivalente).
- Reemplazar `MaterialPageRoute` directos en flujo auth principal:
  - Login -> Register / ForgotPassword / Home
  - Splash -> Login/Home/Onboarding
- Estándar mínimo: fade + slide corto para coherencia visual.

### Fase 6 — Offline foundation en ApiService (alcance sprint)
**Mobile**
- En `mobile\lib\services\api_service.dart`:
  - Estandarizar manejo explícito de `SocketException`/timeout con mensajes consistentes.
  - Agregar base para reintento simple en GET críticos (máx. 1 reintento) o cache mínima de último resultado para pantallas de resumen.
- Objetivo: cerrar tarea MVP “ApiService — Soporte offline” sin introducir arquitectura pesada.

### Fase 7 — Cierre de sprint y documentación
- Actualizar `UNIPLAN_MVP.md` (Sprint 1 a 35/35 si se completa todo).
- Verificar sección “Próximas 5 tareas” alineada al siguiente cuello de botella (Sprint 2/3).
- Dejar lista rama `feature/sprint-1-auth-ui-base-completion` para PR.

## Dependencias y orden
1. Password reset (Fase 1) y Update profile (Fase 2) primero.
2. Componentes base (Fase 3) antes de pulido de transiciones (Fase 5).
3. Onboarding (Fase 4) puede ir en paralelo con Fase 3.
4. Offline foundation (Fase 6) al final del sprint para estabilización.
5. Documentación y sync MVP (Fase 7) al cierre.

## Definition of Done — Sprint 1
- Login, registro, logout, recuperación y edición de perfil funcionando extremo a extremo.
- Onboarding funcional de primera ejecución.
- Componentes base reutilizables integrados en pantallas clave.
- Transiciones consistentes en flujo principal.
- `UNIPLAN_MVP.md` actualizado a estado real y sin desalineaciones.
