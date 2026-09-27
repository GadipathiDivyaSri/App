const http = require('http');
const { handleApiRequest, getAuthOtp } = require('../backend/api_handler');

let server;
let testPort = 0;

function startServer() {
  return new Promise((resolve) => {
    server = http.createServer(async (req, res) => {
      let bodyStr = '';
      req.on('data', (chunk) => { bodyStr += chunk; });
      req.on('end', async () => {
        if (bodyStr) {
          try { req.body = JSON.parse(bodyStr); } catch (e) { req.body = {}; }
        } else {
          req.body = {};
        }
        await handleApiRequest(req, res);
      });
    });

    server.listen(0, '127.0.0.1', () => {
      testPort = server.address().port;
      console.log(`[ACCOUNT DELETION TEST SERVER] Listening on http://127.0.0.1:${testPort}`);
      resolve();
    });
  });
}

function request(path, method = 'GET', data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const reqHeaders = { 'Content-Type': 'application/json', ...headers };
    const req = http.request(`http://127.0.0.1:${testPort}${path}`, { method, headers: reqHeaders }, (res) => {
      let resBody = '';
      res.on('data', (chunk) => { resBody += chunk; });
      res.on('end', () => {
        let parsed = null;
        try { parsed = JSON.parse(resBody); } catch (e) { parsed = resBody; }
        resolve({ status: res.statusCode, body: parsed });
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function runTest() {
  await startServer();
  const testEmail = `del_test_${Date.now()}@wrindhaos.app`;
  const username = `deluser_${Date.now().toString().slice(-6)}`;
  const pass1 = 'Password123!';
  const pass2 = 'NewAccountPass456!';

  console.log(`\n--- TEST 1: Register First Account (${testEmail}) ---`);
  const init1 = await request('/api/auth/register-initiate', 'POST', { username, email: testEmail, password: pass1, confirmPassword: pass1 });
  if (init1.status !== 200) throw new Error(`Registration initiation failed: ${JSON.stringify(init1.body)}`);

  const otp1Obj = await getAuthOtp(testEmail);
  const otp1 = otp1Obj?.otp;
  console.log(`Fetched Registration OTP 1: ${otp1}`);
  if (!otp1) throw new Error('Could not fetch OTP 1');

  const ver1 = await request('/api/auth/register-verify', 'POST', { email: testEmail, otp: otp1 });
  console.log(`Register verify status: ${ver1.status}, message: ${ver1.body.message}`);
  if (ver1.status !== 200) throw new Error('First registration verification failed');
  console.log(' ✅ PASS: First account created');

  console.log('\n--- TEST 2: Login to First Account ---');
  const log1 = await request('/api/auth/login', 'POST', { identifier: testEmail, password: pass1 });
  console.log(`Login status: ${log1.status}`);
  const token1 = log1.body.token;
  if (!token1) throw new Error(`First login failed to obtain session token: ${JSON.stringify(log1.body)}`);
  console.log(' ✅ PASS: Logged into first account successfully');

  console.log('\n--- TEST 3: Delete Account Permanently ---');
  const delRes = await request('/api/users/me', 'DELETE', null, { Authorization: `Bearer ${token1}` });
  console.log(`Delete user status: ${delRes.status}, message: ${delRes.body.message}`);
  if (delRes.status !== 200) throw new Error('Account deletion failed');
  console.log(' ✅ PASS: Account deleted successfully');

  console.log('\n--- TEST 4: Attempt Login to Deleted Account (Must Fail) ---');
  const failLog = await request('/api/auth/login', 'POST', { identifier: testEmail, password: pass1 });
  console.log(`Login after deletion status: ${failLog.status}, message: ${failLog.body.message}`);
  if (failLog.status === 200) throw new Error('Deleted account was able to login!');
  console.log(' ✅ PASS: Login correctly rejected for deleted account (401 Unauthorized)');

  console.log('\n--- TEST 5: Re-register NEW Account with SAME Email ---');
  const newUsername = `newuser_${Date.now().toString().slice(-6)}`;
  const init2 = await request('/api/auth/register-initiate', 'POST', { username: newUsername, email: testEmail, password: pass2, confirmPassword: pass2 });
  if (init2.status !== 200) throw new Error(`Re-registration failed: ${JSON.stringify(init2.body)}`);

  const otp2Obj = await getAuthOtp(testEmail);
  const otp2 = otp2Obj?.otp;
  console.log(`Fetched Registration OTP 2: ${otp2}`);
  if (!otp2) throw new Error('Could not fetch OTP 2');

  const ver2 = await request('/api/auth/register-verify', 'POST', { email: testEmail, otp: otp2 });
  console.log(`New register verify status: ${ver2.status}, message: ${ver2.body.message}`);
  if (ver2.status !== 200) throw new Error('Re-registration verification failed');
  console.log(' ✅ PASS: Re-registered new account with same email address!');

  console.log('\n--- TEST 6: Login to NEW Account with New Password ---');
  const log2 = await request('/api/auth/login', 'POST', { identifier: testEmail, password: pass2 });
  if (log2.status !== 200 || !log2.body.token) throw new Error(`Login to new account failed: ${JSON.stringify(log2.body)}`);
  console.log(' ✅ PASS: Successfully logged into the re-created account!');

  console.log('\n==================================================');
  console.log(' ALL 6 ACCOUNT DELETION & RE-REGISTRATION TESTS PASSED');
  console.log('==================================================\n');

  server.close();
  process.exit(0);
}

runTest().catch((err) => {
  console.error('\n❌ TEST FAILED:', err.message);
  if (server) server.close();
  process.exit(1);
});
