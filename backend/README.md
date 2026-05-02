# 🚀 Uniplan Backend API

API REST para la gestión académica de estudiantes universitarios.

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Tecnologías](#tecnologías)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Ejecutar](#ejecutar)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Endpoints](#endpoints)
- [Base de Datos](#base-de-datos)

---

## 📖 Descripción

API REST desarrollada con Node.js y Express que proporciona endpoints para:

- Autenticación de usuarios (JWT)
- Gestión de materias académicas
- Organización de tareas y entregas
- Sistema de notas y apuntes
- Seguimiento de sesiones Pomodoro
- Calendario académico
- Dashboard con estadísticas

---

## 🛠️ Tecnologías

- **Node.js** v18+
- **Express.js** v4
- **MySQL** v8
- **JWT** - Autenticación
- **bcryptjs** - Encriptación de contraseñas
- **dotenv** - Variables de entorno

---

## 📥 Instalación

### 1. Clonar repositorio

```bash
git clone https://github.com/TU_USUARIO/uniplan.git
cd uniplan/backend
```

### 2. Instalar dependencias

```bash
npm install
```

### 3. Configurar base de datos

- Instalar XAMPP o MySQL Server
- Crear base de datos `uniplan_db`
- Ejecutar el script SQL ubicado en `/docs/database_schema.sql`

---

## ⚙️ Configuración

### Crear archivo `.env`

```env
# Servidor
PORT=3000
NODE_ENV=development

# Base de Datos
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=uniplan_db
DB_PORT=3306

# JWT
JWT_SECRET=tu_clave_secreta_super_segura
JWT_EXPIRE=7d

# Bcrypt
BCRYPT_ROUNDS=10

# Recuperación de contraseña / envío de correos
RESET_PASSWORD_URL=uniplan://reset-password
# URL web opcional para correos (recomendado para enlaces clickeables en todos los clientes)
RESET_PASSWORD_WEB_URL=https://tu-dominio.com/reset-password
RESET_TOKEN_EXPIRE_MINUTES=30

# Opción A: API de Resend
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxx
RESEND_FROM=Uniplan <no-reply@tu-dominio.com>

# Opción B: SMTP (fallback)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tu_correo@ejemplo.com
SMTP_PASS=tu_app_password
SMTP_FROM=Uniplan <no-reply@uniplan.app>
```

---

## 🚀 Ejecutar

### Modo desarrollo (con nodemon)

```bash
npm run dev
```

### Modo producción

```bash
npm start
```

El servidor estará disponible en: `http://localhost:3000`

---

## 📁 Estructura del Proyecto

```
backend/
├── src/
│   ├── config/
│   │   └── database.js          # Configuración de MySQL
│   ├── controllers/
│   │   ├── authController.js    # Autenticación
│   │   ├── studentController.js # CRUD estudiantes
│   │   ├── subjectController.js # CRUD materias
│   │   ├── taskController.js    # CRUD tareas
│   │   ├── noteController.js    # CRUD notas
│   │   ├── pomodoroController.js# Sesiones Pomodoro
│   │   ├── calendarController.js# Calendario
│   │   └── dashboardController.js# Dashboard
│   ├── middlewares/
│   │   └── authMiddleware.js    # Protección de rutas
│   ├── models/
│   │   ├── Student.js
│   │   ├── Subject.js
│   │   ├── Task.js
│   │   ├── Note.js
│   │   ├── Pomodoro.js
│   │   └── Calendar.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── studentRoutes.js
│   │   ├── subjectRoutes.js
│   │   ├── taskRoutes.js
│   │   ├── noteRoutes.js
│   │   ├── pomodoroRoutes.js
│   │   ├── calendarRoutes.js
│   │   └── dashboardRoutes.js
│   ├── utils/
│   │   └── validators.js        # Validaciones
│   └── app.js                   # Configuración Express
├── .env                         # Variables de entorno
├── .gitignore
├── package.json
├── server.js                    # Punto de entrada
└── README.md
```

---

## 📡 Endpoints

### Autenticación

| Método | Ruta | Descripción | Auth |
|--------|------|-------------|------|
| POST | `/api/auth/register` | Registrar estudiante | No |
| POST | `/api/auth/login` | Iniciar sesión | No |
| POST | `/api/auth/forgot-password` | Solicitar recuperación (envía correo) | No |
| POST | `/api/auth/reset-password` | Restablecer contraseña (correo + token) | No |
| GET | `/api/auth/profile` | Obtener perfil | Sí |
| PATCH | `/api/auth/change-password` | Cambiar contraseña autenticado | Sí |

### Materias

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/subjects` | Crear materia |
| GET | `/api/subjects` | Listar materias |
| GET | `/api/subjects/stats` | Estadísticas |
| GET | `/api/subjects/:id` | Obtener materia |
| PUT | `/api/subjects/:id` | Actualizar materia |
| DELETE | `/api/subjects/:id` | Eliminar materia |

### Tareas

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/tasks` | Crear tarea |
| GET | `/api/tasks` | Listar tareas |
| GET | `/api/tasks/upcoming` | Tareas próximas |
| GET | `/api/tasks/stats` | Estadísticas |
| PATCH | `/api/tasks/:id/complete` | Completar tarea |

### Notas

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/notes` | Crear nota |
| GET | `/api/notes` | Listar notas |
| GET | `/api/notes/favorites` | Favoritas |
| PATCH | `/api/notes/:id/favorite` | Toggle favorito |

### Pomodoro

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/pomodoro` | Iniciar sesión |
| GET | `/api/pomodoro/today` | Sesiones de hoy |
| GET | `/api/pomodoro/stats` | Estadísticas |
| PATCH | `/api/pomodoro/:id/complete` | Finalizar sesión |

### Calendario

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/calendar` | Crear evento |
| GET | `/api/calendar/today` | Eventos de hoy |
| GET | `/api/calendar/week` | Eventos de la semana |
| GET | `/api/calendar/month` | Eventos del mes |

### Dashboard

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/dashboard` | Dashboard completo |
| GET | `/api/dashboard/weekly` | Resumen semanal |
| GET | `/api/dashboard/today` | Resumen de hoy |

---

## 🗄️ Base de Datos

### Tablas

- `estudiantes` - Información de usuarios
- `materias` - Asignaturas del estudiante
- `tareas` - Tareas y entregas
- `notas` - Apuntes académicos
- `sesiones_pomodoro` - Registro de estudio
- `eventos_calendario` - Calendario académico
- `progreso_academico` - Estadísticas

### Diagrama ER

Ver archivo `/docs/diagrama_er.png`

---

## 🔐 Autenticación

La API utiliza **JWT (JSON Web Tokens)** para autenticación.

### Obtener token

```bash
POST /api/auth/login
Content-Type: application/json

{
  "correo": "usuario@ejemplo.com",
  "contrasena": "password123"
}
```

### Usar token

```bash
GET /api/subjects
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🧪 Pruebas

### Con Thunder Client (VS Code)

1. Instalar extensión Thunder Client
2. Importar colección desde `/docs/thunder_collection.json`
3. Ejecutar pruebas

### Con Postman

1. Importar colección desde `/docs/postman_collection.json`
2. Configurar variable de entorno `{{base_url}}` = `http://localhost:3000`

---

## 🐛 Solución de Problemas

### Error de conexión a MySQL

```bash
# Verificar que MySQL esté corriendo
# En XAMPP: Iniciar MySQL
# Verificar credenciales en .env
```

### Error "Cannot find module"

```bash
rm -rf node_modules
npm install
```

### Puerto ya en uso

```bash
# Cambiar PORT en .env
PORT=3001
```

---

## 📝 Licencia

MIT License - William Moya Santana

---

## 👨‍💻 Autor

**William Moya Santana**
- Universidad de Córdoba
- Ingeniería de Sistemas
- 2025
