const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('http');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const config = require('../src/config/env');
const { mockStore } = require('../src/config/supabase');

describe('WrindhaOS JWT & Session Security Test Suite', () => {
  let server;
  const PORT = 5098;
  const BASE_URL = `http://localhost:${PORT}/api/v1`;

  before((_, done) => {
    server = http.createServer(app);
    server.listen(PORT, done);
  });

  after((_, done) => {
    server.close(done);
  });

  test('1. Missing Authorization header returns HTTP 401', async () => {
    const res = await fetch(`${BASE_URL}/users/me`, {
      method: 'GET',
    });
    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.success, false);
    assert.strictEqual(body.error.code, 'UNAUTHORIZED');
  });

  test('2. Invalid Bearer format (e.g. "Token xxx", "Basic xxx", plain token) returns HTTP 401', async () => {
    const res1 = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: 'Basic dXNlcjpwYXNz' },
    });
    assert.strictEqual(res1.status, 401);

    const res2 = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: 'Token xyz123' },
    });
    assert.strictEqual(res2.status, 401);

    const res3 = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: 'Bearer' },
    });
    assert.strictEqual(res3.status, 401);
  });

  test('3. Invalid or malformed JWT returns HTTP 401', async () => {
    const res = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: 'Bearer not_a_real_jwt_token.at.all' },
    });
    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.success, false);
  });

  test('4. Expired JWT returns HTTP 401 with TOKEN_EXPIRED code', async () => {
    const expiredToken = jwt.sign(
      { id: 'u_expired_test', email: 'expired@wrindhaos.com' },
      config.jwt.secret,
      { expiresIn: '-10s' }
    );

    const res = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${expiredToken}` },
    });
    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.error.code, 'TOKEN_EXPIRED');
  });

  test('5. Modified / tampered JWT payload returns HTTP 401', async () => {
    const validToken = jwt.sign(
      { id: 'u_tamper_test', email: 'tamper@wrindhaos.com' },
      config.jwt.secret,
      { expiresIn: '1h' }
    );
    const parts = validToken.split('.');
    const tamperedPayload = Buffer.from(JSON.stringify({ id: 'u_tamper_hacked', email: 'hacker@wrindhaos.com' })).toString('base64url');
    const tamperedToken = `${parts[0]}.${tamperedPayload}.${parts[2]}`;

    const res = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${tamperedToken}` },
    });
    assert.strictEqual(res.status, 401);
  });

  test('6. Token signed with wrong secret key returns HTTP 401', async () => {
    const wrongSecretToken = jwt.sign(
      { id: 'u_wrong_secret', email: 'wrong@wrindhaos.com' },
      'completely_different_attacker_secret_key_123',
      { expiresIn: '1h' }
    );

    const res = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${wrongSecretToken}` },
    });
    assert.strictEqual(res.status, 401);
  });

  test('7. Valid JWT allows request and returns HTTP 200', async () => {
    const userId = 'u_jwt_valid_user';
    mockStore.users.set(userId, {
      id: userId,
      email: 'valid.jwt@wrindhaos.com',
      full_name: 'Valid JWT User',
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
    });

    const validToken = jwt.sign(
      { id: userId, email: 'valid.jwt@wrindhaos.com', plan: 'FREE', status: 'ACTIVE' },
      config.jwt.secret,
      { expiresIn: '30d' }
    );

    const res = await fetch(`${BASE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${validToken}` },
    });
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.data.user.id, userId);
    assert.strictEqual(body.data.user.email, 'valid.jwt@wrindhaos.com');
  });

  test('8. Authenticated user ID strictly comes from JWT (IDOR Prevention)', async () => {
    const userA = 'user_id_alpha';
    const userB = 'user_id_beta';

    mockStore.users.set(userA, { id: userA, email: 'alpha@wrindhaos.com', full_name: 'User Alpha' });
    mockStore.users.set(userB, { id: userB, email: 'beta@wrindhaos.com', full_name: 'User Beta' });

    const tokenA = jwt.sign({ id: userA, email: 'alpha@wrindhaos.com' }, config.jwt.secret, { expiresIn: '1h' });

    // User A sends update request trying to modify user B's profile
    const res = await fetch(`${BASE_URL}/users/me`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        userId: userB,
        id: userB,
        full_name: 'Hacked Alpha Name',
      }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 200);
    // Verified that ONLY user A's profile was modified, user B remained untouched
    assert.strictEqual(body.data.user.id, userA);
    assert.strictEqual(mockStore.users.get(userB).full_name, 'User Beta');
  });

  test('9. Admin-only endpoint rejects ordinary FREE user with HTTP 403', async () => {
    const ordinaryUserId = 'u_ordinary_free_user';
    mockStore.users.set(ordinaryUserId, {
      id: ordinaryUserId,
      email: 'free.student@wrindhaos.com',
      role: 'USER',
      is_active: true,
    });

    const ordinaryToken = jwt.sign(
      { id: ordinaryUserId, email: 'free.student@wrindhaos.com', role: 'USER' },
      config.jwt.secret,
      { expiresIn: '1h' }
    );

    const res = await fetch(`${BASE_URL}/admin/dashboard`, {
      headers: {
        Authorization: `Bearer ${ordinaryToken}`,
      },
    });

    // In Zero-Admin architecture: ordinary user without approved admin role is rejected
    assert.ok(res.status === 403 || res.status === 401);
  });

  test('10. Admin endpoint accepts authorized admin token', async () => {
    const adminId = 'u_super_admin_verified';
    mockStore.users.set(adminId, {
      id: adminId,
      email: 'admin@wrindhaos.com',
      role: 'SUPER_ADMIN',
      is_active: true,
    });

    const adminToken = jwt.sign(
      { id: adminId, email: 'admin@wrindhaos.com', role: 'SUPER_ADMIN' },
      config.jwt.secret,
      { expiresIn: '1h' }
    );

    const res = await fetch(`${BASE_URL}/admin/dashboard`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });

    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(body.data.metrics);
  });
});
