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

  describe('create', () => {
    it('inserta una fila nueva cuando no hay ninguna activa para esa referencia', async () => {
      pool.execute
        // 1) SELECT de existencia -> no hay ninguna
        .mockResolvedValueOnce([[]])
        // 2) INSERT
        .mockResolvedValueOnce([{ insertId: 10 }]);

      const result = await Notification.create({
        id_estudiante: 1,
        tipo: 'tarea',
        titulo: 'Tarea próxima a vencer',
        mensaje: 'Entrega de laboratorio',
        referencia_tipo: 'tarea',
        referencia_id: 5,
        fecha_programada: '2026-08-25 23:00:00'
      });

      expect(pool.execute).toHaveBeenCalledTimes(2);
      const insertCall = pool.execute.mock.calls[1];
      expect(insertCall[0]).toMatch(/INSERT INTO notificaciones/);
      expect(result).toEqual({
        id: 10,
        id_estudiante: 1,
        tipo: 'tarea',
        titulo: 'Tarea próxima a vencer',
        mensaje: 'Entrega de laboratorio',
        leida: false,
        referencia_tipo: 'tarea',
        referencia_id: 5,
        fecha_programada: '2026-08-25 23:00:00'
      });
    });

    it('actualiza la fila existente (upsert) y resetea leida cuando la ocurrencia '
      + 'es genuinamente nueva (fecha_programada distinta a la guardada), aunque el '
      + 'cliente no la haya visto (oculta por fecha_programada futura)', async () => {
      pool.execute
        // 1) SELECT de existencia -> ya existe la fila 7, para la ocurrencia de la
        //    semana PASADA (el cliente no la vio porque findByStudent la oculta
        //    hasta que llegue su fecha_programada, pero sigue activa)
        .mockResolvedValueOnce([[{
          id: 7,
          leida: 0,
          fecha_programada: '2026-08-19 08:30:00'
        }]])
        // 2) UPDATE
        .mockResolvedValueOnce([{ affectedRows: 1 }]);

      const result = await Notification.create({
        id_estudiante: 1,
        tipo: 'clase',
        titulo: 'Clase próxima a iniciar',
        mensaje: 'Cálculo · 09:00 - 10:00',
        referencia_tipo: 'clase',
        referencia_id: 90,
        fecha_programada: '2026-08-26 08:30:00'
      });

      expect(pool.execute).toHaveBeenCalledTimes(2);
      const updateCall = pool.execute.mock.calls[1];
      expect(updateCall[0]).toMatch(/UPDATE notificaciones/);
      expect(updateCall[1]).toEqual([
        'Clase próxima a iniciar',
        'Cálculo · 09:00 - 10:00',
        '2026-08-26 08:30:00',
        7
      ]);
      // No se llama a INSERT en absoluto -- no hay una tercera query.
      expect(pool.execute).toHaveBeenCalledTimes(2);
      expect(result).toEqual({
        id: 7,
        id_estudiante: 1,
        tipo: 'clase',
        titulo: 'Clase próxima a iniciar',
        mensaje: 'Cálculo · 09:00 - 10:00',
        leida: false,
        referencia_tipo: 'clase',
        referencia_id: 90,
        fecha_programada: '2026-08-26 08:30:00'
      });
    });

    it('NO toca la fila ni resetea leida cuando fecha_programada es igual a la '
      + 'guardada — mismo aviso de siempre, evita que una notificación ya vista '
      + 'vuelva a aparecer como no leída solo por reabrir la app', async () => {
      pool.execute
        // 1) SELECT de existencia -> misma fecha_programada que se está por enviar,
        //    y ya estaba leída
        .mockResolvedValueOnce([[{
          id: 8,
          tipo: 'tarea',
          titulo: 'Tarea próxima a vencer',
          mensaje: 'Entrega de laboratorio vence mañana',
          leida: 1,
          fecha_programada: '2026-08-25 20:00:00'
        }]]);

      const result = await Notification.create({
        id_estudiante: 1,
        tipo: 'tarea',
        titulo: 'Tarea próxima a vencer',
        mensaje: 'Entrega de laboratorio vence mañana',
        referencia_tipo: 'tarea',
        referencia_id: 40,
        fecha_programada: '2026-08-25 20:00:00'
      });

      // Solo el SELECT de existencia -- ningún UPDATE ni INSERT.
      expect(pool.execute).toHaveBeenCalledTimes(1);
      expect(result).toEqual({
        id: 8,
        id_estudiante: 1,
        tipo: 'tarea',
        titulo: 'Tarea próxima a vencer',
        mensaje: 'Entrega de laboratorio vence mañana',
        leida: true,
        referencia_tipo: 'tarea',
        referencia_id: 40,
        fecha_programada: '2026-08-25 20:00:00'
      });
    });

    it('inserta directo sin chequear duplicados cuando no hay referencia_tipo/referencia_id '
      + '(notificaciones generales/sistema sin entidad asociada)', async () => {
      pool.execute.mockResolvedValueOnce([{ insertId: 20 }]);

      await Notification.create({
        id_estudiante: 1,
        tipo: 'general',
        titulo: 'Aviso del sistema',
        mensaje: 'Mantenimiento programado'
      });

      expect(pool.execute).toHaveBeenCalledTimes(1);
      expect(pool.execute.mock.calls[0][0]).toMatch(/INSERT INTO notificaciones/);
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
