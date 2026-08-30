const http = require('http');

function makeRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(JSON.stringify(postData));
    }
    req.end();
  });
}

async function runTests() {
  console.log('=== Starting Free vs Pro Limits & Feature Locking Integration Tests ===\n');

  // 1. Check Session & Subscription for default user
  const sessionRes = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/subscription/me',
    method: 'GET',
    headers: { 'Authorization': 'Bearer jwt_u_1:token' }
  });

  console.log('1. User Subscription Status:', sessionRes.data);
  if (sessionRes.status !== 200 || !sessionRes.data.subscription) {
    console.error('FAILED: Subscription endpoint returned unexpected result');
    process.exit(1);
  }
  console.log('-> Plan:', sessionRes.data.subscription.plan);

  // 2. Clear habits & test Free 2-habit limit
  // First habit
  const habit1 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/habits',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { title: 'Drink Water 2L', frequency: 'DAILY' });
  console.log('2a. Habit 1 creation status:', habit1.status);

  // Second habit
  const habit2 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/habits',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { title: 'Read 20 pages', frequency: 'DAILY' });
  console.log('2b. Habit 2 creation status:', habit2.status);

  // Third habit (Must be blocked for Free plan)
  const habit3 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/habits',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { title: 'Meditate 10 mins', frequency: 'DAILY' });
  console.log('2c. Habit 3 (Exceeding Limit) status:', habit3.status);
  console.log('    Response body:', habit3.data);

  if (habit3.status === 403 && habit3.data.code === 'LIMIT_REACHED') {
    console.log('PASSED: Free habit limit enforced successfully (Blocked at 2 habits)!');
  } else {
    console.error('FAILED: Free habit limit was not blocked properly.');
    process.exit(1);
  }

  // 3. Test Free 2-subject limit
  // First subject
  const sub1 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/subjects',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { name: 'Mathematics' });
  console.log('3a. Subject 1 creation status:', sub1.status);

  // Second subject
  const sub2 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/subjects',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { name: 'Computer Science' });
  console.log('3b. Subject 2 creation status:', sub2.status);

  // Third subject (Must be blocked for Free plan)
  const sub3 = await makeRequest({
    hostname: '127.0.0.1',
    port: 8080,
    path: '/api/subjects',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer jwt_u_1:token' }
  }, { name: 'Physics' });
  console.log('3c. Subject 3 (Exceeding Limit) status:', sub3.status);
  console.log('    Response body:', sub3.data);

  if (sub3.status === 403 && sub3.data.code === 'LIMIT_REACHED') {
    console.log('PASSED: Free subject limit enforced successfully (Blocked at 2 subjects)!');
  } else {
    console.error('FAILED: Free subject limit was not blocked properly.');
    process.exit(1);
  }

  console.log('\n=== ALL FREE VS PRO LIMITS & LOCKING TESTS PASSED PERFECTLY ===\n');
}

runTests().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
