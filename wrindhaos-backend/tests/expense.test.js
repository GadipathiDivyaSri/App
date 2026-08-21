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

test('Expense Module: Calculations, Validations, and Balance Recalculation', async (t) => {
  // 1. Authenticate user
  const authRes = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'expense.test.user@wrindhaos.com',
    otp: '1234',
  });
  assert.strictEqual(authRes.statusCode, 200);
  const token = authRes.body.data.token;
  const headers = { Authorization: `Bearer ${token}` };

  // 2. Initial Budget = ₹10,000, Initial Balance = ₹10,000
  const initialSummary = await makeRequest('/api/v1/expenses/summary', 'GET', null, headers);
  assert.strictEqual(initialSummary.statusCode, 200);
  assert.strictEqual(initialSummary.body.data.monthlyBudget, 10000);
  assert.strictEqual(initialSummary.body.data.totalExpenses, 0);
  assert.strictEqual(initialSummary.body.data.availableBalance, 10000);

  // 3. Validation: Reject Negative & Zero Amounts
  const negRes = await makeRequest('/api/v1/expenses', 'POST', { title: 'Invalid', amount: -50 }, headers);
  assert.strictEqual(negRes.statusCode, 400);

  const zeroRes = await makeRequest('/api/v1/expenses', 'POST', { title: 'Zero', amount: 0 }, headers);
  assert.strictEqual(zeroRes.statusCode, 400);

  // 4. Add Expense 1: ₹500
  const exp1Res = await makeRequest(
    '/api/v1/expenses',
    'POST',
    { title: 'Groceries', category: 'Food & Drinks', amount: 500, isIncome: false },
    headers
  );
  assert.strictEqual(exp1Res.statusCode, 201);
  assert.strictEqual(exp1Res.body.data.summary.totalExpenses, 500);
  assert.strictEqual(exp1Res.body.data.summary.availableBalance, 9500);

  // 5. Add Expense 2: ₹1,000
  const exp2Res = await makeRequest(
    '/api/v1/expenses',
    'POST',
    { title: 'Books', category: 'Education', amount: 1000, isIncome: false },
    headers
  );
  assert.strictEqual(exp2Res.statusCode, 201);
  const exp2Id = exp2Res.body.data.expense.id;
  assert.strictEqual(exp2Res.body.data.summary.totalExpenses, 1500);
  assert.strictEqual(exp2Res.body.data.summary.availableBalance, 8500);

  // 6. Edit Expense 2: change amount from ₹1000 to ₹700 -> totalExpenses = 1200, availableBalance = 8800
  const editRes = await makeRequest(
    `/api/v1/expenses/${exp2Id}`,
    'PATCH',
    { amount: 700, title: 'Used Books' },
    headers
  );
  assert.strictEqual(editRes.statusCode, 200);
  assert.strictEqual(editRes.body.data.summary.totalExpenses, 1200);
  assert.strictEqual(editRes.body.data.summary.availableBalance, 8800);

  // 7. Delete Expense 2 -> totalExpenses = 500, availableBalance = 9500 (restores amount)
  const delRes = await makeRequest(`/api/v1/expenses/${exp2Id}`, 'DELETE', null, headers);
  assert.strictEqual(delRes.statusCode, 200);
  assert.strictEqual(delRes.body.data.summary.totalExpenses, 500);
  assert.strictEqual(delRes.body.data.summary.availableBalance, 9500);
});
