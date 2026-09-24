const http = require('http');
const assert = require('assert');
const path = require('path');

const { handleApiRequest } = require(path.join(__dirname, '../backend/api_handler.js'));

let server;
let port;

function startTestServer() {
  return new Promise((resolve) => {
    server = http.createServer(async (req, res) => {
      let bodyStr = '';
      req.on('data', chunk => { bodyStr += chunk; });
      req.on('end', async () => {
        try {
          req.body = bodyStr ? JSON.parse(bodyStr) : {};
        } catch (_) {
          req.body = {};
        }
        await handleApiRequest(req, res);
      });
    });
    server.listen(0, '127.0.0.1', () => {
      port = server.address().port;
      console.log(`[FORGOT PASSWORD TEST SERVER] Listening on http://127.0.0.1:${port}`);
      resolve();
    });
  });
}

function makeRequest(method, pathStr, body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : '';
    const reqHeaders = {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
      ...headers,
    };

    const req = http.request(
      {
        hostname: '127.0.0.1',
        port,
        path: pathStr,
        method,
        headers: reqHeaders,
      },
      (res) => {
        let resData = '';
        res.on('data', chunk => { resData += chunk; });
        res.on('end', () => {
          let parsed;
          try {
            parsed = JSON.parse(resData);
          } catch (_) {
            parsed = resData;
          }
          resolve({ status: res.statusCode, body: parsed });
        });
      }
    );

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function runTests() {
  await startTestServer();

  let passed = 0;
  let failed = 0;

  function logPass(msg) {
    passed++;
    console.log(` ✅ PASS: ${msg}`);
  }

  function logFail(msg, err) {
    failed++;
    console.error(` ❌ FAIL: ${msg}`, err ? err.message : '');
  }

  const testEmail = `forgot_test_${Date.now()}@wrindhaos.app`;
  const oldPassword = 'OldPassword123!';
  const newPassword = 'NewPassword456!';

  try {
    console.log('\n--- TEST 1: Register User ---');
    const regInit = await makeRequest('POST', '/api/auth/register-initiate', {
      email: testEmail,
      password: oldPassword,
      username: `forgot_usr_${Date.now()}`,
    });
    const regVer = await makeRequest('POST', '/api/auth/register-verify', {
      email: testEmail,
      otp: '123456',
    });
    if (regVer.status === 200 && regVer.body.success) {
      logPass('Registered test user with old password');
    } else {
      logFail('Failed to register test user', regVer.body);
    }

    console.log('\n--- TEST 2: Verify Login with Old Password ---');
    const oldLogin = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: oldPassword,
    });
    if (oldLogin.status === 200 && oldLogin.body.success && oldLogin.body.token) {
      logPass('Login successful with Old Password');
    } else {
      logFail('Login failed with Old Password', oldLogin.body);
    }

    console.log('\n--- TEST 3: Initiate Forgot Password ---');
    const forgotInit = await makeRequest('POST', '/api/auth/forgot-password/initiate', {
      email: testEmail,
    });
    const otpCode = forgotInit.body.code;
    if (forgotInit.status === 200 && forgotInit.body.success && otpCode) {
      logPass('Forgot password initiated, OTP received');
    } else {
      logFail('Forgot password initiate failed', forgotInit.body);
    }

    console.log('\n--- TEST 4: Verify Forgot Password OTP ---');
    const forgotVer = await makeRequest('POST', '/api/auth/forgot-password/verify-otp', {
      email: testEmail,
      otp: otpCode,
    });
    const resetToken = forgotVer.body.resetToken;
    if (forgotVer.status === 200 && forgotVer.body.success && resetToken) {
      logPass('Forgot password OTP verified, reset token received');
    } else {
      logFail('Forgot password OTP verification failed', forgotVer.body);
    }

    console.log('\n--- TEST 5: Reset Password to New Password ---');
    const resetRes = await makeRequest('POST', '/api/auth/forgot-password/reset', {
      email: testEmail,
      resetToken,
      newPassword,
      confirmPassword: newPassword,
    });
    if (resetRes.status === 200 && resetRes.body.success) {
      logPass('Password successfully reset to New Password');
    } else {
      logFail('Password reset failed', resetRes.body);
    }

    console.log('\n--- TEST 6: Attempt Login with OLD Password (Must Fail 401) ---');
    const oldLoginAttempt = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: oldPassword,
    });
    if (oldLoginAttempt.status === 401 && oldLoginAttempt.body.success === false) {
      logPass('Login with OLD password correctly rejected (401 Unauthorized)');
    } else {
      logFail('Old password was NOT rejected after reset', oldLoginAttempt.body);
    }

    console.log('\n--- TEST 7: Login with NEW Password (Must Succeed 200 OK) ---');
    const newLoginAttempt = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: newPassword,
    });
    if (newLoginAttempt.status === 200 && newLoginAttempt.body.success && newLoginAttempt.body.token) {
      logPass('Login with NEW password succeeded and returned session token!');
    } else {
      logFail('Login with NEW password failed', newLoginAttempt.body);
    }

    console.log('\n==================================================');
    console.log(` RESULTS: ${passed} PASSED, ${failed} FAILED`);
    console.log('==================================================\n');

    server.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('[TEST ERROR]:', err);
    if (server) server.close();
    process.exit(1);
  }
}

runTests();
