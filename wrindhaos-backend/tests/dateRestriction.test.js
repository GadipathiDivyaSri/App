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

test('Date Restriction: Blocks Past Dates, Allows Today and Future Dates', async (t) => {
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'date.test.user@wrindhaos.com',
    otp: '1234',
  });
  assert.strictEqual(authRes.statusCode, 200);
  const token = authRes.body.data.token;
  const headers = { Authorization: `Bearer ${token}` };

  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 3600 * 1000).toISOString();
  const pastMonth = new Date(now.getTime() - 30 * 24 * 3600 * 1000).toISOString();
  const pastYear = '2023-01-15T10:00:00.000Z';
  const today = new Date().toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 3600 * 1000).toISOString();
  const nextYear = new Date(now.getTime() + 365 * 24 * 3600 * 1000).toISOString();

  // 1. Yesterday -> Rejection (400)
  const resYesterday = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Yesterday Event', start_time: yesterday },
    headers
  );
  assert.strictEqual(resYesterday.statusCode, 400);
  assert.strictEqual(resYesterday.body.error.code, 'PAST_DATE_FORBIDDEN');

  // 2. Past Month -> Rejection (400)
  const resPastMonth = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Past Month Event', start_time: pastMonth },
    headers
  );
  assert.strictEqual(resPastMonth.statusCode, 400);

  // 3. Past Year -> Rejection (400)
  const resPastYear = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Past Year Event', start_time: pastYear },
    headers
  );
  assert.strictEqual(resPastYear.statusCode, 400);

  // 4. Today -> Allowed (201)
  const resToday = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Today Focus Session', start_time: today },
    headers
  );
  assert.strictEqual(resToday.statusCode, 201);
  assert.strictEqual(resToday.body.data.event.title, 'Today Focus Session');

  // 5. Tomorrow -> Allowed (201)
  const resTomorrow = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Tomorrow Meeting', start_time: tomorrow },
    headers
  );
  assert.strictEqual(resTomorrow.statusCode, 201);

  // 6. Next Year -> Allowed (201)
  const resNextYear = await makeRequest(
    '/api/v1/calendar/events',
    'POST',
    { title: 'Next Year Milestone Event', start_time: nextYear },
    headers
  );
  assert.strictEqual(resNextYear.statusCode, 201);
});
