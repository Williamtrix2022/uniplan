// ============================================
// TESTS: Task.update — sincronía entre `estado` y `completada`
// ============================================
// La tabla `tareas` guarda el mismo hecho dos veces: el enum `estado` y el
// booleano `completada`. Las estadísticas (Task.getStats), las próximas
// entregas (Task.getUpcoming) y la limpieza (Task.cleanupOld) leen el
// BOOLEANO, pero el formulario de edición solo manda el ENUM.
//
// Estos tests fijan la regla: `update` debe derivar `completada` (y
// `fecha_completada`) a partir de `estado`, para que ambas columnas nunca
// queden desincronizadas.

jest.mock('../../config/database', () => ({
  pool: {
    execute: jest.fn()
  }
}));

const { pool } = require('../../config/database');
const Task = require('../Task');

const baseTask = {
  titulo: 'Entregar informe',
  descripcion: 'Capítulo 3',
  fecha_entrega: '2026-10-01',
  prioridad: 'alta',
  id_materia: 4,
  es_proyecto: false
};

// Devuelve el valor del parámetro `completada` en la llamada al UPDATE.
// La query lista las columnas en orden, así que `completada` es el 8º
// parámetro (índice 7), después de es_proyecto.
const completadaParam = () => pool.execute.mock.calls[0][1][7];

describe('Task model — update: sincroniza `completada` con `estado`', () => {
  beforeEach(() => {
    pool.execute.mockReset();
    pool.execute.mockResolvedValue([{ affectedRows: 1 }]);
  });

  it('marca completada = true cuando el estado pasa a "completada"', async () => {
    await Task.update(12, { ...baseTask, estado: 'completada' });

    expect(pool.execute).toHaveBeenCalledTimes(1);
    expect(pool.execute.mock.calls[0][0]).toMatch(/completada\s*=/);
    expect(completadaParam()).toBe(true);
  });

  it('marca completada = false cuando el estado es "pendiente"', async () => {
    await Task.update(12, { ...baseTask, estado: 'pendiente' });

    expect(completadaParam()).toBe(false);
  });

  it('marca completada = false cuando el estado es "en_progreso"', async () => {
    await Task.update(12, { ...baseTask, estado: 'en_progreso' });

    expect(completadaParam()).toBe(false);
  });

  it('también actualiza fecha_completada en la misma sentencia', async () => {
    await Task.update(12, { ...baseTask, estado: 'completada' });

    expect(pool.execute.mock.calls[0][0]).toMatch(/fecha_completada\s*=/);
  });

  it('devuelve false cuando no se afectó ninguna fila', async () => {
    pool.execute.mockResolvedValue([{ affectedRows: 0 }]);

    const result = await Task.update(99, { ...baseTask, estado: 'pendiente' });

    expect(result).toBe(false);
  });
});
