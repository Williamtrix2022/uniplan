# Checklist de producción — Uniplan

Este documento es una lista de verificación, no un script automático. Los pasos
que requieren credenciales o cuentas personales (dominio, Play Console, claves
de firma) los tiene que ejecutar Jhon directamente — acá se deja documentado
qué falta y en qué orden tiene sentido hacerlo.

## 1. Variables de entorno

El backend (`backend/src/config/database.js` y el resto de `backend/src`) ya
lee todo desde variables de entorno, sin valores hardcodeados — pasar de local
a producción es solo cuestión de `.env` correcto en cada ambiente. Nunca se
suben al repo (`.gitignore` ya lo cubre).

Variables usadas hoy (ver `backend/.env.example` para la lista completa):
`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`, `JWT_SECRET`,
`JWT_EXPIRE`, `BCRYPT_ROUNDS`, `RESET_PASSWORD_URL`,
`RESET_TOKEN_EXPIRE_MINUTES`, `SMTP_*`, `CORS_ORIGINS`.

- [ ] Confirmar que las variables de producción están configuradas en Vercel
      (Project Settings → Environment Variables), no solo en el `.env` local.
- [ ] Setear `CORS_ORIGINS` en Vercel con el/los dominio(s) reales separados
      por coma (ej. `https://uniplan.app,https://www.uniplan.app`). Si queda
      sin setear, la API acepta cualquier origen y lo avisa en el log.
- [x] Rotar la credencial SMTP de MailerSend filtrada en el historial de git
      (hallazgo Crítico de la auditoría — ya la rotaste).
- [ ] `JWT_SECRET` en producción: confirmar que es un valor largo y aleatorio,
      distinto al usado en desarrollo.

## 2. Base de datos

- [x] Esquema versionado en `backend/db/schema.sql` (antes no existía ningún
      `.sql` en el repo — `*.sql` estaba en `.gitignore` sin excepción).
- [x] `docker-compose.yml` para levantar MySQL local con el esquema aplicado
      (`docker compose up -d`), verificado de punta a punta.
- [ ] Decidir si producción sigue en AlwaysData o se migra a otro proveedor
      (Railway, PlanetScale, RDS, etc.) — el código no depende de Alwaysday
      específicamente, es MySQL estándar vía `mysql2`.
- [ ] Si se migra: exportar los datos reales (no solo el esquema) desde
      AlwaysData e importarlos al nuevo proveedor.
- [x] Migraciones versionadas con `db-migrate` (`backend/migrations/`, ver
      `backend/migrations/README.md`). El baseline `20260901000000-initial-schema`
      usa `CREATE TABLE IF NOT EXISTS`, así que la primera corrida sobre la
      base de producción actual es un no-op que solo registra el baseline.
- [ ] Correr `npm run migrate` una vez sobre la base de producción para
      registrar el baseline (pendiente de hacerlo con las credenciales
      reales — desde acá solo se verificó la estructura, no contra la DB).

## 3. Backend

- [x] CORS configurable por `CORS_ORIGINS` en `backend/src/app.js` (allowlist
      por env; `*` solo si no está seteada, con advertencia en el log). Falta
      setear la variable en Vercel — ver sección 1.
- [x] `helmet()` y un rate limiter global (`apiLimiter`, 300 req/15min por IP)
      además del límite específico de `/auth/*`.
- [x] Las respuestas 5xx ya no filtran `error.message` ni el stack al cliente
      fuera de `development` (middleware `sanitizeErrorResponse` + error handler
      global endurecido).
- [x] JWT con revocación / refresh tokens. Access token corto
      (`JWT_ACCESS_EXPIRE`, default 15m) + refresh token largo
      (`JWT_REFRESH_EXPIRE_DAYS`, default 30) guardado hasheado en
      `refresh_tokens`. Endpoints `POST /api/auth/refresh` (rotación +
      detección de reuso), `/logout` y `/logout-all`. El cliente guarda el
      refresh cifrado y reintenta los 401 una vez (single-flight).
- [ ] Setear `JWT_ACCESS_EXPIRE` y `JWT_REFRESH_EXPIRE_DAYS` en Vercel
      (si no se setean, aplican los defaults 15m / 30d). `JWT_EXPIRE` quedó
      obsoleto.
- [ ] Al liberar a `main`: la app vieja (sin lógica de refresh) sigue
      funcionando con su access token actual hasta que venza; después el
      usuario vuelve a iniciar sesión. Los builds nuevos hacen refresh solos.
- [x] `express-validator` conectado a las 11 rutas como guardia de entrada
      (`backend/src/validators/*` + `middlewares/validate.js`). Valida tipos,
      largos, enums y `:id` antes de llegar al controlador; responde 400 con
      `{ success:false, message, errors[] }`. Los chequeos inline previos de
      los controladores se dejaron como segunda línea.
- [ ] `usesCleartextTraffic` ya salió del manifest de release (queda solo en
      `debug`/`profile`); cuando exista dominio propio, confirmar que la app
      apunta siempre a HTTPS.

## 4. Dominio

- [ ] Comprar el dominio.
- [ ] Apuntar el DNS al proyecto de Vercel (o al hosting que se elija para el
      backend).
- [ ] Actualizar `RESET_PASSWORD_URL` (backend) y la URL base de la API en
      `mobile/lib/config/api_config.dart` para que apunten al dominio nuevo.
- [ ] Certificado TLS — Vercel lo gestiona automáticamente si el dominio se
      conecta ahí.

## 5. Play Store

- [ ] Cuenta de Google Play Console (cuesta una vez, la paga Jhon).
- [ ] Revisar `applicationId` en `mobile/android/app/build.gradle` — debe ser
      único y definitivo, no se puede cambiar después de publicar.
- [ ] Generar el keystore de firma de release y guardarlo fuera del repo
      (nunca versionado) — el CI actual (`ci-tests.yml` /
      `firebase-distribution.yml`) no firma para Play Store todavía, solo
      para Firebase App Distribution.
- [ ] Escribir la política de privacidad (obligatoria para publicar) — puede
      alojarse como una página estática en el dominio nuevo. Debe reflejar
      qué datos se recolectan: nombre, correo, carrera, universidad,
      contraseña (hasheada), y el uso de notificaciones locales.
- [x] El token de sesión y los datos de usuario se guardan cifrados en el
      dispositivo (`flutter_secure_storage`: Keychain en iOS,
      EncryptedSharedPreferences en Android), no en `SharedPreferences` en
      texto plano. Hay migración automática para sesiones ya existentes.
- [ ] Completar el formulario de seguridad de datos ("Data safety") de Play
      Console con la misma información.
- [ ] Cuestionario de clasificación de contenido.
- [ ] Capturas de pantalla, ícono, descripción corta/larga de la ficha de
      Play Store.

## 6. Login con Google

Implementado 2026-09-05/06: login/registro con Google verificando el ID token
en el backend (`google-auth-library`), con vinculación automática a cuentas
existentes cuando el correo llega verificado por Google (`payload.email_verified`).
El botón de Google en login solo inicia sesión (rechaza si el correo no existe
todavía); el de registro sí crea la cuenta.

- [ ] `GOOGLE_CLIENT_ID` (el Web Client ID de Google Cloud Console, no el
      Android) seteado en Vercel → Environment Variables → Production, **y
      Redeploy hecho después** — Vercel no aplica variables nuevas a un
      deployment que ya existe.
- [x] Migración `20260905000000-add-google-auth` aplicada (columna
      `google_id` + `contrasena` nullable en `estudiantes`) — verificado en
      local y en AlwaysData.
- [ ] La pantalla de consentimiento OAuth sigue en estado **Testing** en
      Google Cloud Console: solo pueden loguearse con Google las cuentas
      agregadas a mano en "Test users" (máx. 100). Agregar ahí el Gmail de
      cada persona que reciba el build por Firebase App Distribution, o el
      login con Google le va a fallar sin un error claro en pantalla.
- [x] Los builds de distribución no se generan con
      `--dart-define=API_URL=http://<ip-local>...` — el default de
      `mobile/lib/config/api_config.dart` ya apunta a la URL de Vercel.
- [x] `google_sign_in` fuerza `signOut()` antes de `signIn()`
      (`auth_service.dart`) para que siempre muestre el selector de cuentas
      en vez de reautenticar en silencio con la última usada.

### Hallazgo: los builds "release" están firmados con la clave de debug

`mobile/android/app/build.gradle.kts`:
```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```
No rompe nada mientras la distribución sea por Firebase App Distribution — el
SHA-1 de debug ya está registrado en Google Cloud Console y cubre estos
builds también. **Hay que resolverlo antes de subir a Play Store** (ver
sección 5, "Generar el keystore de firma de release"): Play Store espera una
clave de firma propia, no la de debug.

Pasos para cuando se llegue a ese punto (no ejecutar todavía):

1. Generar el keystore real:
   `keytool -genkey -v -keystore <ruta>/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
   Guardar la ruta y las contraseñas en un gestor de contraseñas — nunca en
   el repo (ya protegido en `.gitignore`: `/android/key.properties`, `*.jks`,
   `*.keystore`).
2. Crear `mobile/android/key.properties` con `storePassword`, `keyPassword`,
   `keyAlias=upload`, `storeFile=<ruta al keystore>`.
3. En `build.gradle.kts`: leer `key.properties`, declarar
   `signingConfigs { create("release") { ... } }` con esos valores, y
   cambiar la línea de `release { signingConfig = ... }` para usar
   `signingConfigs.getByName("release")` en vez de `"debug"`.
4. Sacar el SHA-1 del keystore nuevo:
   `keytool -list -v -keystore <ruta>/upload-keystore.jks -alias upload -storepass <password>`.
5. En Google Cloud Console → Credentials, crear otro cliente OAuth tipo
   Android (mismo package `com.uniplan.app`, SHA-1 nuevo) — se suma al de
   debug, no lo reemplaza.
6. Si se activa **Play App Signing** en Play Console: Google vuelve a
   re-firmar el APK con su propia clave para distribuirlo. Sacar el SHA-1
   que Play Console muestra en "Integridad de la app" → "Certificado de
   firma de la app" y agregarlo también como cliente Android — sin este
   paso, el login con Google falla solo para quienes instalan desde Play
   Store, aunque funcione en cualquier otro build.

## 7. CI/CD

- [x] `ci-tests.yml`: corre `flutter analyze` + `flutter test` + `npm test`
      en cada Pull Request a `main` y `dev`.
- [x] `firebase-distribution.yml`: ahora corre analyze + test también antes
      de buildear el APK de distribución (antes no corría ningún test).
- [ ] **Pendiente de un administrador del repo**: activar "Require status
      checks to pass" en Settings → Branches para `main` (y opcionalmente
      `dev`), seleccionando los jobs de `ci-tests.yml` como obligatorios.
      Sin este paso, los tests corren y se ven en el PR, pero no bloquean el
      merge si fallan — eso es una configuración de GitHub, no del código,
      así que no se puede hacer desde acá sin permisos de administración del
      repositorio.
