const path = require('path');
const assert = require('assert');
const { DatabaseManager, hashPassword, verifyPassword } = require(path.join(__dirname, '../backend/db_manager.js'));

async function testBackendDatabaseMapping() {
  console.log('==================================================');
  console.log(' 🧪 TESTING BACKEND DATABASE MAPPING & ENDPOINTS  ');
  console.log('==================================================\n');

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

  const testEmail = `integ_test_${Date.now()}@wrindhaos.app`;
  const testUser = `integ_usr_${Date.now()}`;
  const passHash = hashPassword('TestPass@123');

  try {
    // 1. Create User Profile
    console.log('--- TEST 1: User Profile CRUD ---');
    const createdUser = await DatabaseManager.createUser({
      username: testUser,
      email: testEmail,
      display_name: 'Integration Test User',
      password_hash: passHash,
    });
    if (createdUser && createdUser.id && createdUser.email === testEmail) {
      logPass('Created user profile in Supabase database');
    } else {
      logFail('Failed to create user profile', createdUser);
    }

    const fetchedUser = await DatabaseManager.getUserByEmailOrUsername(testEmail);
    if (fetchedUser && fetchedUser.id === createdUser.id && verifyPassword('TestPass@123', fetchedUser.password_hash)) {
      logPass('Fetched user by email and verified password hash');
    } else {
      logFail('Failed to fetch user or verify password hash', fetchedUser);
    }

    const userId = createdUser.id;

    // 2. Habits & Habit Logs
    console.log('\n--- TEST 2: Habits & Habit Logs CRUD ---');
    const habit = await DatabaseManager.createHabit(userId, {
      title: 'Daily Meditation',
      category: 'Health',
      frequency: 'daily',
      color_hex: '#10B981',
    });
    if (habit && habit.id && habit.title === 'Daily Meditation') {
      logPass('Created habit in habits table');
    } else {
      logFail('Failed to create habit', habit);
    }

    const overviewBefore = await DatabaseManager.getHabitOverview(userId);
    const toggleRes = await DatabaseManager.toggleHabitCompletion(userId, habit.id);
    if (toggleRes && toggleRes.isCompleted === true) {
      logPass('Toggled habit completion (inserted into habit_logs table)');
    } else {
      logFail('Failed to toggle habit completion', toggleRes);
    }

    const overviewAfter = await DatabaseManager.getHabitOverview(userId);
    if (overviewAfter && overviewAfter.completedCount === 1) {
      logPass('Habit overview correctly calculated completedCount from habit_logs');
    } else {
      logFail('Habit overview completedCount mismatch', overviewAfter);
    }

    // 3. Tasks
    console.log('\n--- TEST 3: Tasks CRUD ---');
    const task = await DatabaseManager.createTask(userId, {
      title: 'Complete System Architecture Review',
      category: 'Studies',
      priority: 1,
      due_at: new Date().toISOString(),
    });
    if (task && task.id && task.title === 'Complete System Architecture Review') {
      logPass('Created task in tasks table');
    } else {
      logFail('Failed to create task', task);
    }

    const updatedTask = await DatabaseManager.updateTask(userId, task.id, { is_completed: true });
    if (updatedTask && updatedTask.isCompleted === true) {
      logPass('Updated task completion status in tasks table');
    } else {
      logFail('Failed to update task', updatedTask);
    }

    // 4. Expenses
    console.log('\n--- TEST 4: Expenses CRUD ---');
    const expense = await DatabaseManager.createExpense(userId, {
      title: 'Books & Course Materials',
      amount: 45.00,
      category: 'Education',
      transaction_type: 'expense',
      occurred_at: new Date().toISOString(),
    });
    if (expense && expense.id && Number(expense.amount) === 45) {
      logPass('Created expense in expenses table');
    } else {
      logFail('Failed to create expense', expense);
    }

    // 5. Subjects & Study Items
    console.log('\n--- TEST 5: Subjects & Study Items CRUD ---');
    const subject = await DatabaseManager.createSubject(userId, {
      name: 'Computer Science 101',
      code: 'CS101',
      color_hex: '#0D5CE5',
      credits: 4,
    });
    if (subject && subject.id && subject.name === 'Computer Science 101') {
      logPass('Created subject in subjects table');
    } else {
      logFail('Failed to create subject', subject);
    }

    const studyItem = await DatabaseManager.createStudyItem(userId, {
      subject_id: subject.id,
      title: 'Read Chapter 4: Data Structures',
      type: 'READING',
    });
    if (studyItem && studyItem.id && studyItem.subjectId === subject.id) {
      logPass('Created study item linked to subject in study_items table');
    } else {
      logFail('Failed to create study item', studyItem);
    }

    // 6. Goals
    console.log('\n--- TEST 6: Goals CRUD ---');
    const goal = await DatabaseManager.createGoal(userId, {
      title: 'Master Flutter & Node.js Architecture',
      tier: 'short',
      category: 'Skills',
      target_date: '2026-12-31T00:00:00.000Z',
    });
    if (goal && goal.id && goal.title === 'Master Flutter & Node.js Architecture') {
      logPass('Created goal in goals table');
    } else {
      logFail('Failed to create goal', goal);
    }

    // 7. Calendar Events
    console.log('\n--- TEST 7: Calendar Events CRUD ---');
    const event = await DatabaseManager.createCalendarEvent(userId, {
      title: 'Team Architecture Sync',
      event_date: new Date().toISOString().split('T')[0],
      start_time: '14:00:00',
      end_time: '15:00:00',
    });
    if (event && event.id && event.title === 'Team Architecture Sync') {
      logPass('Created calendar event in calendar_events table');
    } else {
      logFail('Failed to create calendar event', event);
    }

    // 8. Journal Entries
    console.log('\n--- TEST 8: Journal Entries CRUD ---');
    const journal = await DatabaseManager.createJournalEntry(userId, {
      title: 'Daily Reflection',
      content: 'Productive day completing database optimization and backend mapping.',
      mood: 'accomplished',
    });
    if (journal && journal.id && journal.title === 'Daily Reflection') {
      logPass('Created journal entry in journal_entries table');
    } else {
      logFail('Failed to create journal entry', journal);
    }

    // Clean up test user
    console.log('\n--- CLEANUP TEST USER ---');
    await DatabaseManager.deleteUser(userId);
    logPass('Cleaned up test user profile and associated data');

    console.log('\n==================================================');
    console.log(` RESULTS: ${passed} PASSED, ${failed} FAILED`);
    console.log('==================================================\n');
  } catch (err) {
    console.error('Test Suite Error:', err);
  }
}

testBackendDatabaseMapping();
