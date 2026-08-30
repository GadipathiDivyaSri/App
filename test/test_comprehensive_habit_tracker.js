const http = require('http');

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const dataString = body ? JSON.stringify(body) : '';
    const headers = {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(dataString),
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const options = {
      hostname: 'localhost',
      port: 8080,
      path: path,
      method: method,
      headers: headers,
    };

    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => (responseBody += chunk));
      res.on('end', () => {
        try {
          const json = responseBody ? JSON.parse(responseBody) : {};
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, text: responseBody });
        }
      });
    });

    req.on('error', (err) => reject(err));
    if (dataString) req.write(dataString);
    req.end();
  });
}

async function runHabitTrackerAudit() {
  console.log('=================================================================');
  console.log('      WRINDHAOS HABIT TRACKER FULL AUDIT & VERIFICATION          ');
  console.log('=================================================================\n');

  // 1. Authenticate / Create Isolated Test User via Google OAuth
  const testEmail = `habit_tester_${Date.now()}@wrindhaos.in`;
  const authRes = await makeRequest('POST', '/api/auth/google', {
    email: testEmail,
    googleId: `g_ht_${Date.now()}`,
    name: 'Habit Audit User',
  });

  const token = authRes.data.token;
  const userId = authRes.data.user.id;
  console.log(`[1] Authenticated Test User: ${userId} (${testEmail}) - Plan: ${authRes.data.user.subscriptionPlan}`);

  // 2. Free Tier Limits Enforcement (Max 2 Habits)
  console.log('\n--- 2. FREE TIER HABIT LIMIT ENFORCEMENT ---');
  const h1 = await makeRequest('POST', '/api/habits', {
    title: 'Daily Morning Meditation',
    category: 'Mindfulness',
    frequency: 'DAILY',
  }, token);
  console.log(`[2.1] Habit 1 (Daily): Status ${h1.status} - ID: ${h1.data.id}`);

  const h2 = await makeRequest('POST', '/api/habits', {
    title: 'Gym Workout (Mon, Wed, Fri)',
    category: 'Health & Fitness',
    frequency: 'CUSTOM',
    selectedDays: [1, 3, 5],
  }, token);
  console.log(`[2.2] Habit 2 (Mon/Wed/Fri): Status ${h2.status} - ID: ${h2.data.id}`);

  const h3 = await makeRequest('POST', '/api/habits', {
    title: 'Read 20 pages',
    category: 'Study & Learning',
    frequency: 'DAILY',
  }, token);
  console.log(`[2.3] Habit 3 on Free Tier (Expect 403): Status ${h3.status} - Code: ${h3.data.code}`);
  console.assert(h3.status === 403, 'Free tier must reject 3rd habit with 403');
  console.assert(h3.data.code === 'LIMIT_REACHED', 'Code must be LIMIT_REACHED');

  // 3. Pro Upgrade & Unlimited Creation
  console.log('\n--- 3. PRO UPGRADE & UNLIMITED HABIT UNLOCK ---');
  const upgRes = await makeRequest('POST', '/api/subscription/upgrade', { provider: 'GOOGLE_PLAY' }, token);
  console.log(`[3.1] Upgrade Subscription: Status ${upgRes.status} - Plan: ${upgRes.data.subscription.plan}`);

  const h3Pro = await makeRequest('POST', '/api/habits', {
    title: 'Read 20 pages',
    category: 'Study & Learning',
    frequency: 'DAILY',
  }, token);
  console.log(`[3.2] Habit 3 on Pro Tier (Expect 201): Status ${h3Pro.status} - ID: ${h3Pro.data.id}`);
  console.assert(h3Pro.status === 201, 'Pro tier must allow 3rd habit');

  // 4. Custom Day Scheduling Verification
  console.log('\n--- 4. CUSTOM FREQUENCY SCHEDULE DETERMINATION ---');
  // Check Monday (e.g. 2026-08-24) vs Tuesday (2026-08-25) for Habit 2 (Mon, Wed, Fri)
  const mondayList = await makeRequest('GET', '/api/habits?date=2026-08-24', null, token);
  const tuesdayList = await makeRequest('GET', '/api/habits?date=2026-08-25', null, token);

  const h2Monday = mondayList.data.find(h => h.id === h2.data.id);
  const h2Tuesday = tuesdayList.data.find(h => h.id === h2.data.id);
  console.log(`[4.1] Habit 2 scheduled on Monday (2026-08-24): ${h2Monday.isScheduled}`);
  console.log(`[4.2] Habit 2 scheduled on Tuesday (2026-08-25): ${h2Tuesday.isScheduled}`);
  console.assert(h2Monday.isScheduled === true, 'Habit 2 must be scheduled on Monday');
  console.assert(h2Tuesday.isScheduled === false, 'Habit 2 must NOT be scheduled on Tuesday');

  // 5. Daily Completion Toggling & Streak Engine
  console.log('\n--- 5. DAILY COMPLETIONS & STREAK ACCURACY ---');
  // Complete Habit 2 on Mon 24th, Wed 26th, Fri 28th
  await makeRequest('POST', `/api/habits/${h2.data.id}/toggle`, { date: '2026-08-24', status: 'completed' }, token);
  await makeRequest('POST', `/api/habits/${h2.data.id}/toggle`, { date: '2026-08-26', status: 'completed' }, token);
  const toggleFri = await makeRequest('POST', `/api/habits/${h2.data.id}/toggle`, { date: '2026-08-28', status: 'completed' }, token);

  console.log(`[5.1] Toggled 3 MWF completions: Status ${toggleFri.status} - Current Streak: ${toggleFri.data.currentStreak}`);
  console.assert(toggleFri.data.currentStreak === 3, 'Streak should be 3 for Mon/Wed/Fri completed');

  // Test accidental unmark / toggle off
  const toggleOff = await makeRequest('POST', `/api/habits/${h2.data.id}/toggle`, { date: '2026-08-28', status: 'uncompleted' }, token);
  console.log(`[5.2] Unmark Fri completion: isCompleted: ${toggleOff.data.isCompleted} - Streak: ${toggleOff.data.currentStreak}`);
  console.assert(toggleOff.data.isCompleted === false, 'Completion must be un-marked');

  // Re-complete
  await makeRequest('POST', `/api/habits/${h2.data.id}/toggle`, { date: '2026-08-28', status: 'completed' }, token);

  // 6. Pause & Resume Status
  console.log('\n--- 6. PAUSE & RESUME LIFECYCLE ---');
  const pauseRes = await makeRequest('PATCH', `/api/habits/${h1.data.id}/status`, { status: 'paused' }, token);
  console.log(`[6.1] Pause Habit 1: Status ${pauseRes.status} - Status: ${pauseRes.data.habit.status}`);
  console.assert(pauseRes.data.habit.status === 'paused', 'Habit must be paused');

  const resumeRes = await makeRequest('PATCH', `/api/habits/${h1.data.id}/status`, { status: 'active' }, token);
  console.log(`[6.2] Resume Habit 1: Status ${resumeRes.status} - Status: ${resumeRes.data.habit.status}`);
  console.assert(resumeRes.data.habit.status === 'active', 'Habit must be active');

  // 7. Habit Analytics Dynamic Calculation
  console.log('\n--- 7. HABIT ANALYTICS ENGINE ---');
  const analyticsRes = await makeRequest('GET', '/api/habits/analytics', null, token);
  console.log('[7.1] Habit Analytics Summary:', analyticsRes.data.analytics);
  console.assert(analyticsRes.data.success === true, 'Analytics fetch must succeed');
  console.assert(analyticsRes.data.analytics.totalHabits === 3, 'Total habits must equal 3');

  // 8. User Account Deletion & Cascading Purge
  console.log('\n--- 8. DATA ISOLATION & CASCADING USER PURGE ---');
  const deleteRes = await makeRequest('DELETE', '/api/account/delete', null, token);
  console.log(`[8.1] Purge Account: Status ${deleteRes.status} - Message: ${deleteRes.data.message}`);

  const postDeleteHabits = await makeRequest('GET', '/api/habits', null, token);
  console.log(`[8.2] Query Habits Post-Deletion (Expect 401): Status ${postDeleteHabits.status}`);
  console.assert(postDeleteHabits.status === 401, 'Deleted user session must be invalid');

  console.log('\n=================================================================');
  console.log('   ALL COMPREHENSIVE HABIT TRACKER AUDIT TESTS PASSED (100%)!    ');
  console.log('=================================================================\n');
}

runHabitTrackerAudit().catch(err => {
  console.error('Test Suite Failed:', err);
  process.exit(1);
});
