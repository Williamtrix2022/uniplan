// ============================================
// TESTS: middleware sanitizeErrorResponse
// ============================================
// Foco: fuera de desarrollo, las respuestas 5xx no deben llevar `error`
// ni `stack` al cliente; las <500 y el modo development pasan intactas.

const express = require('express');
const request = require('supertest');
const sanitizeErrorResponse = require('../sanitizeErrorResponse');

const buildApp = () => {
  const app = express();
  app.use(sanitizeErrorResponse);

  app.get('/boom', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Error al obtener perfil',
      error: 'ER_NO_SUCH_TABLE: Table \'uniplan.foo\' doesn\'t exist',
      stack: 'Error: ...\n    at /var/task/src/controllers/x.js:12'
    });
  });

  app.get('/bad-request', (req, res) => {
    res.status(400).json({
      success: false,
      message: 'El tipo no es válido',
      error: 'validation'
    });
  });

  return app;
};

describe('middleware sanitizeErrorResponse', () => {
  const OLD_ENV = process.env.NODE_ENV;

  afterEach(() => {
    process.env.NODE_ENV = OLD_ENV;
  });

  it('en producción poda error y stack de las respuestas 5xx', async () => {
    process.env.NODE_ENV = 'production';

    const res = await request(buildApp()).get('/boom');

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      success: false,
      message: 'Error al obtener perfil'
    });
    expect(res.body.error).toBeUndefined();
    expect(res.body.stack).toBeUndefined();
  });

  it('no toca las respuestas con status < 500', async () => {
    process.env.NODE_ENV = 'production';

    const res = await request(buildApp()).get('/bad-request');

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation');
  });

  it('en development deja pasar el detalle del error', async () => {
    process.env.NODE_ENV = 'development';

    const res = await request(buildApp()).get('/boom');

    expect(res.status).toBe(500);
    expect(res.body.error).toMatch(/ER_NO_SUCH_TABLE/);
    expect(res.body.stack).toBeDefined();
  });
});
