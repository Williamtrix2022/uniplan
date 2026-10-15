# Guía de publicación en Google Play Store

> A ejecutar **después** de cerrar los sprints de `docs/mvp/UNIPLAN_EVOLUCION.md`
> (Sprints 1–4) y de decidir, con `docs/OFFLINE_FIRST.md`, si el modo offline
> va antes o después del primer lanzamiento. Este documento no duplica
> `docs/PRODUCCION.md` — lo referencia y corrige lo que quedó desactualizado
> ahí.

Evidencia verificada en código al 2026-10-15.

## ⚠️ Corrección sobre `docs/PRODUCCION.md`

Ese documento (sección "Hallazgo: los builds release están firmados con la
clave de debug", líneas 140-153) describe un `build.gradle.kts` que **ya no
refleja el código actual**. Verificado:

- `mobile/android/app/build.gradle.kts:15-21,52-61` crea un `signingConfig` de
  release **si existe `key.properties`** — y ese archivo **sí existe** en esta
  máquina (confirmado, sin leer su contenido). El fallback a la clave de debug
  (`:73-77`) solo se activa si `key.properties` falta.
- `release-please.yml:84-99` ya decodifica `ANDROID_KEYSTORE_BASE64` desde
  secrets y genera `key.properties` en CI, con fail-hard si el secret no está
  seteado.

La firma de release **no es el hueco real para Play Store**. Los huecos reales
son los de este documento: no se genera AAB, falta ícono adaptativo, falta
política de privacidad, y el `versionCode` de CI no coincide con el de
`pubspec.yaml`.

---

## 1. Prerrequisitos de código

- [ ] **Generar AAB, no solo APK.** Ningún workflow de
  `.github/workflows/` construye un Android App Bundle — `release-please.yml:110`
  y `firebase-distribution.yml:94` corren `flutter build apk --release`. Play
  Store exige `.aab` para publicaciones nuevas. Agregar un job (o modificar uno
  existente) con `flutter build appbundle --release`.
- [ ] **Resolver la discrepancia de `versionCode`.** `pubspec.yaml:4` dice
  `1.0.5+6` (versionCode 6), pero CI pasa
  `--build-number=${{ github.run_number }}` (`release-please.yml:110-112`) — el
  AAB que suba a Play tendría el run number de GitHub Actions como versionCode,
  no el `+6` del pubspec. Play solo acepta versionCode estrictamente
  creciente; decidir una sola fuente de verdad antes del primer upload (lo más
  simple: dejar que CI siga mandando, y que `release-please` sincronice el
  pubspec con el mismo número tras cada release).
- [ ] **Ícono adaptativo.** `flutter_launcher_icons` está configurado
  (`pubspec.yaml:57-60`) pero sin `adaptive_icon_background`/
  `adaptive_icon_foreground`, y no existe `mipmap-anydpi-v26/` en
  `android/app/src/main/res/`. Play Store acepta iconos no adaptativos, pero
  se ven peor en Android 8+; agregar las dos claves y regenerar.
- [ ] **`android:label` en minúscula.** `AndroidManifest.xml:26` tiene
  `android:label="uniplan"` — revisar si se quiere "UniPlan" o el nombre
  definitivo de marca antes de publicar (no se puede cambiar después de que
  usuarios instalen con el label viejo visible en sus listas de apps sin que
  se vea como una app "nueva" hasta que actualicen).
- [ ] **`applicationId` definitivo.** `com.uniplan.app`
  (`build.gradle.kts:41`) — confirmar que es el final, no se puede cambiar
  después de publicar.
- [ ] **`minSdk`/`targetSdk`/`compileSdk` delegados al Flutter Gradle Plugin**
  (`build.gradle.kts:25,46,47`), sin número fijo. Play exige un `targetSdk`
  mínimo vigente (revisar el requisito actual de Play Console al momento de
  subir — cambia con el tiempo); confirmar que la versión de Flutter usada en
  CI (`3.32.0`, `release-please.yml:69`) cumple el mínimo vigente.
- [ ] **Permisos declarados — revisar que todos se expliquen en Data safety**:
  `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
  `SCHEDULE_EXACT_ALARM` (`AndroidManifest.xml:4,7,8,20`). Nota ya documentada
  en el propio manifest (`:12-19`): `USE_EXACT_ALARM` fue deliberadamente
  omitido porque Play lo reserva para apps de alarma/calendario/timer — no
  reintroducirlo sin necesidad real, Play puede rechazar la app por declarar
  un permiso sensible sin justificación.

## 2. Firma y Play App Signing

- [x] Keystore de release y `key.properties` ya existen localmente
  (confirmado, no versionado — `.gitignore` lo cubre).
- [x] CI ya puede generar el mismo keystore desde secrets
  (`release-please.yml:84-99`).
- [ ] Si se activa **Play App Signing** (recomendado, es el flujo estándar de
  Play Console): Google re-firma el AAB con su propia clave para distribución.
  **Paso crítico que no está en `docs/PRODUCCION.md` todavía**: sacar el SHA-1
  que Play Console muestra en "Integridad de la app" → "Certificado de firma
  de la app" y agregarlo como cliente OAuth Android adicional en Google Cloud
  Console (mismo `applicationId`, SHA-1 nuevo). **Sin este paso, el login con
  Google (`docs/PRODUCCION.md` sección 6) funciona en cualquier build propio
  pero falla específicamente para quien instale desde Play Store**, porque el
  certificado que firma el APK instalado ya no es el que generó tu keystore.

## 3. Política de privacidad y Data safety

- [ ] Redactar la política de privacidad — **insumo directo de MJ-08**
  (`docs/mvp/UNIPLAN_EVOLUCION.md`), que ya produce el contenido legal de
  tratamiento de datos (Ley 1581 de 2012). Alojarla en una URL pública (puede
  ser una página estática en el dominio nuevo, ver `docs/PRODUCCION.md`
  sección 4).
- [ ] Formulario de seguridad de datos ("Data safety") de Play Console: debe
  reflejar exactamente qué se recolecta — nombre, correo, carrera, universidad,
  contraseña (hasheada con bcrypt), notificaciones locales, y los permisos de
  la sección 1. No declarar menos de lo que la app realmente hace; Play
  verifica esto contra el comportamiento real de la app en revisión.
- [ ] Cuestionario de clasificación de contenido.

## 4. Ficha de tienda

- [ ] Ícono de 512×512 px.
- [ ] Gráfico de función (feature graphic) 1024×500 px.
- [ ] 2 a 8 capturas de pantalla reales de la app (tomarlas **después** de los
  Sprints 1–3, no antes — el rediseño de login/registro/onboarding cambia
  exactamente las pantallas que normalmente se capturan primero).
- [ ] Descripción corta (80 caracteres) y larga (4000 caracteres).
- [ ] Categoría de la app (Educación o Productividad).

## 5. Cuenta y recorrido de publicación

- [ ] Cuenta de Google Play Console (pago único — lo ejecuta Jhon, requiere
  tarjeta/identidad personal).
- [ ] Verificar el requisito vigente de Play Console para cuentas de
  desarrollador personales nuevas (historialmente exige un periodo de pruebas
  cerradas con un mínimo de testers antes de habilitar producción) — revisar
  el requisito actual al momento de crear la cuenta, cambia con el tiempo.
- [ ] Recorrido de tracks recomendado: **pruebas internas** (equipo propio,
  sin revisión de Google) → **pruebas cerradas** (grupo de participantes del
  postest, si coincide en el tiempo — oportunidad de reusar a los mismos
  estudiantes del estudio como testers cerrados) → **producción**.
- [ ] Revisión de Google antes de producción (puede tardar días; planificar el
  cronograma de publicación con ese margen).

## 6. Pendientes heredados de `docs/PRODUCCION.md` que bloquean Play (no repetidos aquí en detalle, solo el estado)

Ver el documento original para el detalle completo de cada uno:
- Dominio propio (sección 4) — afecta `RESET_PASSWORD_URL` y la URL de la API.
- `GOOGLE_CLIENT_ID` en Vercel producción + pantalla de consentimiento OAuth
  saliendo de modo "Testing" (sección 6) — en Testing, el login con Google
  solo funciona para cuentas agregadas a mano; **no es viable para usuarios
  reales de Play Store**, tiene que pasar a producción en Google Cloud Console
  antes del lanzamiento público.
- Activar "Require status checks to pass" en GitHub (sección 7) — pendiente de
  un administrador del repositorio, no bloquea Play Store pero sí la calidad
  del pipeline que produce el AAB.

## 7. iOS — fuera de alcance de esta guía

`mobile/ios/` sigue siendo la plantilla de Flutter sin configurar
(`PRODUCT_BUNDLE_IDENTIFIER = com.example.mobile`,
`ios/Runner.xcodeproj/project.pbxproj:371,550,572`). Esta guía cubre
exclusivamente Google Play. Publicar en App Store requeriría un documento
separado y una cuenta de Apple Developer (anual, de pago) — no se detalla acá
porque no fue pedido.
