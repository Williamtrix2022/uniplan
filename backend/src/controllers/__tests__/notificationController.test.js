// ============================================
// TESTS: notificationController
// ============================================
// Se mockea el modelo Notification por completo (no se toca MySQL real).
// Foco: envelope de respuesta { success, ... }, ownership (403), 404 y
// validación de query params / body.

jest.mock('../../models/Notification');

const Notification = require('../../models/Notification');
const notificationController = require('../notificationController');

const buildRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('notificationController', () => {
  describe('getNotifications', () => {
    it('responde con el envelope estándar { success, count, data }', async () => {
      const req = { user: { id: 1 }, query: {} };
      const res = buildRes();
      const fakeNotifications = [
        { id: 1, id_estudiante: 1, titulo: 'Tarea próxima', tipo: 'tarea' }
      ];
      Notification.findByStudent.mockResolvedValue(fakeNotifications);

      await notificationController.getNotifications(req, res);

      expect(Notification.findByStudent).toHaveBeenCalledWith(1, {
        tipo: undefined,
        leida: undefined
      });
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        count: 1,
        data: fakeNotifications
      });
    });

    it('responde 400 cuando el filtro tipo no es válido', async () => {
      const req = { user: { id: 1 }, query: { tipo: 'invalido' } };
      const res = buildRes();

      await notificationController.getNotifications(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
      expect(Notification.findByStudent).not.toHaveBeenCalled();
    });

    it('responde 400 cuando leida no es "true"/"false"', async () => {
      const req = { user: { id: 1 }, query: { leida: 'si' } };
      const res = buildRes();

      await notificationController.getNotifications(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
    });
  });

  describe('createNotification', () => {
    it('responde 400 cuando el tipo no es válido', async () => {
      const req = {
        user: { id: 1 },
        body: { tipo: 'invalido', titulo: 'Recordatorio' }
      };
      const res = buildRes();

      await notificationController.createNotification(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(Notification.create).not.toHaveBeenCalled();
    });

    it('responde 400 cuando titulo está vacío', async () => {
      const req = { user: { id: 1 }, body: { titulo: '   ' } };
      const res = buildRes();

      await notificationController.createNotification(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(Notification.create).not.toHaveBeenCalled();
    });

    it('crea la notificación escopeada al usuario autenticado y responde 201', async () => {
      const req = {
        user: { id: 1 },
        body: {
          tipo: 'clase',
          titulo: 'Clase próxima a iniciar',
          mensaje: 'Cálculo I · 08:00 - 10:00',
          referencia_tipo: 'clase',
          referencia_id: 7,
          fecha_programada: '2026-07-15T13:00:00.000Z'
        }
      };
      const res = buildRes();
      const created = { id: 10, id_estudiante: 1, tipo: 'clase', titulo: 'Clase próxima a iniciar' };
      Notification.create.mockResolvedValue(created);

      await notificationController.createNotification(req, res);

      expect(Notification.create).toHaveBeenCalledWith(
        expect.objectContaining({ id_estudiante: 1, tipo: 'clase', referencia_id: 7 })
      );
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: created })
      );
    });
  });

  describe('getUnreadCount', () => {
    it('responde con el conteo de no leídas', async () => {
      const req = { user: { id: 1 } };
      const res = buildRes();
      Notification.getUnreadCount.mockResolvedValue(3);

      await notificationController.getUnreadCount(req, res);

      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: { unread_count: 3 }
      });
    });
  });

  describe('markRead', () => {
    it('responde 404 cuando la notificación no existe', async () => {
      const req = { params: { id: '99' }, user: { id: 1 } };
      const res = buildRes();
      Notification.findById.mockResolvedValue(null);

      await notificationController.markRead(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
      expect(Notification.markAsRead).not.toHaveBeenCalled();
    });

    it('responde 403 cuando la notificación no pertenece al usuario', async () => {
      const req = { params: { id: '5' }, user: { id: 1 } };
      const res = buildRes();
      Notification.findById.mockResolvedValue({ id: 5, id_estudiante: 2 });

      await notificationController.markRead(req, res);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
      expect(Notification.markAsRead).not.toHaveBeenCalled();
    });

    it('marca como leída y responde con el envelope estándar cuando el dueño coincide', async () => {
      const req = { params: { id: '5' }, user: { id: 1 } };
      const res = buildRes();
      Notification.findById.mockResolvedValue({ id: 5, id_estudiante: 1 });
      Notification.markAsRead.mockResolvedValue({ id: 5, id_estudiante: 1, leida: true });

      await notificationController.markRead(req, res);

      expect(Notification.markAsRead).toHaveBeenCalledWith('5', 1);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: { id: 5, id_estudiante: 1, leida: true } })
      );
    });
  });

  describe('deleteNotification', () => {
    it('responde 404 cuando la notificación no existe', async () => {
      const req = { params: { id: '99' }, user: { id: 1 } };
      const res = buildRes();
      Notification.findById.mockResolvedValue(null);

      await notificationController.deleteNotification(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('responde 403 cuando la notificación no pertenece al usuario', async () => {
      const req = { params: { id: '5' }, user: { id: 1 } };
      const res = buildRes();
      Notification.findById.mockResolvedValue({ id: 5, id_estudiante: 2 });

      await notificationController.deleteNotification(req, res);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(Notification.remove).not.toHaveBeenCalled();
    });
  });

  describe('getPreferences', () => {
    it('responde con el envelope estándar con las preferencias del estudiante', async () => {
      const req = { user: { id: 1 } };
      const res = buildRes();
      const fakePrefs = { id_estudiante: 1, notif_tareas: 1, notif_clases: 1 };
      Notification.getPreferences.mockResolvedValue(fakePrefs);

      await notificationController.getPreferences(req, res);

      expect(res.json).toHaveBeenCalledWith({ success: true, data: fakePrefs });
    });
  });

  describe('updatePreferences', () => {
    it('responde 400 cuando minutos_antes_tarea es negativo', async () => {
      const req = { user: { id: 1 }, body: { minutos_antes_tarea: -5 } };
      const res = buildRes();

      await notificationController.updatePreferences(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(Notification.updatePreferences).not.toHaveBeenCalled();
    });

    it('responde 400 cuando minutos_antes_clase no es numérico', async () => {
      const req = { user: { id: 1 }, body: { minutos_antes_clase: 'pronto' } };
      const res = buildRes();

      await notificationController.updatePreferences(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(Notification.updatePreferences).not.toHaveBeenCalled();
    });

    it('actualiza y responde con el envelope estándar cuando los datos son válidos', async () => {
      const req = { user: { id: 1 }, body: { notif_tareas: false } };
      const res = buildRes();
      const updated = { id_estudiante: 1, notif_tareas: 0 };
      Notification.updatePreferences.mockResolvedValue(updated);

      await notificationController.updatePreferences(req, res);

      expect(Notification.updatePreferences).toHaveBeenCalledWith(
        1,
        expect.objectContaining({ notif_tareas: false })
      );
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: updated })
      );
    });
  });
});
