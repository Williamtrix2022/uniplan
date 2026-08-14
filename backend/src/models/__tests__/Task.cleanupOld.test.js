// ============================================
// TESTS: Task.cleanupOld
// ============================================
// Se mockea `pool.execute` directamente (sin conexión real a MySQL).
// Foco: cubrir las 4 reglas de negocio:
//   1) días ≤ 0 -> error explícito
//   2) dry-run cuenta sin escribir
//   3) cero candidatas -> no toca la DB
//   4) modo real -> cuenta + soft-delete (UPDATE activo = FALSE)

jest.mock('../../config/database', () => ({
  pool: {
    execute: jest.fn()
  }
}));

const { pool } = require('../../config/database');
const Task = require('../Task');

describe('Task model — cleanupOld', () => {
  beforeEach(() => {
    pool.execute.mockReset();
  });

  it('rechaza daysOld ≤ 0 sin tocar la DB', async () => {
    await expect(Task.cleanupOld({ daysOld: 0 })).rejects.toThrow(/días positivos|positivo/);
    await expect(Task.cleanupOld({ daysOld: -5 })).rejects.toThrow(/días positivos|positivo/);
    expect(pool.execute).not.toHaveBeenCalled();
  });

  it('rechaza daysOld no numérico sin tocar la DB', async () => {
    await expect(Task.cleanupOld({ daysOld: 'abc' })).rejects.toThrow(/días positivos|positivo/);
    await expect(Task.cleanupOld({ daysOld: null })).rejects.toThrow(/días positivos|positivo/);
    expect(pool.execute).not.toHaveBeenCalled();
  });

  it('dry-run cuenta candidatas y NO ejecuta UPDATE', async () => {
    pool.execute.mockResolvedValueOnce([[{ total: 7 }]]);

    const result = await Task.cleanupOld({ daysOld: 90, dryRun: true });

    expect(pool.execute).toHaveBeenCalledTimes(1);
    expect(pool.execute.mock.calls[0][0]).toMatch(/SELECT COUNT\(\*\) AS total/);
    // El parámetro debe ser el negativo de daysOld (-90)
    expect(pool.execute.mock.calls[0][1]).toEqual([-90]);

    expect(result).toEqual({
      candidates: 7,
      softDeleted: 0,
      dryRun: true,
      daysOld: 90
    });
  });

  it('cero candidatas -> no ejecuta UPDATE y devuelve softDeleted=0', async () => {
    pool.execute.mockResolvedValueOnce([[{ total: 0 }]]);

    const result = await Task.cleanupOld({ daysOld: 90, dryRun: false });

    expect(pool.execute).toHaveBeenCalledTimes(1);
    expect(result).toEqual({
      candidates: 0,
      softDeleted: 0,
      dryRun: false,
      daysOld: 90
    });
  });

  it('modo real ejecuta SELECT + UPDATE y devuelve affectedRows como softDeleted', async () => {
    pool.execute
      // 1) SELECT COUNT(*) -> 3 candidatas
      .mockResolvedValueOnce([[{ total: 3 }]])
      // 2) UPDATE activo = FALSE -> affectedRows = 3
      .mockResolvedValueOnce([{ affectedRows: 3 }]);

    const result = await Task.cleanupOld({ daysOld: 30, dryRun: false });

    expect(pool.execute).toHaveBeenCalledTimes(2);

    const countCall = pool.execute.mock.calls[0];
    expect(countCall[0]).toMatch(/SELECT COUNT\(\*\) AS total/);
    // fecha_entrega <= DATE_ADD(CURDATE(), INTERVAL -30 DAY)
    expect(countCall[1]).toEqual([-30]);

    const updateCall = pool.execute.mock.calls[1];
    expect(updateCall[0]).toMatch(/UPDATE tareas/);
    expect(updateCall[0]).toMatch(/SET activo = FALSE/);
    expect(updateCall[0]).toMatch(/completada = TRUE/);
    expect(updateCall[1]).toEqual([-30]);

    expect(result).toEqual({
      candidates: 3,
      softDeleted: 3,
      dryRun: false,
      daysOld: 30
    });
  });

  it('daysOld decimal se trunca a entero (Math.trunc) sin perder signo', async () => {
    pool.execute
      .mockResolvedValueOnce([[{ total: 1 }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);

    const result = await Task.cleanupOld({ daysOld: 90.7, dryRun: false });

    // Math.trunc(90.7) = 90, y como días negativos: -90
    expect(pool.execute.mock.calls[0][1]).toEqual([-90]);
    expect(pool.execute.mock.calls[1][1]).toEqual([-90]);
    expect(result.daysOld).toBe(90.7); // se devuelve el valor original del caller
    expect(result.candidates).toBe(1);
    expect(result.softDeleted).toBe(1);
  });
});
