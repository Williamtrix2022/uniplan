<div align="center">

<img src="mobile/assets/images/uniplan_logo.png" alt="Uniplan" width="120" />

# 📚 Uniplan

**Organización académica universitaria, todo en un solo lugar.**

[![CI — Tests](https://github.com/Williamtrix2022/uniplan/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/Williamtrix2022/uniplan/actions/workflows/ci-tests.yml)
[![Licencia MIT](https://img.shields.io/badge/Licencia-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](mobile/pubspec.yaml)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)](backend/package.json)
[![Backend en Vercel](https://img.shields.io/badge/Backend-Vercel-black?logo=vercel)](https://uniplan-jade.vercel.app)

</div>

---

## 📖 Descripción

**Uniplan** es una aplicación móvil (Flutter) con una API REST propia (Node.js
+ Express + MySQL) que ayuda a estudiantes universitarios a organizar su vida
académica: materias, horarios, tareas, calificaciones, notas y sesiones de
estudio con la técnica Pomodoro, todo sincronizado en la nube y con
notificaciones locales.

Proyecto desarrollado por estudiantes de Ingeniería de Sistemas de la
**Universidad de Córdoba**.

### ✨ Características principales

- 🔐 **Autenticación** con JWT + refresh tokens (rotación y revocación de sesión)
- 📚 **Materias y horarios**, con detección automática de conflictos de horario
- ✅ **Tareas y entregas** con prioridades, filtros y estadísticas
- 🎓 **Calificaciones**, resumen por materia y proyección de la nota necesaria para aprobar
- 📔 **Notas y apuntes**, con favoritos
- ⏱️ **Pomodoro** con persistencia de configuración y automatización real
- 📅 **Calendario académico** (día / semana / mes)
- 🔔 **Notificaciones** locales (recordatorios de tareas, sin duplicados)
- 📊 **Dashboard** con resumen y productividad semanal

---

## 🛠️ Stack tecnológico

| | |
|---|---|
| **Mobile** | Flutter · Dart · Provider (estado) · go_router (navegación) · Dio/http |
| **Backend** | Node.js · Express · MySQL (`mysql2`) · JWT · express-validator |
| **Infraestructura** | Vercel (API en producción) · Docker Compose (MySQL local) · `db-migrate` (migraciones versionadas) |
| **Calidad** | Jest (backend) · `flutter test` + `flutter analyze` (mobile) · GitHub Actions (CI) |
| **Distribución** | Firebase App Distribution (builds de prueba para testers) |

---

## 📁 Estructura del proyecto

```
uniplan/
├── backend/          # API REST (Node.js + Express + MySQL)
│   ├── src/          # controllers, models, routes, middlewares, validators
│   ├── migrations/   # historial de esquema versionado (db-migrate)
│   └── db/schema.sql # snapshot del esquema + datos demo
├── mobile/            # App Flutter (Android / iOS / Windows / Web)
├── docs/              # MVP, sprints y checklist de producción
├── docker-compose.yml # MySQL local para desarrollo
└── README.md
```

---

## 🚀 Empezar rápido

### Prerrequisitos

- Node.js ≥ 18
- Flutter ≥ 3.x
- Docker (para MySQL local) o una instancia MySQL 8 propia
- Git

### 1. Base de datos local

```bash
docker compose up -d
```

Levanta MySQL en `localhost:3307` con el esquema y datos demo ya cargados
(estudiante de prueba: `demo@uniplan.co` / `Uniplan2026`).

### 2. Backend

```bash
cd backend
npm install
cp .env.example .env
# Apuntar DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME a la base local (ver docker-compose.yml)
npm run dev
```

La API queda en `http://localhost:3000`.

### 3. Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://localhost:3000
```

Sin `--dart-define`, la app apunta por defecto al backend en producción
(`https://uniplan-jade.vercel.app`).

---

## 🧪 Tests

```bash
# Backend
cd backend && npm test

# Mobile
cd mobile && flutter analyze && flutter test
```

Ambos corren automáticamente en cada Pull Request a `main`/`dev` vía
[GitHub Actions](.github/workflows/ci-tests.yml).

---

## 📝 Documentación

- [Especificación del MVP y progreso por sprint](docs/mvp/UNIPLAN_MVP.md)
- [Detalle de sprints](docs/sprints)
- [Checklist de producción](docs/PRODUCCION.md)
- [API y endpoints del backend](backend/README.md)
- [Migraciones de base de datos](backend/migrations/README.md)

---

## 👨‍💻 Autores

**William Moya Santana** · **Jhon Quiceno Padilla**

Universidad de Córdoba — Facultad de Ingeniería — Ingeniería de Sistemas

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT — ver [LICENSE](LICENSE) para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Abre un issue o un pull request contra
`dev` para proponer cambios.

## 📧 Contacto

Para preguntas o sugerencias, abre un [issue en GitHub](https://github.com/Williamtrix2022/uniplan/issues).

---

<div align="center">

**Desarrollado con ❤️ para la comunidad estudiantil universitaria**

</div>
