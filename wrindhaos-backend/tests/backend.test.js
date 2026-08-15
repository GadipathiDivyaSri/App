const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');
const http = require('http');

let server;
let baseUrl;

test.before((t, done) => {
  server = app.listen(0, () => {
    const port = server.address().port;
    baseUrl = `http://localhost:${port}`;
    done();
  });
});

test.after((t, done) => {
  server.close(done);
});

// Helper for making test HTTP requests
function makeRequest(path, method = 'GET', body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${baseUrl}${path}`);
    const req = http.request(
      url,
      {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            resolve({ statusCode: res.statusCode, body: JSON.parse(data) });
          } catch (e) {
            resolve({ statusCode: res.statusCode, body: data });
          }
        });
      }
    );
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

test('1. Health Check Endpoint Returns 200 OK', async () => {
  const res = await makeRequest('/health');
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.status, 'ok');
  assert.ok(res.body.service.includes('WrindhaOS Backend'));
});

test('2. OpenAPI Swagger Docs Endpoint Returns Schema', async () => {
  const res = await makeRequest('/api-docs');
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.openapi, '3.0.0');
});

test('3. Email OTP Request Dispatches Code', async () => {
  const res = await makeRequest('/api/v1/auth/email/request-otp', 'POST', {
    email: 'test.student@wrindhaos.com',
  });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.success, true);
});

test('4. Email OTP Verification Returns Valid JWT Token & FREE Plan Defaults', async () => {
  const res = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'test.student@wrindhaos.com',
    otp: '1234',
  });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.success, true);
  assert.ok(res.body.data.token);
  assert.strictEqual(res.body.data.user.subscription_plan, 'FREE');
  assert.strictEqual(res.body.data.user.ads_enabled, true);
});

test('5. Entitlements Endpoint Confirms Free Limits (Max 2 Habits, Max 2 Subjects, Ads Enabled)', async () => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'test.student@wrindhaos.com',
    otp: '1234',
  });
  const token = authRes.body.data.token;

  const res = await makeRequest('/api/v1/entitlements', 'GET', null, {
    Authorization: `Bearer ${token}`,
  });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.data.plan, 'FREE');
  assert.strictEqual(res.body.data.adsEnabled, true);
  assert.strictEqual(res.body.data.features.habits.limit, 2);
  assert.strictEqual(res.body.data.features.subjects.limit, 2);
});

test('6. Free Plan Allows 2 Habits, Rejects 3rd Habit with HABIT_LIMIT_REACHED', async () => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'habit.user@wrindhaos.com',
    otp: '1234',
  });
  const token = authRes.body.data.token;

  // Habit 1
  const h1 = await makeRequest('/api/v1/habits', 'POST', { title: 'Habit 1' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(h1.statusCode, 201);

  // Habit 2
  const h2 = await makeRequest('/api/v1/habits', 'POST', { title: 'Habit 2' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(h2.statusCode, 201);

  // Habit 3 (Should be rejected for Free plan!)
  const h3 = await makeRequest('/api/v1/habits', 'POST', { title: 'Habit 3' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(h3.statusCode, 403);
  assert.strictEqual(h3.body.error.code, 'HABIT_LIMIT_REACHED');
});

test('7. Free Plan Allows 2 Subjects, Rejects 3rd Subject with SUBJECT_LIMIT_REACHED', async () => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'subject.user@wrindhaos.com',
    otp: '1234',
  });
  const token = authRes.body.data.token;

  // Subject 1
  const s1 = await makeRequest('/api/v1/subjects', 'POST', { title: 'Maths' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(s1.statusCode, 201);

  // Subject 2
  const s2 = await makeRequest('/api/v1/subjects', 'POST', { title: 'Physics' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(s2.statusCode, 201);

  // Subject 3 (Should be rejected for Free plan!)
  const s3 = await makeRequest('/api/v1/subjects', 'POST', { title: 'Chemistry' }, { Authorization: `Bearer ${token}` });
  assert.strictEqual(s3.statusCode, 403);
  assert.strictEqual(s3.body.error.code, 'SUBJECT_LIMIT_REACHED');
});

test('8. Google Play Subscription Verification Activates Premium & Disables Ads', async () => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'premium.user@wrindhaos.com',
    otp: '1234',
  });
  const token = authRes.body.data.token;

  const res = await makeRequest(
    '/api/v1/subscriptions/google/verify',
    'POST',
    {
      purchaseToken: 'gpa_token_valid_123',
      productId: 'wrindhaos_premium_monthly',
    },
    { Authorization: `Bearer ${token}` }
  );

  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.data.userPlan, 'PREMIUM');
  assert.strictEqual(res.body.data.adsEnabled, false);
});

test('9. Admin Dashboard Metrics Returns Overview Statistics', async () => {
  const res = await makeRequest('/api/v1/admin/dashboard', 'GET', null, {
    Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa',
  });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.success, true);
  assert.ok(res.body.data.metrics.totalUsers >= 0);
});

test('10. Super Admin Can Override User Plan to PREMIUM', async () => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'override.target@wrindhaos.com',
    otp: '1234',
  });
  const userId = authRes.body.data.user.id;

  const res = await makeRequest(
    `/api/v1/admin/users/${userId}/override-plan`,
    'PATCH',
    { plan: 'PREMIUM', reason: 'Admin Test Grant' },
    { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' }
  );

  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.data.user.subscription_plan, 'PREMIUM');
  assert.strictEqual(res.body.data.user.ads_enabled, false);
});
