const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('http');
const app = require('../src/app');
const { mockStore } = require('../src/config/supabase');
const { normalizeEmail, authenticateEmail } = require('../src/services/authService');

describe('MSG91 Widget Token & Supabase User Persistence Suite', () => {
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

  test('1. Reject request with missing accessToken (HTTP 400)', async () => {
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

  test('2. Reject invalid or expired MSG91 access token before reaching user creation (HTTP 401)', async () => {
    const beforeCount = mockStore.users.size;
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ accessToken: 'test_invalid_token' }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.success, false);
    assert.strictEqual(body.error.code, 'INVALID_MSG91_TOKEN');
    assert.strictEqual(mockStore.users.size, beforeCount, 'No user should be created on invalid token');
  });

  test('3. New verified email -> user created with correct FREE defaults and referral code (HTTP 200)', async () => {
    const testEmail = 'new.student.persist@wrindhaos.com';
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
    assert.strictEqual(body.data.isNewUser, true);
    assert.strictEqual(body.data.user.email, testEmail);
    assert.strictEqual(body.data.user.subscription_plan, 'FREE');
    assert.strictEqual(body.data.user.subscription_status, 'ACTIVE');
    assert.strictEqual(body.data.user.ads_enabled, true);
    assert.ok(body.data.user.referral_code.startsWith('WRINDHA'));
    assert.ok(body.data.token, 'Must return signed JWT token');
  });

  test('4. New verified email -> authentication identity created in user_auth_identities store', async () => {
    const testEmail = 'identity.check@wrindhaos.com';
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 200);
    
    // Check that identity record exists
    const identityKey = `email_${testEmail}`;
    const identity = mockStore.identities.get(identityKey);
    assert.ok(identity, 'Identity record must exist in identities table/store');
    assert.strictEqual(identity.provider, 'email');
    assert.strictEqual(identity.provider_user_id, testEmail);
    assert.strictEqual(identity.user_id, body.data.user.id);
  });

  test('5. Existing verified email -> existing user returned without duplicate creation', async () => {
    const testEmail = 'existing.student@wrindhaos.com';
    
    // 1st request - Creates user
    const res1 = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });
    const body1 = await res1.json();
    assert.strictEqual(body1.data.isNewUser, true);
    const userId = body1.data.user.id;

    // 2nd request - Reuses existing user
    const res2 = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });
    const body2 = await res2.json();
    assert.strictEqual(res2.status, 200);
    assert.strictEqual(body2.data.isNewUser, false);
    assert.strictEqual(body2.data.user.id, userId, 'Must match previous user ID');
    assert.strictEqual(body2.data.user.email, testEmail);
  });

  test('6. Email Normalization: Same email with different casing/whitespace resolves to same user', async () => {
    const baseEmail = 'casetest.student@wrindhaos.com';
    const casedEmail = '   CaseTest.Student@WrindhaOS.COM   ';
    
    assert.strictEqual(normalizeEmail(casedEmail), baseEmail);

    const res1 = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${casedEmail}`,
      }),
    });
    const body1 = await res1.json();
    assert.strictEqual(body1.data.user.email, baseEmail);

    const res2 = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${baseEmail}`,
      }),
    });
    const body2 = await res2.json();
    assert.strictEqual(body2.data.isNewUser, false);
    assert.strictEqual(body2.data.user.id, body1.data.user.id);
  });

  test('7. Database duplicate/race-condition handling in authenticateEmail', async () => {
    const raceEmail = 'race.condition@wrindhaos.com';
    // Run two concurrent authentications simultaneously
    const [result1, result2] = await Promise.all([
      authenticateEmail(raceEmail, '127.0.0.1'),
      authenticateEmail(raceEmail, '127.0.0.1'),
    ]);

    assert.strictEqual(result1.user.email, raceEmail);
    assert.strictEqual(result2.user.email, raceEmail);
    assert.strictEqual(result1.user.id, result2.user.id, 'Concurrent logins must resolve to the identical user ID');
  });

  test('8. Supabase service-role secret and sensitive config are never returned to the client', async () => {
    const testEmail = 'security.audit@wrindhaos.com';
    const res = await fetch(`${BASE_URL}/msg91/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${testEmail}`,
      }),
    });

    const body = await res.json();
    const rawString = JSON.stringify(body);
    assert.strictEqual(rawString.includes('service_role'), false);
    assert.strictEqual(rawString.includes('SERVICE_ROLE'), false);
    assert.strictEqual(rawString.includes('authkey'), false);
    assert.strictEqual(body.data.user.serviceRoleKey, undefined);
    assert.strictEqual(body.data.user.anonKey, undefined);
  });

  test('9. Convenience Alias: /email/verify-token functions identically to /msg91/verify', async () => {
    const aliasEmail = 'alias.user@wrindhaos.com';
    const res = await fetch(`${BASE_URL}/email/verify-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: `test_msg91_token_${aliasEmail}`,
      }),
    });

    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.data.user.email, aliasEmail);
  });

  test('10. Direct access bypass prevention: Invalid or missing token cannot access protected routes', async () => {
    const res = await fetch(`http://localhost:${PORT}/api/v1/users/me`, {
      method: 'GET',
      headers: {
        'Authorization': 'Bearer invalid_garbage_token_123',
      },
    });

    assert.strictEqual(res.status, 401);
    const body = await res.json();
    assert.strictEqual(body.success, false);
  });
});
