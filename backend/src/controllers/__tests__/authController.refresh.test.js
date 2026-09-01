// ============================================
// TESTS: authController — refresh / logout / logout-all
// ============================================
// Modelos mockeados (sin MySQL). tokenService es real: firma JWT de
// verdad, así que se fija un JWT_SECRET de prueba.

process.env.JWT_SECRET = 'test-secret-para-jest';

jest.mock('../../models/RefreshToken');
jest.mock('../../models/Student');
jest.mock('../../services/mailService', () => ({ sendEmail: jest.fn().mockResolvedValue(true) }));

const RefreshToken = require('../../models/RefreshToken');
const Student = require('../../models/Student');
const { hashToken } = require('../../services/tokenService');
const authController = require('../authController');

const buildRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

// isUsable no está mockeado por jest.mock (es método estático) → se
// reimplementa igual que el modelo real para los tests.
RefreshToken.isUsable = (row) =>
  !!row && row.revoked === 0 && new Date(row.expires_at) > new Date();

const futuro = () => new Date(Date.now() + 60_000);
const pasado = () => new Date(Date.now() - 60_000);

describe('authController — refresh', () => {
  it('401 si el refresh token no existe', async () => {
    RefreshToken.findByHash.mockResolvedValue(null);
    const res = buildRes();

    await authController.refresh({ body: { refreshToken: 'x' } }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(RefreshToken.create).not.toHaveBeenCalled();
  });

  it('reuso de un token revocado → revoca todas las sesiones y 401', async () => {
    RefreshToken.findByHash.mockResolvedValue({
      id: 3, id_estudiante: 9, revoked: 1, expires_at: futuro()
    });
    const res = buildRes();

    await authController.refresh({ body: { refreshToken: 'robado' } }, res);

    expect(RefreshToken.revokeAllForStudent).toHaveBeenCalledWith(9);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it('401 si el token está vencido', async () => {
    RefreshToken.findByHash.mockResolvedValue({
      id: 4, id_estudiante: 9, revoked: 0, expires_at: pasado()
    });
    const res = buildRes();

    await authController.refresh({ body: { refreshToken: 'viejo' } }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(RefreshToken.create).not.toHaveBeenCalled();
  });

  it('token válido → rota: crea uno nuevo, revoca el anterior y devuelve el par', async () => {
    RefreshToken.findByHash.mockResolvedValue({
      id: 5, id_estudiante: 9, revoked: 0, expires_at: futuro()
    });
    Student.findById.mockResolvedValue({ id: 9, correo: 'a@b.co' });
    RefreshToken.create.mockResolvedValue(42);
    const res = buildRes();

    await authController.refresh({ body: { refreshToken: 'bueno' } }, res);

    expect(RefreshToken.create).toHaveBeenCalledWith(9, expect.any(String), expect.any(Date));
    expect(RefreshToken.revoke).toHaveBeenCalledWith(5, 42);
    const payload = res.json.mock.calls[0][0];
    expect(payload.success).toBe(true);
    expect(typeof payload.token).toBe('string');
    expect(typeof payload.refreshToken).toBe('string');
    // El refresh nuevo no puede ser el mismo string que se presentó.
    expect(payload.refreshToken).not.toBe('bueno');
  });
});

describe('authController — logout', () => {
  it('revoca el token cuando pertenece al usuario autenticado', async () => {
    RefreshToken.findByHash.mockResolvedValue({ id: 7, id_estudiante: 1, revoked: 0 });
    const res = buildRes();

    await authController.logout({ user: { id: 1 }, body: { refreshToken: 'mío' } }, res);

    expect(RefreshToken.revoke).toHaveBeenCalledWith(7);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });

  it('no revoca si el token es de otro usuario, pero responde 200', async () => {
    RefreshToken.findByHash.mockResolvedValue({ id: 7, id_estudiante: 2, revoked: 0 });
    const res = buildRes();

    await authController.logout({ user: { id: 1 }, body: { refreshToken: 'ajeno' } }, res);

    expect(RefreshToken.revoke).not.toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

describe('authController — logoutAll', () => {
  it('revoca todos los refresh tokens del usuario y devuelve el conteo', async () => {
    RefreshToken.revokeAllForStudent.mockResolvedValue(3);
    const res = buildRes();

    await authController.logoutAll({ user: { id: 1 } }, res);

    expect(RefreshToken.revokeAllForStudent).toHaveBeenCalledWith(1);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: true, data: { sesiones_cerradas: 3 } })
    );
  });
});

describe('tokenService — hashToken', () => {
  it('es determinístico y distinto por input', () => {
    expect(hashToken('abc')).toBe(hashToken('abc'));
    expect(hashToken('abc')).not.toBe(hashToken('abd'));
    expect(hashToken('abc')).toMatch(/^[a-f0-9]{64}$/);
  });
});
