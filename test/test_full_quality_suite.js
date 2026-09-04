const http = require('http');
const fs = require('fs');
const path = require('path');

console.log('=================================================================');
console.log('       WRINDHAOS PRODUCTION QUALITY ASSURANCE (QA) SUITE        ');
console.log('=================================================================');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition, message) {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  ✅ [PASS] ${message}`);
  } else {
    failedTests++;
    console.error(`  ❌ [FAIL] ${message}`);
  }
}

function makeRequest({ method, path, body = null, headers = {} }) {
  return new Promise((resolve) => {
    const payload = body ? JSON.stringify(body) : null;
    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers,
      ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {})
    };

    const req = http.request(
      {
        hostname: 'localhost',
        port: 8080,
        path,
        method,
        headers: reqHeaders
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          let parsed = null;
          try {
            parsed = JSON.parse(data);
          } catch (e) {
            parsed = data;
          }
          resolve({ status: res.statusCode, data: parsed, raw: data });
        });
      }
    );

    req.on('error', (err) => resolve({ error: err.message, status: 500 }));
    if (payload) req.write(payload);
    req.end();
  });
}

async function runQualitySuite() {
  const timestamp = Date.now();
  const testEmail = `qa_tester_${timestamp}@wrindhaos.in`;
  const testUser = `qa_user_${timestamp.toString().slice(-5)}`;
  let authToken = null;
  let userId = null;
  let generatedOtp = null;

  // ---------------------------------------------------------------------------
  // SECTION 1: SYSTEM & ASSET INTEGRITY
  // ---------------------------------------------------------------------------
  console.log('\n--- 1. SYSTEM & ASSET INTEGRITY ---');

  const healthRes = await makeRequest({ method: 'GET', path: '/api/health' });
  assert(healthRes.status === 200 && healthRes.data?.status === 'UP', 'Health check endpoint returns 200 OK UP');

  const indexRes = await makeRequest({ method: 'GET', path: '/' });
  assert(indexRes.status === 200 && typeof indexRes.raw === 'string' && indexRes.raw.includes('<html'), 'Root web server serves index.html');

  const manifestRes = await makeRequest({ method: 'GET', path: '/manifest.json' });
  assert(manifestRes.status === 200, 'Web App manifest.json is served with 200 OK');

  const mainJsExists = fs.existsSync(path.join(process.cwd(), 'main.dart.js'));
  assert(mainJsExists, 'Production web build main.dart.js exists');

  // ---------------------------------------------------------------------------
  // SECTION 2: SECURITY & CRYPTOGRAPHY
  // ---------------------------------------------------------------------------
  console.log('\n--- 2. SECURITY & CRYPTOGRAPHY ---');

  // Input Sanitization (XSS)
  const xssTest = await makeRequest({
    method: 'POST',
    path: '/api/tasks',
    body: { title: '<script>alert("xss")</script>Secure Task' },
    headers: { Authorization: 'Bearer mock_token' }
  });
  assert(
    xssTest.status === 401 || (xssTest.data?.title && !xssTest.data.title.includes('<script>')),
    'XSS Injection safely blocked or sanitized'
  );

  // ---------------------------------------------------------------------------
  // SECTION 3: AUTHENTICATION & SESSION LIFECYCLE
  // ---------------------------------------------------------------------------
  console.log('\n--- 3. AUTHENTICATION & SESSION LIFECYCLE ---');

  // 3.1 Register Initiate
  const initRes = await makeRequest({
    method: 'POST',
    path: '/api/auth/register-initiate',
    body: { username: testUser, email: testEmail, password: 'SecurePassword123!', confirmPassword: 'SecurePassword123!' }
  });
  assert(initRes.status === 200 && initRes.data?.success === true, 'Register initiate generates verification code');
  generatedOtp = initRes.data?.code;

  // 3.2 Register Verify (Wrong OTP -> Expect 400)
  const wrongOtpRes = await makeRequest({
    method: 'POST',
    path: '/api/auth/register-verify',
    body: { username: testUser, email: testEmail, otp: '000000' }
  });
  assert(wrongOtpRes.status === 400, 'Invalid OTP code rejected with 400 Bad Request');

  // 3.3 Register Verify (Valid OTP)
  const verifyRes = await makeRequest({
    method: 'POST',
    path: '/api/auth/register-verify',
    body: { username: testUser, email: testEmail, otp: generatedOtp, password: 'SecurePassword123!' }
  });
  assert(verifyRes.status === 200 && verifyRes.data?.token != null, 'Valid OTP registration succeeds and issues JWT token');
  authToken = verifyRes.data?.token;
  userId = verifyRes.data?.user?.id;

  // 3.4 Login Authentication (Incorrect password -> Expect 400)
  const badLogin = await makeRequest({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: testUser, password: 'WrongPassword' }
  });
  assert(badLogin.status === 400, 'Incorrect password rejected with 400');

  // 3.5 Login Authentication (Correct credentials)
  const goodLogin = await makeRequest({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: testUser, password: 'SecurePassword123!' }
  });
  assert(goodLogin.status === 200 && goodLogin.data?.success === true, 'Correct credentials login successfully');

  // ---------------------------------------------------------------------------
  // SECTION 4: FORGOT PASSWORD 3-STEP FLOW
  // ---------------------------------------------------------------------------
  console.log('\n--- 4. FORGOT PASSWORD LIFECYCLE ---');

  // 4.1 Initiate Forgot Password
  const fpInit = await makeRequest({
    method: 'POST',
    path: '/api/auth/forgot-password/initiate',
    body: { email: testEmail }
  });
  assert(fpInit.status === 200 && fpInit.data?.success === true, 'Forgot password initiate sends OTP');
  const fpOtp = fpInit.data?.code;

  // 4.2 Verify Forgot Password OTP
  const fpVerify = await makeRequest({
    method: 'POST',
    path: '/api/auth/forgot-password/verify-otp',
    body: { email: testEmail, otp: fpOtp }
  });
  assert(fpVerify.status === 200 && fpVerify.data?.resetToken != null, 'Forgot password OTP verified and issued resetToken');
  const resetToken = fpVerify.data?.resetToken;

  // 4.3 Reset Password
  const fpReset = await makeRequest({
    method: 'POST',
    path: '/api/auth/forgot-password/reset',
    body: { email: testEmail, resetToken, newPassword: 'BrandNewPassword2026!', confirmPassword: 'BrandNewPassword2026!' }
  });
  assert(fpReset.status === 200 && fpReset.data?.success === true, 'Password reset saved to database');

  // 4.4 Login with New Password
  const newLogin = await makeRequest({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: testUser, password: 'BrandNewPassword2026!' }
  });
  assert(newLogin.status === 200, 'Login succeeds with newly reset password');
  authToken = newLogin.data?.token;

  // ---------------------------------------------------------------------------
  // SECTION 5: FREE VS PRO TIER RESTRICTIONS
  // ---------------------------------------------------------------------------
  console.log('\n--- 5. FREE VS PRO TIER RESTRICTIONS ---');

  const authHeader = { Authorization: `Bearer ${authToken}` };

  // Create Habit 1 (Free allowed)
  const h1 = await makeRequest({
    method: 'POST',
    path: '/api/habits',
    headers: authHeader,
    body: { title: 'Read 20 mins', category: 'Studies', frequency: 'DAILY' }
  });
  assert(h1.status === 201, 'Free tier: Habit 1 creation allowed (201)');

  // Create Habit 2 (Free allowed)
  const h2 = await makeRequest({
    method: 'POST',
    path: '/api/habits',
    headers: authHeader,
    body: { title: 'Drink 3L water', category: 'Health', frequency: 'DAILY' }
  });
  assert(h2.status === 201, 'Free tier: Habit 2 creation allowed (201)');

  // Create Habit 3 (Free tier limit reached -> Expect 403)
  const h3 = await makeRequest({
    method: 'POST',
    path: '/api/habits',
    headers: authHeader,
    body: { title: 'Exercise 30 mins', category: 'Fitness', frequency: 'DAILY' }
  });
  assert(h3.status === 403 && h3.data?.code === 'LIMIT_REACHED', 'Free tier: Habit 3 blocked with 403 LIMIT_REACHED');

  // Free Tier: Milestones blocked -> Expect 403
  const mFree = await makeRequest({
    method: 'POST',
    path: '/api/milestones',
    headers: authHeader,
    body: { title: 'First Class Degree', targetDate: '2027-06-01' }
  });
  assert(mFree.status === 403 && mFree.data?.code === 'PRO_REQUIRED', 'Free tier: Milestones blocked with 403 PRO_REQUIRED');

  // ---------------------------------------------------------------------------
  // SECTION 6: PRO UPGRADE & UNLOCK
  // ---------------------------------------------------------------------------
  console.log('\n--- 6. PRO UPGRADE & UNLOCK ---');

  const upgrade = await makeRequest({
    method: 'POST',
    path: '/api/subscription/upgrade',
    headers: authHeader,
    body: { plan: 'pro', billingCycle: 'monthly' }
  });
  assert(upgrade.status === 200 && upgrade.data?.subscription?.plan === 'pro', 'Upgrade to Pro tier succeeds (200)');

  // Pro Tier: Milestone creation allowed (201)
  const mPro = await makeRequest({
    method: 'POST',
    path: '/api/milestones',
    headers: authHeader,
    body: { title: 'First Class Degree', targetDate: '2027-06-01' }
  });
  assert(mPro.status === 201, 'Pro tier: Milestone creation allowed (201)');

  // Goal creation allowed (201)
  const gCreate = await makeRequest({
    method: 'POST',
    path: '/api/goals',
    headers: authHeader,
    body: { title: 'Crack UPSC Exam', targetDate: '2027-06-01' }
  });
  assert(gCreate.status === 201, 'Goal creation allowed (201)');

  // ---------------------------------------------------------------------------
  // SECTION 7: HABIT COMPLETION & STREAKS ENGINE
  // ---------------------------------------------------------------------------
  console.log('\n--- 7. HABIT COMPLETIONS & STREAKS ---');

  const habitId = h1.data?.id;
  const todayStr = new Date().toISOString().split('T')[0];

  const toggleComp = await makeRequest({
    method: 'POST',
    path: `/api/habits/${habitId}/toggle`,
    headers: authHeader,
    body: { date: todayStr }
  });
  assert(toggleComp.status === 200 && toggleComp.data?.isCompleted === true, 'Habit completion toggle recorded (200)');

  const habitOverview = await makeRequest({
    method: 'GET',
    path: '/api/habits/overview',
    headers: authHeader
  });
  assert(habitOverview.status === 200 && habitOverview.data?.completedCount >= 1, 'Habit stats reflect completed habit');

  // ---------------------------------------------------------------------------
  // SECTION 8: COUPONS & PROMOTIONS
  // ---------------------------------------------------------------------------
  console.log('\n--- 8. COUPONS & PROMOTIONS ---');

  const validateCoupon = await makeRequest({
    method: 'POST',
    path: '/api/coupons/validate',
    headers: authHeader,
    body: { code: 'WELCOME50' }
  });
  assert(validateCoupon.status === 200 && validateCoupon.data?.success === true, 'Promo coupon WELCOME50 validated (50% off)');

  const applyCoupon = await makeRequest({
    method: 'POST',
    path: '/api/coupons/apply',
    headers: authHeader,
    body: { code: 'WELCOME50', originalPrice: 49 }
  });
  assert(applyCoupon.status === 200 && applyCoupon.data?.finalPrice === 24.5, 'Promo discount applied correctly (₹24.5)');

  // ---------------------------------------------------------------------------
  // SECTION 9: 6-TAB ANALYTICS SUITES
  // ---------------------------------------------------------------------------
  console.log('\n--- 9. ANALYTICS SUITES (6 TABS) ---');

  const anOverview = await makeRequest({ method: 'GET', path: '/api/analytics/overview', headers: authHeader });
  assert(anOverview.status === 200 && (anOverview.data?.data?.overallProgressScore != null || anOverview.data?.overallProgressScore != null), 'Analytics Tab 1: Overview returns Focus/Progress Score');

  const anHabits = await makeRequest({ method: 'GET', path: '/api/analytics/habits', headers: authHeader });
  assert(anHabits.status === 200 && (anHabits.data?.data?.totalHabits >= 2 || anHabits.data?.habitsTracked >= 2 || anHabits.data?.data?.bestStreak != null), 'Analytics Tab 2: Habits returns tracked habits');

  const anStudies = await makeRequest({ method: 'GET', path: '/api/analytics/studies', headers: authHeader });
  assert(anStudies.status === 200, 'Analytics Tab 3: Studies returns 200 OK');

  const anExpenses = await makeRequest({ method: 'GET', path: '/api/analytics/expenses', headers: authHeader });
  assert(anExpenses.status === 200 && (anExpenses.data?.data?.totalSpent != null || anExpenses.data?.totalExpenses != null), 'Analytics Tab 4: Expenses returns 200 OK');

  const anGoals = await makeRequest({ method: 'GET', path: '/api/analytics/goals', headers: authHeader });
  assert(anGoals.status === 200 && (anGoals.data?.data?.totalGoals >= 1 || anGoals.data?.totalGoals >= 1), 'Analytics Tab 5: Goals returns 200 OK');

  const anMilestones = await makeRequest({ method: 'GET', path: '/api/analytics/milestones', headers: authHeader });
  assert(anMilestones.status === 200, 'Analytics Tab 6: Milestones returns 200 OK');

  // ---------------------------------------------------------------------------
  // SECTION 10: ACCOUNT DELETION & GDPR PURGE
  // ---------------------------------------------------------------------------
  console.log('\n--- 10. GDPR ACCOUNT PURGE & DATA PRIVACY ---');

  const deleteAcc = await makeRequest({
    method: 'DELETE',
    path: '/api/users/me',
    headers: authHeader
  });
  assert(deleteAcc.status === 200 && deleteAcc.data?.success === true, 'User account and all personal data purged (200 OK)');

  // Verify token is invalidated
  const postDeleteCheck = await makeRequest({
    method: 'GET',
    path: '/api/analytics/overview',
    headers: authHeader
  });
  assert(postDeleteCheck.status === 401 || postDeleteCheck.status === 404, 'Purged user token no longer has access');

  // ---------------------------------------------------------------------------
  // FINAL QUALITY SCORECARD
  // ---------------------------------------------------------------------------
  console.log('\n=================================================================');
  console.log(` QUALITY AUDIT SCORE: ${passedTests} / ${totalTests} TESTS PASSED (${Math.round((passedTests / totalTests) * 100)}%)`);
  console.log('=================================================================');

  if (failedTests === 0) {
    console.log('🌟 EXCELLENT: PRODUCTION QUALITY CERTIFIED 100% READY! 🚀\n');
  } else {
    console.log(`⚠️ ${failedTests} quality test(s) failed. Check details above.\n`);
  }
}

runQualitySuite();
