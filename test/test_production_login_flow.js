const http = require('http');
const { handleApiRequest } = require('../backend/api_handler');

// Create standalone HTTP server listening on a dynamic port
const server = http.createServer((req, res) => {
  handleApiRequest(req, res);
});

server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const baseUrl = `http://127.0.0.1:${port}`;
  console.log(`[TEST SERVER] Running on ${baseUrl}`);

  function makeRequest(method, path, body = null, headers = {}) {
    return new Promise((resolve, reject) => {
      const u = new URL(baseUrl + path);
      const req = http.request(
        u,
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
              resolve({ status: res.statusCode, body: JSON.parse(data) });
            } catch (e) {
              resolve({ status: res.statusCode, raw: data });
            }
          });
        }
      );
      req.on('error', reject);
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  }

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(` ✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(` ❌ FAIL: ${message}`);
      failed++;
    }
  }

  try {
    const testEmail = `user_${Date.now()}@wrindhaos.app`;
    const testPass = 'SecurePassword2026!';

    console.log('\n--- TEST 1: Register Initiate & Verify ---');
    const regInit = await makeRequest('POST', '/api/auth/register-initiate', {
      username: `student_${Date.now().toString().slice(-4)}`,
      email: testEmail,
      password: testPass,
      confirmPassword: testPass,
    });
    assert(regInit.status === 200 && regInit.body.success === true, 'Register initiate sent verification code');

    const regVer = await makeRequest('POST', '/api/auth/register-verify', {
      email: testEmail,
      otp: '123456',
    });
    assert(regVer.status === 200 && regVer.body.success === true && !!regVer.body.token, 'Register verify created account and returned session JWT');

    console.log('\n--- TEST 2: Password Login Initiate (Direct Session Token) ---');
    const loginInit = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: testPass,
    });
    assert(loginInit.status === 200 && loginInit.body.success === true, 'Login initiate status 200 OK');
    assert(!!loginInit.body.token, 'Login initiate returned direct session JWT token');
    assert(!!loginInit.body.user && loginInit.body.user.email === testEmail, 'Login initiate returned correct user profile');

    const sessionToken = regVer.body.token || loginInit.body.token;

    console.log('\n--- TEST 3: Standard /api/auth/login Endpoint ---');
    const loginStd = await makeRequest('POST', '/api/auth/login', {
      email: testEmail,
      password: testPass,
    });
    assert(loginStd.status === 200 && loginStd.body.success === true, 'Standard login status 200 OK');
    assert(!!loginStd.body.token, 'Standard login returned session JWT token');

    console.log('\n--- TEST 4: Invalid Password Rejection ---');
    const loginBad = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: 'WrongPassword123!',
    });
    assert(loginBad.status === 401 && loginBad.body.success === false, 'Invalid password correctly rejected with 401');

    console.log('\n--- TEST 5: Authenticated Session Retrieval (/api/users/me) ---');
    const userMe = await makeRequest('GET', '/api/users/me', null, {
      Authorization: `Bearer ${sessionToken}`,
    });
    assert(userMe.status === 200 && userMe.body.success === true, 'Authenticated /api/users/me returned user details');
    assert(!!userMe.body.user && userMe.body.user.email === testEmail, 'Authenticated user email matches registered email');

    console.log('\n--- TEST 6: Google Play Reviewer Credential Bypass ---');
    const reviewerLogin = await makeRequest('POST', '/api/auth/login-initiate', {
      email: 'demo.reviewer@wrindha.app',
      password: 'any_password',
    });
    assert(reviewerLogin.status === 200 && reviewerLogin.body.success === true, 'Google Play Reviewer demo login succeeds');

    console.log('\n==================================================');
    console.log(` RESULTS: ${passed} PASSED, ${failed} FAILED`);
    console.log('==================================================\n');

    server.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('[TEST ERROR]:', err);
    server.close();
    process.exit(1);
  }
});
