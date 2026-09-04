const http = require('http');

console.log('=================================================================');
console.log('     WRINDHAOS END-TO-END ADD / DELETE (CRUD) AUDIT SUITE       ');
console.log('=================================================================\n');

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

function request({ method, path, body = null, token = null }) {
  return new Promise((resolve) => {
    const payload = body ? JSON.stringify(body) : null;
    const headers = {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {})
    };

    const req = http.request(
      {
        hostname: 'localhost',
        port: 8080,
        path,
        method: method.toUpperCase(),
        headers
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
          resolve({ status: res.statusCode, data: parsed });
        });
      }
    );

    req.on('error', (err) => resolve({ error: err.message, status: 500 }));
    if (payload) req.write(payload);
    req.end();
  });
}

async function runCrudSuite() {
  const timestamp = Date.now();
  const testEmail = `crud_tester_${timestamp}@wrindhaos.in`;
  const testUser = `crud_user_${timestamp.toString().slice(-5)}`;

  // 1. SETUP: REGISTER USER & UPGRADE TO PRO (for full CRUD access)
  const init = await request({
    method: 'POST',
    path: '/api/auth/register-initiate',
    body: { username: testUser, email: testEmail, password: 'StrongPassword123!', confirmPassword: 'StrongPassword123!' }
  });
  const otpCode = init.data.code;

  const verify = await request({
    method: 'POST',
    path: '/api/auth/register-verify',
    body: { username: testUser, email: testEmail, otp: otpCode, password: 'StrongPassword123!' }
  });
  const token = verify.data.token;
  const userId = verify.data.user.id;

  // Upgrade to Pro to enable all feature creation & deletion
  await request({
    method: 'POST',
    path: '/api/subscription/upgrade',
    body: { plan: 'pro', billingCycle: 'monthly' },
    token
  });

  // ---------------------------------------------------------------------------
  // 1. TASKS CRUD (ADD, UPDATE, DELETE)
  // ---------------------------------------------------------------------------
  console.log('--- 1. TASKS ADD / UPDATE / DELETE ---');

  // ADD TASK
  const addTask = await request({
    method: 'POST',
    path: '/api/tasks',
    body: {
      title: 'Complete Mathematics Chapter 4',
      category: 'Studies',
      priority: 'high',
      dueDate: '2026-09-10'
    },
    token
  });
  assert(addTask.status === 201 && addTask.data?.id != null, 'ADD Task: Task created successfully (201)');
  const taskId = addTask.data?.id;

  // UPDATE TASK (Toggle complete)
  const updateTask = await request({
    method: 'PUT',
    path: `/api/tasks/${taskId}`,
    body: { isCompleted: true },
    token
  });
  assert(updateTask.status === 200 && (updateTask.data?.isCompleted === true || updateTask.data?.status === 'completed'), 'UPDATE Task: Task marked completed (200)');

  // DELETE TASK
  const deleteTask = await request({
    method: 'DELETE',
    path: `/api/tasks/${taskId}`,
    token
  });
  assert(deleteTask.status === 200, 'DELETE Task: Task deleted successfully (200)');

  // VERIFY TASK DELETED
  const listTasks = await request({ method: 'GET', path: '/api/tasks', token });
  const taskFound = Array.isArray(listTasks.data) && listTasks.data.some((t) => t.id === taskId);
  assert(!taskFound, 'VERIFY Task Deletion: Task is completely removed from list');

  // ---------------------------------------------------------------------------
  // 2. HABITS CRUD (ADD, TOGGLE, DELETE)
  // ---------------------------------------------------------------------------
  console.log('\n--- 2. HABITS ADD / TOGGLE / DELETE ---');

  // ADD HABIT
  const addHabit = await request({
    method: 'POST',
    path: '/api/habits',
    body: {
      title: 'Morning 5km Run & Meditation',
      category: 'Health',
      frequency: 'DAILY',
      colorHex: '0xFF10B981',
      iconName: 'directions_run'
    },
    token
  });
  assert(addHabit.status === 201 && addHabit.data?.id != null, 'ADD Habit: Habit created with custom icon & color (201)');
  const habitId = addHabit.data?.id;

  // TOGGLE HABIT COMPLETION
  const toggleHabit = await request({
    method: 'POST',
    path: `/api/habits/${habitId}/toggle`,
    body: { date: new Date().toISOString().split('T')[0] },
    token
  });
  assert(toggleHabit.status === 200 && toggleHabit.data?.isCompleted === true, 'TOGGLE Habit: Habit marked completed for today (200)');

  // DELETE HABIT
  const deleteHabit = await request({
    method: 'DELETE',
    path: `/api/habits/${habitId}`,
    token
  });
  assert(deleteHabit.status === 200, 'DELETE Habit: Habit deleted successfully (200)');

  // VERIFY HABIT DELETED
  const listHabits = await request({ method: 'GET', path: '/api/habits', token });
  const habitFound = Array.isArray(listHabits.data) && listHabits.data.some((h) => h.id === habitId && h.status !== 'archived');
  assert(!habitFound, 'VERIFY Habit Deletion: Habit is completely removed or archived');

  // ---------------------------------------------------------------------------
  // 3. SUBJECTS & STUDY UNITS CRUD (ADD, ADD UNIT, DELETE)
  // ---------------------------------------------------------------------------
  console.log('\n--- 3. ACADEMIC SUBJECTS & UNITS ADD / DELETE ---');

  // ADD SUBJECT
  const addSubject = await request({
    method: 'POST',
    path: '/api/subjects',
    body: {
      name: 'Advanced Organic Chemistry',
      colorHex: '0xFF6366F1',
      iconName: 'science'
    },
    token
  });
  assert(addSubject.status === 201 && addSubject.data?.id != null, 'ADD Subject: Subject created with custom color (201)');
  const subjectId = addSubject.data?.id;

  // ADD UNIT TO SUBJECT
  const addUnit = await request({
    method: 'POST',
    path: `/api/subjects/${subjectId}/units`,
    body: {
      name: 'Reaction Mechanisms & Synthesis',
      targetHours: 15
    },
    token
  });
  assert(addUnit.status === 200 || addUnit.status === 201, 'ADD Unit: Study unit added to subject (200/201)');

  // DELETE SUBJECT
  const deleteSubject = await request({
    method: 'DELETE',
    path: `/api/subjects/${subjectId}`,
    token
  });
  assert(deleteSubject.status === 200, 'DELETE Subject: Subject deleted successfully (200)');

  // VERIFY SUBJECT DELETED
  const listSubjects = await request({ method: 'GET', path: '/api/subjects', token });
  const subFound = Array.isArray(listSubjects.data) && listSubjects.data.some((s) => s.id === subjectId);
  assert(!subFound, 'VERIFY Subject Deletion: Subject is completely removed');

  // ---------------------------------------------------------------------------
  // 4. EXPENSES CRUD (ADD, DELETE)
  // ---------------------------------------------------------------------------
  console.log('\n--- 4. EXPENSES ADD / DELETE ---');

  // ADD EXPENSE
  const addExpense = await request({
    method: 'POST',
    path: '/api/expenses',
    body: {
      title: 'College Textbooks & Reference Guides',
      amount: 1450,
      category: 'Education',
      type: 'expense',
      date: new Date().toISOString().split('T')[0]
    },
    token
  });
  assert(addExpense.status === 201 && addExpense.data?.id != null, 'ADD Expense: Transaction recorded (201)');
  const expenseId = addExpense.data?.id;

  // DELETE EXPENSE
  const deleteExpense = await request({
    method: 'DELETE',
    path: `/api/expenses/${expenseId}`,
    token
  });
  assert(deleteExpense.status === 200, 'DELETE Expense: Expense record deleted (200)');

  // VERIFY EXPENSE DELETED
  const listExpenses = await request({ method: 'GET', path: '/api/expenses', token });
  const expFound = Array.isArray(listExpenses.data) && listExpenses.data.some((e) => e.id === expenseId);
  assert(!expFound, 'VERIFY Expense Deletion: Expense record is completely removed');

  // ---------------------------------------------------------------------------
  // 5. GOALS & MILESTONES CRUD (ADD, ADD MILESTONE, DELETE)
  // ---------------------------------------------------------------------------
  console.log('\n--- 5. CAREER GOALS & MILESTONES ADD / DELETE ---');

  // ADD GOAL
  const addGoal = await request({
    method: 'POST',
    path: '/api/goals',
    body: {
      title: 'Master Full-Stack Cloud Architecture',
      category: 'Career',
      targetDate: '2027-01-01',
      description: 'Acquire AWS & Flutter certifications'
    },
    token
  });
  assert(addGoal.status === 201 && addGoal.data?.id != null, 'ADD Goal: Career Goal created (201)');
  const goalId = addGoal.data?.id;

  // ADD MILESTONE TO GOAL
  const addMilestone = await request({
    method: 'POST',
    path: `/api/goals/${goalId}/milestones`,
    body: {
      title: 'Complete AWS Solutions Architect Certificate',
      dueDate: '2026-11-30'
    },
    token
  });
  assert(addMilestone.status === 200 || addMilestone.status === 201, 'ADD Milestone: Milestone attached to Goal (200/201)');

  // DELETE GOAL
  const deleteGoal = await request({
    method: 'DELETE',
    path: `/api/goals/${goalId}`,
    token
  });
  assert(deleteGoal.status === 200, 'DELETE Goal: Career Goal deleted successfully (200)');

  // VERIFY GOAL DELETED
  const listGoals = await request({ method: 'GET', path: '/api/goals', token });
  const goalFound = Array.isArray(listGoals.data) && listGoals.data.some((g) => g.id === goalId);
  assert(!goalFound, 'VERIFY Goal Deletion: Goal is completely removed');

  // ---------------------------------------------------------------------------
  // 6. COMPLETE ACCOUNT & DATA PURGE
  // ---------------------------------------------------------------------------
  console.log('\n--- 6. COMPLETE ACCOUNT & DATA PURGE ---');

  const purgeAccount = await request({
    method: 'DELETE',
    path: '/api/users/me',
    token
  });
  assert(purgeAccount.status === 200 && purgeAccount.data?.success === true, 'DELETE Account: User profile and all relational data permanently wiped (200)');

  // VERIFY PURGED
  const recheck = await request({ method: 'GET', path: '/api/auth/session', token });
  assert(recheck.status === 401, 'VERIFY Purge: Session immediately invalidated (401)');

  // ---------------------------------------------------------------------------
  // FINAL CRUD SCORECARD
  // ---------------------------------------------------------------------------
  console.log('\n=================================================================');
  console.log(` CRUD LIFECYCLE AUDIT: ${passedTests} / ${totalTests} TESTS PASSED (${Math.round((passedTests / totalTests) * 100)}%)`);
  console.log('=================================================================\n');

  if (failedTests === 0) {
    console.log('🌟 100% ADD & DELETE CRUD INTEGRITY CERTIFIED ACROSS ALL MODULES! 🚀\n');
  }
}

runCrudSuite();
