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
`RESET_TOKEN_EXPIRE_MINUTES`, `SMTP_*`.

- [ ] Confirmar que las variables de producción están configuradas en Vercel
      (Project Settings → Environment Variables), no solo en el `.env` local.
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
- [ ] Adoptar una herramienta de migraciones versionadas (ej. `db-migrate` o
      Knex) para que los próximos cambios de esquema no vuelvan a quedar solo
      en la base de producción sin registro. Hoy los cambios de esquema se
      documentan a mano en `docs/DB/base-de-datos.md` (gitignored, contiene
      datos reales de estudiantes — no subir nunca ese archivo).

## 3. Backend

- [ ] Restringir `cors({ origin: '*' })` en `backend/src/app.js` al dominio
      real de producción antes del lanzamiento (hallazgo Medio de la
      auditoría — hoy cualquier sitio puede llamar a la API).
- [ ] Agregar `helmet()` y un rate limiter global (más allá del que ya se
      agregó específicamente a `/auth/*`) — hallazgo Medio de la auditoría.
- [ ] Revisar los hallazgos Medio/Bajo restantes de la auditoría de
      seguridad (JWT sin revocación, `express-validator` instalado pero sin
      conectar a las rutas, dependencias desactualizadas) — quedaron fuera
      de esta ronda porque solo se atendieron los High.

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
- [ ] Completar el formulario de seguridad de datos ("Data safety") de Play
      Console con la misma información.
- [ ] Cuestionario de clasificación de contenido.
- [ ] Capturas de pantalla, ícono, descripción corta/larga de la ficha de
      Play Store.

## 6. CI/CD

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
