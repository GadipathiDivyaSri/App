const http = require('http');
const assert = require('assert');
const path = require('path');

const { handleApiRequest } = require(path.join(__dirname, '../backend/api_handler.js'));
const { DatabaseManager } = require(path.join(__dirname, '../backend/db_manager.js'));

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
      console.log(`[DEFERRED PROMOTION TEST SERVER] Listening on http://127.0.0.1:${port}`);
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
    console.error(` ❌ FAIL: ${msg}`, err ? err.message || err : '');
  }

  const testEmail = `staging_test_${Date.now()}@wrindhaos.app`;
  const initialPassword = 'InitialPass123!';
  const newStagedPassword = 'NewStagedPass456!';

  try {
    console.log('\n--- 1. Register User with Initial Password ---');
    const regInit = await makeRequest('POST', '/api/auth/register-initiate', {
      email: testEmail,
      password: initialPassword,
      username: `staging_usr_${Date.now()}`,
    });
    const regVer = await makeRequest('POST', '/api/auth/register-verify', {
      email: testEmail,
      otp: '123456',
    });
    if (regVer.status === 200 && regVer.body.success) {
      logPass('Registered test user with Initial Password');
    } else {
      logFail('Failed to register test user', regVer.body);
    }

    console.log('\n--- 2. Request Forgot Password & Stage New Password ---');
    const forgotInit = await makeRequest('POST', '/api/auth/forgot-password/initiate', { email: testEmail });
    const otpCode = forgotInit.body.code;
    const forgotVer = await makeRequest('POST', '/api/auth/forgot-password/verify-otp', {
      email: testEmail,
      otp: otpCode,
    });
    const resetToken = forgotVer.body.resetToken;

    const resetRes = await makeRequest('POST', '/api/auth/forgot-password/reset', {
      email: testEmail,
      resetToken,
      newPassword: newStagedPassword,
      confirmPassword: newStagedPassword,
    });
    if (resetRes.status === 200 && resetRes.body.success) {
      logPass('Forgot password reset requested successfully');
    } else {
      logFail('Forgot password reset failed', resetRes.body);
    }

    console.log('\n--- 3. Verify Database Staging State ---');
    const userInDb = await DatabaseManager.getUserByEmailOrUsername(testEmail);
    if (userInDb && userInDb.new_password) {
      logPass('New password hash staged inside profiles.new_password column!');
    } else {
      logFail('profiles.new_password column was not populated', userInDb);
    }

    console.log('\n--- 4. Login with NEW Password (Triggers Hash Promotion) ---');
    const newLoginRes = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: newStagedPassword,
    });
    if (newLoginRes.status === 200 && newLoginRes.body.success) {
      logPass('Login with NEW password succeeded!');
    } else {
      logFail('Login with NEW password failed', newLoginRes.body);
    }

    console.log('\n--- 5. Verify Database Promotion & Cleanup State ---');
    const promotedUserInDb = await DatabaseManager.getUserByEmailOrUsername(testEmail);
    if (promotedUserInDb && !promotedUserInDb.new_password && promotedUserInDb.password_hash === userInDb.new_password) {
      logPass('profiles.new_password promoted to password_hash & new_password reset to null!');
    } else {
      logFail('Password promotion or cleanup failed', promotedUserInDb);
    }

    console.log('\n--- 6. Subsequent Login Verification ---');
    const subLoginRes = await makeRequest('POST', '/api/auth/login-initiate', {
      email: testEmail,
      password: newStagedPassword,
    });
    if (subLoginRes.status === 200 && subLoginRes.body.success) {
      logPass('Subsequent login with promoted password_hash succeeded!');
    } else {
      logFail('Subsequent login failed', subLoginRes.body);
    }

    // Clean up test user
    if (userInDb && userInDb.id) {
      await DatabaseManager.deleteUser(userInDb.id);
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
