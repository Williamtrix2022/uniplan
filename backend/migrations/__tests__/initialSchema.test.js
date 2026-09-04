// ============================================
// TESTS: migración inicial (estructura, sin DB)
// ============================================
// No conecta a MySQL. Verifica que la migración baseline sea coherente:
// exporta up/down/setup, cubre todas las tablas del esquema, es
// idempotente (IF NOT EXISTS) y su reversa borra lo que crea.

const fs = require('fs');
const path = require('path');

const MIGRATION = '20260901000000-initial-schema';
const sqlDir = path.join(__dirname, '..', 'sqls');

const TABLAS = [
  'estudiantes',
  'materias',
  'tareas',
  'horarios',
  'notas',
  'eventos_calendario',
  'sesiones_pomodoro',
  'progreso_academico',
  'password_resets',
  'calificaciones',
  'notificaciones',
  'preferencias_notificacion'
];

describe('migración inicial', () => {
  const mod = require(path.join('..', `${MIGRATION}.js`));
  const up = fs.readFileSync(path.join(sqlDir, `${MIGRATION}-up.sql`), 'utf-8');
  const down = fs.readFileSync(path.join(sqlDir, `${MIGRATION}-down.sql`), 'utf-8');

  it('exporta setup, up y down como funciones', () => {
    expect(typeof mod.setup).toBe('function');
    expect(typeof mod.up).toBe('function');
    expect(typeof mod.down).toBe('function');
  });

  it('crea las 12 tablas del esquema y todas con IF NOT EXISTS', () => {
    for (const tabla of TABLAS) {
      expect(up).toContain(`CREATE TABLE IF NOT EXISTS ${tabla} (`);
    }
    // No debe haber ningún CREATE TABLE sin IF NOT EXISTS (baseline seguro).
    const createLines = up
      .split('\n')
      .filter((l) => /^\s*CREATE TABLE/i.test(l));
    expect(createLines).toHaveLength(TABLAS.length);
    for (const line of createLines) {
      expect(line).toMatch(/CREATE TABLE IF NOT EXISTS/i);
    }
  });

  it('la reversa borra cada tabla que la migración crea', () => {
    for (const tabla of TABLAS) {
      expect(down).toContain(`DROP TABLE IF EXISTS ${tabla};`);
    }
  });

  it('mantiene los enums del dominio', () => {
    expect(up).toContain("prioridad ENUM('baja','media','alta')");
    expect(up).toContain("dia ENUM('lunes','martes','miercoles','jueves','viernes','sabado','domingo')");
    expect(up).toContain("tipo ENUM('parcial','taller','quiz','proyecto','laboratorio','final','otro')");
    expect(up).toContain("tipo ENUM('tarea','clase','evento','sistema','general')");
  });
});
