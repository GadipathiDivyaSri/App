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

  console.log(`\n--- TEST 1: Register First Account (${testEmail}) ---`);
  const init1 = await request('/api/auth/register-initiate', 'POST', { username, email: testEmail });
  if (init1.status !== 200) throw new Error(`Registration initiation failed: ${JSON.stringify(init1.body)}`);

  const otp1Obj = await getAuthOtp(testEmail);
  const otp1 = otp1Obj?.otp;
  console.log(`Fetched Registration OTP 1: ${otp1}`);
  if (!otp1) throw new Error('Could not fetch OTP 1');

  const ver1 = await request('/api/auth/register-verify', 'POST', { email: testEmail, otp: otp1, username });
  console.log(`Register verify status: ${ver1.status}, message: ${ver1.body.message}`);
  if (ver1.status !== 200) throw new Error('First registration verification failed');
  const token1 = ver1.body.token;
  console.log(' ✅ PASS: First account created');

  console.log('\n--- TEST 2: Passwordless Login OTP to First Account ---');
  const log1Init = await request('/api/auth/login-initiate', 'POST', { email: testEmail });
  console.log(`Login initiate status: ${log1Init.status}`);
  if (log1Init.status !== 200) throw new Error(`Passwordless login initiate failed: ${JSON.stringify(log1Init.body)}`);

  const loginOtpObj1 = await getAuthOtp(testEmail);
  const loginOtp1 = loginOtpObj1?.otp;
  const verLogin1 = await request('/api/auth/login-verify', 'POST', { email: testEmail, otp: loginOtp1 });
  if (verLogin1.status !== 200 || !verLogin1.body.token) throw new Error(`Login verify failed: ${JSON.stringify(verLogin1.body)}`);
  console.log(' ✅ PASS: Logged into first account successfully via Email OTP');

  console.log('\n--- TEST 3: Delete Account Permanently ---');
  const delRes = await request('/api/users/me', 'DELETE', null, { Authorization: `Bearer ${token1}` });
  console.log(`Delete user status: ${delRes.status}, message: ${delRes.body.message}`);
  if (delRes.status !== 200) throw new Error('Account deletion failed');
  console.log(' ✅ PASS: Account deleted successfully');

  console.log('\n--- TEST 4: Attempt Passwordless Login to Deleted Account (Must Fail 403 / 404) ---');
  const failLog = await request('/api/auth/login-initiate', 'POST', { email: testEmail });
  console.log(`Login initiate after deletion status: ${failLog.status}, message: ${failLog.body.message}`);
  if (failLog.status === 200) throw new Error('Deleted account was able to initiate login!');
  console.log(' ✅ PASS: Passwordless login correctly rejected for deleted account');

  console.log('\n--- TEST 5: Re-register NEW Account with SAME Email ---');
  const newUsername = `newuser_${Date.now().toString().slice(-6)}`;
  const init2 = await request('/api/auth/register-initiate', 'POST', { username: newUsername, email: testEmail });
  if (init2.status !== 200) throw new Error(`Re-registration failed: ${JSON.stringify(init2.body)}`);

  const otp2Obj = await getAuthOtp(testEmail);
  const otp2 = otp2Obj?.otp;
  console.log(`Fetched Registration OTP 2: ${otp2}`);
  if (!otp2) throw new Error('Could not fetch OTP 2');

  const ver2 = await request('/api/auth/register-verify', 'POST', { email: testEmail, otp: otp2, username: newUsername });
  console.log(`New register verify status: ${ver2.status}, message: ${ver2.body.message}`);
  if (ver2.status !== 200) throw new Error('Re-registration verification failed');
  console.log(' ✅ PASS: Re-registered new account with same email address!');

  console.log('\n--- TEST 6: Passwordless Login to NEW Account ---');
  const log2Init = await request('/api/auth/login-initiate', 'POST', { email: testEmail });
  const loginOtpObj2 = await getAuthOtp(testEmail);
  const verLogin2 = await request('/api/auth/login-verify', 'POST', { email: testEmail, otp: loginOtpObj2?.otp });
  if (verLogin2.status !== 200 || !verLogin2.body.token) throw new Error(`Login to new account failed: ${JSON.stringify(verLogin2.body)}`);
  console.log(' ✅ PASS: Successfully logged into the re-created account via Email OTP!');

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
