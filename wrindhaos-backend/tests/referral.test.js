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

test('Referral System: Code Generation, Self-Referral Block, Qualification & 10% Discount on Next Billing', async (t) => {
  // 1. Register Person A
  const authA = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'person.a@wrindhaos.com',
    otp: '1234',
  });
  assert.strictEqual(authA.statusCode, 200);
  const tokenA = authA.body.data.token;
  const headersA = { Authorization: `Bearer ${tokenA}` };

  const summaryA = await makeRequest('/api/v1/referrals/me', 'GET', null, headersA);
  assert.strictEqual(summaryA.statusCode, 200);
  const codeA = summaryA.body.data.referralCode;
  assert.ok(codeA.startsWith('WRINDHA'));
  assert.strictEqual(summaryA.body.data.successfulReferrals, 0);
  assert.strictEqual(summaryA.body.data.pendingReferrals, 0);
  assert.strictEqual(summaryA.body.data.activeDiscountPercent, 0);

  // 2. Person A tries to refer themselves -> Rejection (400)
  const selfRefRes = await makeRequest(
    '/api/v1/referrals/apply',
    'POST',
    { referralCode: codeA },
    headersA
  );
  assert.strictEqual(selfRefRes.statusCode, 400);
  assert.strictEqual(selfRefRes.body.error.code, 'SELF_REFERRAL_FORBIDDEN');

  // 3. Register Person B
  const authB = await makeRequest('/api/v1/auth/email/verify-otp', 'POST', {
    email: 'person.b@wrindhaos.com',
    otp: '1234',
  });
  assert.strictEqual(authB.statusCode, 200);
  const tokenB = authB.body.data.token;
  const headersB = { Authorization: `Bearer ${tokenB}` };

  // 4. Person B enters Person A's referral code -> status = PENDING
  const applyRes = await makeRequest(
    '/api/v1/referrals/apply',
    'POST',
    { referralCode: codeA },
    headersB
  );
  assert.strictEqual(applyRes.statusCode, 201);
  assert.strictEqual(applyRes.body.data.referral.status, 'PENDING');

  // Check Person A summary: pendingReferrals = 1, successfulReferrals = 0, discount = 0%
  const summaryA2 = await makeRequest('/api/v1/referrals/me', 'GET', null, headersA);
  assert.strictEqual(summaryA2.body.data.pendingReferrals, 1);
  assert.strictEqual(summaryA2.body.data.successfulReferrals, 0);
  assert.strictEqual(summaryA2.body.data.activeDiscountPercent, 0);

  // 5. Person B pays for subscription (Checkout) -> Referral qualifies, Person A gets 10% discount
  const checkoutB = await makeRequest(
    '/api/v1/subscriptions/checkout',
    'POST',
    { plan: 'PREMIUM', basePrice: 59.0 },
    headersB
  );
  assert.strictEqual(checkoutB.statusCode, 200);
  assert.strictEqual(checkoutB.body.data.pricing.finalAmount, 59.0); // Person B pays standard rate

  // 6. Verify Person A earned 10% discount
  const summaryA3 = await makeRequest('/api/v1/referrals/me', 'GET', null, headersA);
  assert.strictEqual(summaryA3.body.data.successfulReferrals, 1);
  assert.strictEqual(summaryA3.body.data.pendingReferrals, 0);
  assert.strictEqual(summaryA3.body.data.activeDiscountPercent, 10);

  // 7. Person A checks out their next billing cycle: ₹59 - 10% (₹5.90) = ₹53.10
  const checkoutA = await makeRequest(
    '/api/v1/subscriptions/checkout',
    'POST',
    { plan: 'PREMIUM', basePrice: 59.0 },
    headersA
  );
  assert.strictEqual(checkoutA.statusCode, 200);
  assert.strictEqual(checkoutA.body.data.pricing.originalPrice, 59.0);
  assert.strictEqual(checkoutA.body.data.pricing.discountPercentage, 10);
  assert.strictEqual(checkoutA.body.data.pricing.discountAmount, 5.9);
  assert.strictEqual(checkoutA.body.data.pricing.finalAmount, 53.1);

  // 8. Reward is valid ONLY for that cycle -> Next checkout for Person A is full price ₹59.00
  const summaryA4 = await makeRequest('/api/v1/referrals/me', 'GET', null, headersA);
  assert.strictEqual(summaryA4.body.data.activeDiscountPercent, 0); // Consumed

  const checkoutA2 = await makeRequest(
    '/api/v1/subscriptions/checkout',
    'POST',
    { plan: 'PREMIUM', basePrice: 59.0 },
    headersA
  );
  assert.strictEqual(checkoutA2.statusCode, 200);
  assert.strictEqual(checkoutA2.body.data.pricing.discountPercentage, 0);
  assert.strictEqual(checkoutA2.body.data.pricing.finalAmount, 59.0);
});
