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

test('Account Deletion: Permanently Erases User Records in Isolation', async (t) => {
  // 1. Create User 1 and add data
  const auth1 = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'user1.delete@wrindhaos.com',
    otp: '1234',
  });
  const token1 = auth1.body.data.token;
  const headers1 = { Authorization: `Bearer ${token1}` };

  await makeRequest('/api/v1/todos', 'POST', { title: 'User 1 Task' }, headers1);
  await makeRequest('/api/v1/habits', 'POST', { title: 'User 1 Habit' }, headers1);
  await makeRequest('/api/v1/expenses', 'POST', { title: 'User 1 Expense', amount: 300 }, headers1);

  // 2. Create User 2 and add data
  const auth2 = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'user2.stay@wrindhaos.com',
    otp: '1234',
  });
  const token2 = auth2.body.data.token;
  const headers2 = { Authorization: `Bearer ${token2}` };

  await makeRequest('/api/v1/todos', 'POST', { title: 'User 2 Task' }, headers2);
  await makeRequest('/api/v1/expenses', 'POST', { title: 'User 2 Expense', amount: 800 }, headers2);

  // 3. Delete User 1 account
  const delRes = await makeRequest('/api/v1/users/delete-account', 'DELETE', null, headers1);
  assert.strictEqual(delRes.statusCode, 200);
  assert.strictEqual(delRes.body.success, true);

  // 4. Verify User 1 cannot access /me
  const checkUser1 = await makeRequest('/api/v1/users/me', 'GET', null, headers1);
  assert.strictEqual(checkUser1.statusCode, 404);

  // 5. Verify User 2's data is completely intact (Isolation)
  const checkUser2 = await makeRequest('/api/v1/users/me', 'GET', null, headers2);
  assert.strictEqual(checkUser2.statusCode, 200);
  assert.strictEqual(checkUser2.body.data.user.email, 'user2.stay@wrindhaos.com');

  const user2Todos = await makeRequest('/api/v1/todos', 'GET', null, headers2);
  assert.strictEqual(user2Todos.body.data.todos.length, 1);
  assert.strictEqual(user2Todos.body.data.todos[0].title, 'User 2 Task');

  const user2Expenses = await makeRequest('/api/v1/expenses', 'GET', null, headers2);
  assert.strictEqual(user2Expenses.body.data.expenses.length, 1);
  assert.strictEqual(user2Expenses.body.data.expenses[0].title, 'User 2 Expense');
});
