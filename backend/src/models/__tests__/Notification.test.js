// ============================================
// TESTS: modelo Notification
// ============================================
// Se mockea pool.execute directamente (sin conexión real a MySQL).
// Foco: getPreferences crea una fila con valores por defecto cuando el
// estudiante todavía no tiene preferencias registradas.

jest.mock('../../config/database', () => ({
  pool: {
    execute: jest.fn()
  }
}));

const { pool } = require('../../config/database');
const Notification = require('../Notification');

describe('Notification model', () => {
  describe('getPreferences', () => {
    it('crea e inserta una fila con valores por defecto cuando el estudiante no tiene preferencias', async () => {
      const defaultRow = {
        id: 1,
        id_estudiante: 42,
        notif_tareas: 1,
        notif_clases: 1,
        notif_generales: 1,
        minutos_antes_tarea: 60,
        minutos_antes_clase: 30,
        sonido_activo: 1,
        hora_silencio_inicio: null,
        hora_silencio_fin: null
      };

      pool.execute
        // 1) SELECT inicial -> no existe fila
        .mockResolvedValueOnce([[]])
        // 2) INSERT de la fila por defecto
        .mockResolvedValueOnce([{ insertId: 1 }])
        // 3) SELECT posterior al INSERT -> retorna la fila recién creada
        .mockResolvedValueOnce([[defaultRow]]);

      const result = await Notification.getPreferences(42);

      expect(pool.execute).toHaveBeenCalledTimes(3);

      // La query de INSERT debe usar los valores por defecto documentados
      const insertCall = pool.execute.mock.calls[1];
      expect(insertCall[0]).toMatch(/INSERT INTO preferencias_notificacion/);
      expect(insertCall[1]).toEqual([
        42,
        true,  // notif_tareas
        true,  // notif_clases
        true,  // notif_generales
        60,    // minutos_antes_tarea
        30,    // minutos_antes_clase
        true,  // sonido_activo
        null,  // hora_silencio_inicio
        null   // hora_silencio_fin
      ]);

      expect(result).toEqual(defaultRow);
    });

    it('retorna la fila existente sin insertar cuando el estudiante ya tiene preferencias', async () => {
      const existingRow = { id: 2, id_estudiante: 7, notif_tareas: 0 };
      pool.execute.mockResolvedValueOnce([[existingRow]]);

      const result = await Notification.getPreferences(7);

      expect(pool.execute).toHaveBeenCalledTimes(1);
      expect(result).toEqual(existingRow);
    });

    it('re-consulta y retorna la fila en vez de lanzar cuando el INSERT choca con una carrera concurrente (ER_DUP_ENTRY)', async () => {
      const raceRow = { id: 3, id_estudiante: 99, notif_tareas: 1 };
      const dupError = Object.assign(new Error('Duplicate entry'), {
        code: 'ER_DUP_ENTRY'
      });

      pool.execute
        // 1) SELECT inicial -> no existe fila (todavía, desde el punto de vista de esta request)
        .mockResolvedValueOnce([[]])
        // 2) INSERT -> choca porque otra request concurrente ya insertó la fila
        .mockRejectedValueOnce(dupError)
        // 3) SELECT posterior -> ahora sí devuelve la fila creada por la otra request
        .mockResolvedValueOnce([[raceRow]]);

      const result = await Notification.getPreferences(99);

      expect(pool.execute).toHaveBeenCalledTimes(3);
      expect(result).toEqual(raceRow);
    });

    it('propaga errores del INSERT que no son ER_DUP_ENTRY', async () => {
      const otherError = Object.assign(new Error('connection refused'), {
        code: 'ECONNREFUSED'
      });

      pool.execute
        .mockResolvedValueOnce([[]])
        .mockRejectedValueOnce(otherError);

      await expect(Notification.getPreferences(123)).rejects.toThrow(
        'connection refused'
      );
    });
  });

  describe('markAsRead', () => {
    it('retorna null cuando no se afecta ninguna fila (no encontrada o no es dueño)', async () => {
      pool.execute.mockResolvedValueOnce([{ affectedRows: 0 }]);

      const result = await Notification.markAsRead(5, 1);

      expect(result).toBeNull();
    });

    it('retorna la notificación actualizada cuando la actualización afecta una fila', async () => {
      pool.execute
        .mockResolvedValueOnce([{ affectedRows: 1 }])
        .mockResolvedValueOnce([[{ id: 5, id_estudiante: 1, leida: 1 }]]);

      const result = await Notification.markAsRead(5, 1);

      expect(result).toEqual({ id: 5, id_estudiante: 1, leida: 1 });
    });
  });

  describe('findByStudent', () => {
    it('filtra por fecha_programada (NULL o ya vencida) para no mostrar recordatorios futuros antes de tiempo', async () => {
      pool.execute.mockResolvedValueOnce([[]]);

      await Notification.findByStudent(1);

      const query = pool.execute.mock.calls[0][0];
      expect(query).toMatch(/fecha_programada/);
      expect(query).toMatch(/fecha_programada\s+IS\s+NULL/i);
      expect(query).toMatch(/fecha_programada\s*<=\s*NOW\(\)/i);
    });
  });

  describe('getUnreadCount', () => {
    it('filtra por fecha_programada (NULL o ya vencida) para no contar recordatorios futuros antes de tiempo', async () => {
      pool.execute.mockResolvedValueOnce([[{ total: 0 }]]);

      await Notification.getUnreadCount(1);

      const query = pool.execute.mock.calls[0][0];
      expect(query).toMatch(/fecha_programada/);
      expect(query).toMatch(/fecha_programada\s+IS\s+NULL/i);
      expect(query).toMatch(/fecha_programada\s*<=\s*NOW\(\)/i);
    });
  });
});
