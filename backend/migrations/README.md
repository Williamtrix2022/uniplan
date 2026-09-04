# Migraciones de base de datos

Hasta ahora el esquema vivía solo en la base de producción y se copiaba a
mano a `backend/db/schema.sql`. A partir de acá, **todo cambio de esquema se
hace con una migración versionada** (`db-migrate`).

## Herramienta

[`db-migrate`](https://db-migrate.readthedocs.io/) + `db-migrate-mysql`
(ambos en `devDependencies`). La conexión se lee de las mismas variables de
entorno que el resto del backend (`DB_HOST`, `DB_PORT`, `DB_USER`,
`DB_PASSWORD`, `DB_NAME`) vía `backend/database.json` y `.env`.

## Comandos

```bash
cd backend

npm run migrate           # aplica todas las migraciones pendientes
npm run migrate:pending   # muestra qué se aplicaría, sin tocar la DB
npm run migrate:down      # revierte la última migración
npm run migrate:create -- nombre-del-cambio   # crea una migración nueva (.js + up/down .sql)
```

`db-migrate` lleva el control en una tabla `migrations` que crea solo.

## Estado inicial (baseline)

`20260901000000-initial-schema` refleja el esquema completo actual. Sus
`CREATE TABLE` usan `IF NOT EXISTS`, así que aplicarla sobre una base que
**ya tiene** el esquema (producción hoy) no rompe nada: solo deja la
migración registrada como aplicada. En una base vacía, la crea entera.

Primera vez sobre la base de producción actual:

```bash
npm run migrate   # no-op estructural + registra el baseline
```

## Cómo agregar un cambio

1. `npm run migrate:create -- agrega-campo-x`
2. Editar `migrations/sqls/<ts>-agrega-campo-x-up.sql` con el `ALTER TABLE`.
3. Editar el `-down.sql` con la reversa.
4. `npm run migrate:pending` para revisar, luego `npm run migrate`.
5. Actualizar `backend/db/schema.sql` para que el snapshot siga al día
   (lo usa `docker-compose.yml` para levantar una base local de cero, con
   datos demo). El snapshot y las migraciones deben describir la misma
   estructura.

## Relación con `backend/db/schema.sql`

- `schema.sql` = *foto* del esquema actual + datos demo. Rápido para
  `docker compose up`.
- `migrations/` = *historial* de cambios, forward-only, sin datos.

No se contradicen: al agregar una migración se actualiza también el
snapshot.
