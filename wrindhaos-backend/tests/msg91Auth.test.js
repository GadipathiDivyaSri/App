const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('http');
const app = require('../src/app');

describe('MSG91 Widget Token Authentication Suite', () => {
  let server;
  const PORT = 5099;
  const BASE_URL = `http://localhost:${PORT}/api/v1/auth`;

  before((_, done) => {
    server = http.createServer(app);
    server.listen(PORT, done);
  });

  after((_, done) => {
    server.close(done);
  });

  test('1. Reject request with missing accessToken', async () => {
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 400);
    assert.strictEqual(body.success, false);
    assert.ok(body.error.message.includes('accessToken'));
  });

  test('2. Reject invalid or expired MSG91 access token', async () => {
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ accessToken: 'test_invalid_token' }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.success, false);
    assert.strictEqual(body.error.code, 'INVALID_MSG91_TOKEN');
  });

  test('3. Successfully verify valid MSG91 access token & issue WrindhaOS JWT Session', async () => {
    const testEmail = 'divyasri.student@wrindhaos.com';
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.success, true);
    assert.ok(body.data.token, 'Must return signed JWT token');
    assert.strictEqual(body.data.user.email, testEmail);
    assert.strictEqual(body.data.user.subscription_plan, 'FREE');
    assert.strictEqual(body.data.user.subscription_status, 'ACTIVE');
    assert.ok(body.data.user.referral_code, 'Must generate unique referral code');
  });

  test('4. Existing user logging in with MSG91 token updates session without duplicate creation', async () => {
    const testEmail = 'divyasri.student@wrindhaos.com';
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.data.isNewUser, false);
    assert.strictEqual(body.data.user.email, testEmail);
  });
});
