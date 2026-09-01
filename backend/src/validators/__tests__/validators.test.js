// ============================================
// TESTS: capa de validación de entrada (express-validator)
// ============================================
// Monta las cadenas reales + handleValidation delante de un handler stub,
// sin auth ni DB. Verifica el contrato: 400 con envelope { success:false,
// message, errors[] } en entrada inválida; 200 y body saneado si es válida.

const express = require('express');
const request = require('supertest');

const { handleValidation } = require('../../middlewares/validate');
const taskV = require('../taskValidators');
const gradeV = require('../gradeValidators');
const scheduleV = require('../scheduleValidators');
const subjectV = require('../subjectValidators');

const ok = (req, res) => res.status(200).json({ success: true, body: req.body, params: req.params });

const buildApp = () => {
  const app = express();
  app.use(express.json());
  app.post('/tasks', taskV.create, handleValidation, ok);
  app.put('/tasks/:id', taskV.update, handleValidation, ok);
  app.get('/tasks/:id', taskV.detail, handleValidation, ok);
  app.post('/grades', gradeV.create, handleValidation, ok);
  app.post('/schedules', scheduleV.create, handleValidation, ok);
  app.post('/subjects', subjectV.create, handleValidation, ok);
  return app;
};

describe('capa de validación de entrada', () => {
  const app = buildApp();

  describe('tareas', () => {
    it('rechaza create sin titulo ni fecha_entrega', async () => {
      const res = await request(app).post('/tasks').send({});
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(typeof res.body.message).toBe('string');
      expect(Array.isArray(res.body.errors)).toBe(true);
      const campos = res.body.errors.map((e) => e.campo);
      expect(campos).toEqual(expect.arrayContaining(['titulo', 'fecha_entrega']));
    });

    it('rechaza prioridad fuera del enum', async () => {
      const res = await request(app)
        .post('/tasks')
        .send({ titulo: 'X', fecha_entrega: '2026-07-20', prioridad: 'urgentísima' });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('prioridad');
    });

    it('rechaza titulo de más de 150 caracteres', async () => {
      const res = await request(app)
        .post('/tasks')
        .send({ titulo: 'a'.repeat(151), fecha_entrega: '2026-07-20' });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('titulo');
    });

    it('acepta un create válido y recorta el titulo', async () => {
      const res = await request(app)
        .post('/tasks')
        .send({ titulo: '  Taller  ', fecha_entrega: '2026-07-20', prioridad: 'alta' });
      expect(res.status).toBe(200);
      expect(res.body.body.titulo).toBe('Taller');
    });

    it('rechaza :id no numérico', async () => {
      const res = await request(app).get('/tasks/abc');
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('id');
    });

    it('acepta un update parcial vacío (todos los campos opcionales)', async () => {
      const res = await request(app).put('/tasks/5').send({});
      expect(res.status).toBe(200);
    });
  });

  describe('calificaciones', () => {
    it('rechaza valor fuera de 0..5', async () => {
      const res = await request(app)
        .post('/grades')
        .send({ id_materia: 1, valor: 7, porcentaje: 20 });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('valor');
    });

    it('rechaza porcentaje mayor a 100', async () => {
      const res = await request(app)
        .post('/grades')
        .send({ id_materia: 1, valor: 4, porcentaje: 120 });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('porcentaje');
    });

    it('acepta una calificación válida', async () => {
      const res = await request(app)
        .post('/grades')
        .send({ id_materia: 1, valor: 4.2, porcentaje: 30, tipo: 'parcial' });
      expect(res.status).toBe(200);
    });
  });

  describe('horarios', () => {
    it('rechaza dia fuera del enum', async () => {
      const res = await request(app)
        .post('/schedules')
        .send({ id_materia: 1, dia: 'lunnes', hora_inicio: '07:00', hora_fin: '09:00' });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('dia');
    });

    it('rechaza hora con formato inválido', async () => {
      const res = await request(app)
        .post('/schedules')
        .send({ id_materia: 1, dia: 'lunes', hora_inicio: '7am', hora_fin: '09:00' });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('hora_inicio');
    });

    it('acepta HH:MM y HH:MM:SS', async () => {
      const res = await request(app)
        .post('/schedules')
        .send({ id_materia: 1, dia: 'lunes', hora_inicio: '07:00', hora_fin: '09:00:00' });
      expect(res.status).toBe(200);
    });
  });

  describe('materias', () => {
    it('rechaza color que no es hexadecimal', async () => {
      const res = await request(app).post('/subjects').send({ nombre: 'Cálculo', color: 'rojo' });
      expect(res.status).toBe(400);
      expect(res.body.errors[0].campo).toBe('color');
    });

    it('acepta #RRGGBB', async () => {
      const res = await request(app).post('/subjects').send({ nombre: 'Cálculo', color: '#4CAF50' });
      expect(res.status).toBe(200);
    });
  });
});
