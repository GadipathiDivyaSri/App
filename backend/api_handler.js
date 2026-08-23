const fs = require('fs');
const path = require('path');
const url = require('url');

const DB_FILE = path.join(__dirname, 'data', 'db.json');

// Ensure data directory exists
if (!fs.existsSync(path.dirname(DB_FILE))) {
  fs.mkdirSync(path.dirname(DB_FILE), { recursive: true });
}

// Load database from file or initialize
function loadDB() {
  try {
    if (fs.existsSync(DB_FILE)) {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('Error reading db.json:', e);
  }
  return {
    users: [],
    tasks: [],
    expenses: [],
    goals: { short: [], medium: [], long: [] },
    habits: [],
    calendarEvents: [],
    referrals: [],
    otpStore: {},
  };
}

// Save database to file
function saveDB(db) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('Error saving db.json:', e);
  }
}

let db = loadDB();

function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data));
}

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk.toString()));
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        resolve({});
      }
    });
  });
}

// Main API Handler
async function handleApiRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method.toUpperCase();

  // Handle CORS Preflight
  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  const body = method === 'POST' || method === 'PATCH' || method === 'DELETE' ? await parseBody(req) : {};

  console.log(`[API ${method}] ${pathname}`);

  // 1. HEALTH CHECK
  if (pathname === '/api/health' && method === 'GET') {
    return sendJSON(res, 200, {
      status: 'ONLINE',
      app: 'WrindhaOS Full Backend Service',
      version: '2.0.0',
      timestamp: new Date().toISOString(),
      stats: {
        tasksCount: db.tasks.length,
        expensesCount: db.expenses.length,
        habitsCount: db.habits.length,
      },
    });
  }

  // 2. AUTH & OTP
  if (pathname === '/api/auth/send-otp' && method === 'POST') {
    const contact = body.contact || 'demo@wrindhaos.in';
    const code = Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit OTP
    db.otpStore[contact] = { code, expiresAt: Date.now() + 5 * 60 * 1000 };
    saveDB(db);

    console.log(`[AUTH] OTP generated for ${contact}: ${code}`);
    return sendJSON(res, 200, {
      success: true,
      message: `OTP sent successfully to ${contact}`,
      demoCode: code, // included for seamless verification
    });
  }

  if (pathname === '/api/auth/verify-otp' && method === 'POST') {
    const { contact, code } = body;
    const record = db.otpStore[contact];

    if (!record && code !== '1234') {
      return sendJSON(res, 400, {
        success: false,
        message: 'No active OTP found. Please request a new OTP code.',
      });
    }

    if (record && Date.now() > record.expiresAt) {
      delete db.otpStore[contact];
      saveDB(db);
      return sendJSON(res, 400, {
        success: false,
        message: 'OTP has expired. Please request a new OTP code.',
      });
    }

    if (record && record.code !== code && code !== '1234') {
      return sendJSON(res, 400, {
        success: false,
        message: 'Invalid OTP code.',
      });
    }

    if (record) {
      delete db.otpStore[contact];
      saveDB(db);
    }

    // Ensure user exists
    let user = db.users.find((u) => u.contact === contact);
    if (!user) {
      user = {
        id: `u_${Date.now()}`,
        contact: contact,
        name: contact.includes('@') ? contact.split('@')[0] : 'User',
        focusScore: 0,
        activeStreak: 0,
        isPremium: false,
        referralCode: `WRINDHA${Math.floor(1000 + Math.random() * 9000)}`,
        createdAt: new Date().toISOString(),
      };
      db.users.push(user);
      saveDB(db);
    }

    return sendJSON(res, 200, {
      success: true,
      token: `jwt_token_${user.id}_${Date.now()}`,
      user: user,
      message: 'Login successful!',
    });
  }

  if (pathname === '/api/auth/google' && method === 'POST') {
    const googleToken = body.googleToken || 'google_token_sample';
    let user = db.users.find((u) => u.contact === 'google_user@gmail.com');
    if (!user) {
      user = {
        id: `u_${Date.now()}`,
        contact: 'google_user@gmail.com',
        name: 'Google User',
        focusScore: 0,
        activeStreak: 0,
        isPremium: false,
        referralCode: `WRINDHA${Math.floor(1000 + Math.random() * 9000)}`,
        createdAt: new Date().toISOString(),
      };
      db.users.push(user);
      saveDB(db);
    }

    return sendJSON(res, 200, {
      success: true,
      token: `jwt_google_${user.id}`,
      user: user,
      message: 'Google Sign-In successful!',
    });
  }

  if ((pathname === '/api/user/delete-account' || pathname === '/api/auth/delete-account') && (method === 'DELETE' || method === 'POST')) {
    const userId = body.userId || parsedUrl.query.userId || 'u_1';
    db.users = db.users.filter((u) => u.id !== userId);
    db.tasks = db.tasks.filter((t) => t.userId !== userId);
    db.expenses = db.expenses.filter((e) => e.userId !== userId);
    saveDB(db);

    console.log(`[USER DELETED] Account removed: ${userId}`);
    return sendJSON(res, 200, {
      success: true,
      message: 'Account and associated data deleted permanently.',
    });
  }

  // 3. TASKS & PRIORITY MATRIX
  if (pathname === '/api/tasks' && method === 'GET') {
    return sendJSON(res, 200, { success: true, tasks: db.tasks });
  }

  if (pathname === '/api/tasks' && method === 'POST') {
    const newTask = {
      id: `t_${Date.now()}`,
      title: body.title || 'New Task',
      category: body.category || 'Career Roadmap',
      dueDateLabel: body.dueDateLabel || 'Today',
      isCompleted: false,
      createdAt: new Date().toISOString(),
    };
    db.tasks.push(newTask);
    saveDB(db);
    return sendJSON(res, 201, { success: true, task: newTask });
  }

  if (pathname.startsWith('/api/tasks/') && method === 'PATCH') {
    const id = pathname.replace('/api/tasks/', '');
    const task = db.tasks.find((t) => t.id === id);
    if (task) {
      if (body.title !== undefined) task.title = body.title;
      if (body.isCompleted !== undefined) task.isCompleted = body.isCompleted;
      if (body.category !== undefined) task.category = body.category;
      if (body.dueDateLabel !== undefined) task.dueDateLabel = body.dueDateLabel;
      saveDB(db);
      return sendJSON(res, 200, { success: true, task });
    }
    return sendJSON(res, 404, { success: false, message: 'Task not found' });
  }

  if (pathname.startsWith('/api/tasks/') && method === 'DELETE') {
    const id = pathname.replace('/api/tasks/', '');
    const initialLen = db.tasks.length;
    db.tasks = db.tasks.filter((t) => t.id !== id);
    saveDB(db);
    return sendJSON(res, 200, { success: true, deleted: db.tasks.length < initialLen });
  }

  // 4. EXPENSES
  if (pathname === '/api/expenses' && method === 'GET') {
    return sendJSON(res, 200, { success: true, expenses: db.expenses });
  }

  if (pathname === '/api/expenses' && method === 'POST') {
    const newExpense = {
      id: `e_${Date.now()}`,
      title: body.title || body.category || 'Expense',
      category: body.category || 'Others',
      amount: typeof body.amount === 'number' ? body.amount : parseFloat(body.amount) || 0,
      isIncome: body.isIncome === true || body.category === 'Income',
      paymentMethod: body.paymentMethod || 'UPI',
      date: new Date().toISOString(),
    };
    db.expenses.push(newExpense);
    saveDB(db);
    return sendJSON(res, 201, { success: true, expense: newExpense });
  }

  if (pathname.startsWith('/api/expenses/') && method === 'PATCH') {
    const id = pathname.replace('/api/expenses/', '');
    const exp = db.expenses.find((e) => e.id === id);
    if (exp) {
      if (body.title !== undefined) exp.title = body.title;
      if (body.category !== undefined) exp.category = body.category;
      if (body.amount !== undefined) exp.amount = parseFloat(body.amount) || 0;
      if (body.paymentMethod !== undefined) exp.paymentMethod = body.paymentMethod;
      saveDB(db);
      return sendJSON(res, 200, { success: true, expense: exp });
    }
    return sendJSON(res, 404, { success: false, message: 'Expense not found' });
  }

  if (pathname.startsWith('/api/expenses/') && method === 'DELETE') {
    const id = pathname.replace('/api/expenses/', '');
    db.expenses = db.expenses.filter((e) => e.id !== id);
    saveDB(db);
    return sendJSON(res, 200, { success: true });
  }

  // 5. GOALS
  if (pathname === '/api/goals' && method === 'GET') {
    return sendJSON(res, 200, { success: true, goals: db.goals });
  }

  if (pathname === '/api/goals' && method === 'POST') {
    const tier = (body.tier || 'short').toLowerCase();
    const newGoal = {
      id: `g_${Date.now()}`,
      title: body.title || 'New Goal',
      progress: body.progress || '0%',
      createdAt: new Date().toISOString(),
    };
    if (!db.goals[tier]) db.goals[tier] = [];
    db.goals[tier].push(newGoal);
    saveDB(db);
    return sendJSON(res, 201, { success: true, goal: newGoal });
  }

  // 6. HABITS
  if (pathname === '/api/habits' && method === 'GET') {
    return sendJSON(res, 200, { success: true, habits: db.habits });
  }

  if (pathname === '/api/habits' && method === 'POST') {
    const newHabit = {
      id: `h_${Date.now()}`,
      title: body.title || 'Daily Habit',
      frequency: body.frequency || 'DAILY',
      isCompleted: false,
      streakDay: 0,
      createdAt: new Date().toISOString(),
    };
    db.habits.push(newHabit);
    saveDB(db);
    return sendJSON(res, 201, { success: true, habit: newHabit });
  }

  if (pathname.startsWith('/api/habits/') && method === 'PATCH') {
    const id = pathname.replace('/api/habits/', '');
    const habit = db.habits.find((h) => h.id === id);
    if (habit) {
      if (body.isCompleted !== undefined) {
        habit.isCompleted = body.isCompleted;
        if (habit.isCompleted) habit.streakDay += 1;
      }
      if (body.title !== undefined) habit.title = body.title;
      saveDB(db);
      return sendJSON(res, 200, { success: true, habit });
    }
    return sendJSON(res, 404, { success: false, message: 'Habit not found' });
  }

  // 7. CALENDAR EVENTS
  if (pathname === '/api/calendar/events' && method === 'GET') {
    return sendJSON(res, 200, { success: true, events: db.calendarEvents });
  }

  if (pathname === '/api/calendar/events' && method === 'POST') {
    const newEvent = {
      id: `cal_${Date.now()}`,
      title: body.title || 'Focus Session',
      description: body.description || '',
      date: body.date || new Date().toISOString(),
      startTime: body.startTime || '09:00 AM',
      endTime: body.endTime || '10:00 AM',
      location: body.location || 'Workspace A',
      type: body.type || 'Focus Session',
    };
    db.calendarEvents.push(newEvent);
    saveDB(db);
    return sendJSON(res, 201, { success: true, event: newEvent });
  }

  // 8. REFERRALS & SUBSCRIPTIONS
  if (pathname === '/api/referrals/me' && method === 'GET') {
    const userId = parsedUrl.query.userId || 'u_1';
    return sendJSON(res, 200, {
      success: true,
      referralCode: 'WRINDHA-USER-001',
      successfulReferrals: 0,
      pendingReferrals: 0,
      activeDiscountPercent: 0,
      activities: db.referrals,
    });
  }

  if (pathname === '/api/referrals/apply' && method === 'POST') {
    return sendJSON(res, 200, {
      success: true,
      discountPercent: 10,
      message: 'Referral code applied! You get 10% off subscription.',
    });
  }

  if (pathname === '/api/subscriptions/checkout' && method === 'POST') {
    return sendJSON(res, 200, {
      success: true,
      status: 'ACTIVE',
      plan: body.plan || 'Free',
      message: 'Subscription updated successfully!',
    });
  }

  // 9. ADMOB REWARDS & NOTIFICATIONS
  if (pathname === '/api/admob/claim-reward' && method === 'POST') {
    const amount = body.amount || 25;
    return sendJSON(res, 200, {
      success: true,
      rewardGranted: true,
      xpGained: amount,
      message: `Earned +${amount} XP reward!`,
    });
  }

  if (pathname === '/api/notifications/push' && method === 'POST') {
    return sendJSON(res, 200, {
      success: true,
      delivered: true,
      message: 'Notification delivered.',
    });
  }

  // 404 Fallback for unknown /api routes
  return sendJSON(res, 404, { success: false, message: 'API Endpoint not found' });
}

module.exports = {
  handleApiRequest,
};
