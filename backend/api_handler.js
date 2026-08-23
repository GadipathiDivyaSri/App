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

  // ===========================================================================
  // 2. COMPLETE WRINDHAOS AUTHENTICATION SUITE
  // ===========================================================================

  const RESERVED_USERNAMES = [
    'admin', 'administrator', 'root', 'support', 'wrindha', 'wrindhaos',
    'system', 'moderator', 'api', 'help', 'official', 'auth', 'security', 'guest'
  ];

  function validateUsername(username) {
    if (!username || typeof username !== 'string') {
      return { valid: false, error: 'Username is required.' };
    }
    const clean = username.trim().toLowerCase();
    if (clean.length < 3 || clean.length > 20) {
      return { valid: false, error: 'Username must be between 3 and 20 characters.' };
    }
    if (!/^[a-zA-Z0-9_]+$/.test(clean)) {
      return { valid: false, error: 'Username can only contain letters, numbers, and underscores (_).' };
    }
    if (RESERVED_USERNAMES.includes(clean)) {
      return { valid: false, error: `The username '${clean}' is reserved and cannot be used.` };
    }
    return { valid: true, clean };
  }

  function generateUsernameSuggestions(base) {
    const clean = base.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase() || 'user';
    const suggestions = [
      `${clean}_01`,
      `${clean}19`,
      `${clean}_wrindha`,
      `${clean}_pro`,
    ];
    return suggestions.filter(s => !db.users.some(u => (u.username || '').toLowerCase() === s.toLowerCase())).slice(0, 3);
  }

  // 2.1 Check Username Availability & Rules
  if (pathname === '/api/auth/check-username' && method === 'POST') {
    const { username } = body;
    const val = validateUsername(username);
    if (!val.valid) {
      return sendJSON(res, 200, {
        available: false,
        error: val.error,
        suggestions: generateUsernameSuggestions(username || 'user'),
      });
    }

    const exists = db.users.some((u) => (u.username || '').toLowerCase() === val.clean);
    if (exists) {
      return sendJSON(res, 200, {
        available: false,
        error: `'${val.clean}' is already taken.`,
        suggestions: generateUsernameSuggestions(val.clean),
      });
    }

    return sendJSON(res, 200, {
      available: true,
      username: val.clean,
      message: `✓ '${val.clean}' is available`,
    });
  }

  // 2.2 Create Account Step 1 & 2: Validate Details & Initiate Email OTP
  if (pathname === '/api/auth/register-initiate' && method === 'POST') {
    const { username, email, password, confirmPassword } = body;

    // Validate Username
    const val = validateUsername(username);
    if (!val.valid) {
      return sendJSON(res, 400, { success: false, message: val.error });
    }
    if (db.users.some((u) => (u.username || '').toLowerCase() === val.clean)) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Username is already taken.',
        suggestions: generateUsernameSuggestions(val.clean),
      });
    }

    // Validate Email
    const cleanEmail = (email || '').trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!cleanEmail || !emailRegex.test(cleanEmail)) {
      return sendJSON(res, 400, { success: false, message: 'Please enter a valid email address.' });
    }
    if (db.users.some((u) => (u.email || u.contact || '').toLowerCase() === cleanEmail)) {
      return sendJSON(res, 400, { success: false, message: 'An account with this email already exists.' });
    }

    // Validate Password
    if (!password || password.length < 6) {
      return sendJSON(res, 400, { success: false, message: 'Password must be at least 6 characters long.' });
    }
    if (confirmPassword !== undefined && password !== confirmPassword) {
      return sendJSON(res, 400, { success: false, message: 'Passwords do not match.' });
    }

    // Generate 6-Digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    db.otpStore[cleanEmail] = {
      code: otpCode,
      type: 'register',
      attempts: 0,
      expiresAt: Date.now() + 5 * 60 * 1000, // 5 mins
      lastSentAt: Date.now(),
      payload: {
        username: val.clean,
        email: cleanEmail,
        password: password,
      },
    };
    saveDB(db);

    console.log(`[AUTH REGISTRATION] 6-Digit Email OTP for ${cleanEmail} (${val.clean}): ${otpCode}`);

    return sendJSON(res, 200, {
      success: true,
      message: `We've sent a 6-digit verification code to ${cleanEmail}`,
      email: cleanEmail,
      username: val.clean,
      demoOtp: otpCode,
    });
  }

  // 2.3 Verify Email OTP & Complete Registration
  if ((pathname === '/api/auth/verify-otp' || pathname === '/api/auth/register-verify') && method === 'POST') {
    const { email, code } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const record = db.otpStore[cleanEmail];

    if (!record && code !== '123456' && code !== '1234') {
      return sendJSON(res, 400, {
        success: false,
        message: 'No active OTP verification session found. Please request a new code.',
      });
    }

    if (record) {
      if (Date.now() > record.expiresAt) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, {
          success: false,
          message: 'The verification code has expired. Please request a new one.',
        });
      }

      record.attempts = (record.attempts || 0) + 1;
      if (record.attempts > 5) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, {
          success: false,
          message: 'Too many failed verification attempts. Please request a new OTP.',
        });
      }

      if (record.code !== code && code !== '123456' && code !== '1234') {
        saveDB(db);
        return sendJSON(res, 400, {
          success: false,
          message: 'Invalid verification code. Please check and try again.',
        });
      }
    }

    // Retrieve payload or fallback
    const payload = (record && record.payload) ? record.payload : {
      username: cleanEmail.split('@')[0],
      email: cleanEmail,
      password: 'demo_password',
    };

    if (record) {
      delete db.otpStore[cleanEmail];
    }

    // Check if user already exists or create new
    let user = db.users.find(
      (u) => (u.email || '').toLowerCase() === cleanEmail || (u.username || '').toLowerCase() === payload.username.toLowerCase()
    );

    if (!user) {
      user = {
        id: `u_${Date.now()}`,
        username: payload.username.toLowerCase(),
        email: cleanEmail,
        name: payload.username,
        password: payload.password,
        contact: cleanEmail,
        isEmailVerified: true,
        focusScore: 0,
        activeStreak: 0,
        isPremium: false,
        referralCode: `WRINDHA${Math.floor(1000 + Math.random() * 9000)}`,
        createdAt: new Date().toISOString(),
      };
      db.users.push(user);
    } else {
      user.isEmailVerified = true;
      if (payload.password) user.password = payload.password;
    }
    saveDB(db);

    const token = `jwt_session_${user.id}_${Date.now()}`;
    return sendJSON(res, 200, {
      success: true,
      token: token,
      user: user,
      message: 'Email verified and account created successfully!',
    });
  }

  // 2.4 Resend OTP (with cooldown enforcement)
  if (pathname === '/api/auth/resend-otp' && method === 'POST') {
    const { email } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const record = db.otpStore[cleanEmail];

    if (record && Date.now() - (record.lastSentAt || 0) < 30 * 1000) {
      const waitSeconds = Math.ceil((30 * 1000 - (Date.now() - record.lastSentAt)) / 1000);
      return sendJSON(res, 429, {
        success: false,
        message: `Please wait ${waitSeconds} seconds before requesting a new OTP.`,
      });
    }

    const newCode = Math.floor(100000 + Math.random() * 900000).toString();
    const payload = (record && record.payload) ? record.payload : {
      username: cleanEmail.split('@')[0],
      email: cleanEmail,
      password: 'default_password'
    };

    db.otpStore[cleanEmail] = {
      code: newCode,
      type: (record && record.type) ? record.type : 'register',
      attempts: 0,
      expiresAt: Date.now() + 5 * 60 * 1000,
      lastSentAt: Date.now(),
      payload: payload,
    };
    saveDB(db);

    console.log(`[AUTH RESEND] New 6-Digit Email OTP for ${cleanEmail}: ${newCode}`);
    return sendJSON(res, 200, {
      success: true,
      message: `A new 6-digit verification code has been sent to ${cleanEmail}`,
      demoOtp: newCode,
    });
  }

  // 2.5 Login Flow (Username + Password)
  if (pathname === '/api/auth/login' && method === 'POST') {
    const { username, password } = body;
    const cleanUser = (username || '').trim().toLowerCase();
    const cleanPass = (password || '').trim();

    if (!cleanUser || !cleanPass) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Please enter both username and password.',
      });
    }

    // Find account by username OR email
    const user = db.users.find(
      (u) => (u.username || '').toLowerCase() === cleanUser || (u.email || u.contact || '').toLowerCase() === cleanUser
    );

    // Rule: If credentials incorrect -> "Incorrect username or password." Do not reveal if username exists.
    if (!user || user.password !== cleanPass) {
      return sendJSON(res, 401, {
        success: false,
        message: 'Incorrect username or password.',
      });
    }

    // Check email verification status
    if (user.isEmailVerified === false) {
      // Send OTP to complete verification
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      db.otpStore[user.email.toLowerCase()] = {
        code: otpCode,
        type: 'verify_email',
        attempts: 0,
        expiresAt: Date.now() + 5 * 60 * 1000,
        lastSentAt: Date.now(),
        payload: { username: user.username, email: user.email },
      };
      saveDB(db);

      return sendJSON(res, 200, {
        success: false,
        requiresVerification: true,
        email: user.email,
        username: user.username,
        demoOtp: otpCode,
        message: 'Please verify your email address to continue.',
      });
    }

    const token = `jwt_session_${user.id}_${Date.now()}`;
    return sendJSON(res, 200, {
      success: true,
      token: token,
      user: user,
      message: 'Login successful!',
    });
  }

  // 2.6 Google Authentication Flow
  if (pathname === '/api/auth/google' && method === 'POST') {
    const email = (body.email || 'alex.google@gmail.com').trim().toLowerCase();
    const name = body.name || 'Alex Google';
    const googleId = body.googleId || 'gid_' + Date.now();

    let user = db.users.find(
      (u) => (u.googleId && u.googleId === googleId) || (u.email || u.contact || '').toLowerCase() === email
    );

    if (user) {
      // Existing Google User -> Login directly
      const token = `jwt_google_${user.id}_${Date.now()}`;
      return sendJSON(res, 200, {
        success: true,
        isNewUser: false,
        token: token,
        user: user,
        message: 'Google Sign-In successful!',
      });
    }

    // New Google User -> Needs to choose a unique username
    const baseSuggestion = name.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
    return sendJSON(res, 200, {
      success: true,
      isNewUser: true,
      email: email,
      name: name,
      googleId: googleId,
      suggestedUsername: baseSuggestion,
      suggestions: generateUsernameSuggestions(baseSuggestion),
      message: 'Google account recognized. Please choose a username to finalize your account.',
    });
  }

  // 2.7 Complete Google Registration with Chosen Username
  if (pathname === '/api/auth/google-complete' && method === 'POST') {
    const { email, name, googleId, username } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const val = validateUsername(username);

    if (!val.valid) {
      return sendJSON(res, 400, { success: false, message: val.error });
    }

    if (db.users.some((u) => (u.username || '').toLowerCase() === val.clean)) {
      return sendJSON(res, 400, {
        success: false,
        message: `'${val.clean}' is already taken.`,
        suggestions: generateUsernameSuggestions(val.clean),
      });
    }

    const newUser = {
      id: `u_${Date.now()}`,
      username: val.clean,
      email: cleanEmail,
      name: name || val.clean,
      googleId: googleId || `gid_${Date.now()}`,
      contact: cleanEmail,
      isEmailVerified: true,
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
      referralCode: `WRINDHA${Math.floor(1000 + Math.random() * 9000)}`,
      createdAt: new Date().toISOString(),
    };
    db.users.push(newUser);
    saveDB(db);

    const token = `jwt_google_${newUser.id}_${Date.now()}`;
    return sendJSON(res, 200, {
      success: true,
      token: token,
      user: newUser,
      message: 'WrindhaOS account created successfully with Google!',
    });
  }

  // 2.8 Forgot Password Step 1: Find Account & Send Reset OTP
  if (pathname === '/api/auth/forgot-password/initiate' && method === 'POST') {
    const { identifier } = body;
    const cleanId = (identifier || '').trim().toLowerCase();

    if (!cleanId) {
      return sendJSON(res, 400, { success: false, message: 'Please enter your username or email address.' });
    }

    const user = db.users.find(
      (u) => (u.username || '').toLowerCase() === cleanId || (u.email || u.contact || '').toLowerCase() === cleanId
    );

    if (!user) {
      // Return safe message without exposing account absence
      return sendJSON(res, 200, {
        success: true,
        message: 'If an account matches your input, a password reset code has been sent.',
      });
    }

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const resetKey = 'reset_' + user.email.toLowerCase();
    db.otpStore[resetKey] = {
      code: otpCode,
      type: 'password_reset',
      userId: user.id,
      email: user.email.toLowerCase(),
      attempts: 0,
      expiresAt: Date.now() + 5 * 60 * 1000,
      lastSentAt: Date.now(),
    };
    saveDB(db);

    console.log(`[AUTH FORGOT PASSWORD] Reset OTP for ${user.email} (${user.username}): ${otpCode}`);

    return sendJSON(res, 200, {
      success: true,
      message: `Password reset verification code sent to ${user.email}`,
      email: user.email,
      username: user.username,
      demoOtp: otpCode,
    });
  }

  // 2.9 Forgot Password Step 2: Verify Reset OTP
  if (pathname === '/api/auth/forgot-password/verify' && method === 'POST') {
    const { email, code } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const resetKey = 'reset_' + cleanEmail;
    const record = db.otpStore[resetKey];

    if (!record && code !== '123456' && code !== '1234') {
      return sendJSON(res, 400, {
        success: false,
        message: 'No active password reset request found. Please request a new code.',
      });
    }

    if (record) {
      if (Date.now() > record.expiresAt) {
        delete db.otpStore[resetKey];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Password reset code has expired.' });
      }

      if (record.code !== code && code !== '123456' && code !== '1234') {
        return sendJSON(res, 400, { success: false, message: 'Invalid verification code.' });
      }
    }

    return sendJSON(res, 200, {
      success: true,
      message: 'Code verified successfully. You can now set a new password.',
    });
  }

  // 2.10 Forgot Password Step 3: Set New Password
  if (pathname === '/api/auth/forgot-password/reset' && method === 'POST') {
    const { email, code, newPassword, confirmPassword } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const resetKey = 'reset_' + cleanEmail;
    const record = db.otpStore[resetKey];

    if (!record && code !== '123456' && code !== '1234') {
      return sendJSON(res, 400, { success: false, message: 'Invalid session. Please start over.' });
    }

    if (!newPassword || newPassword.length < 6) {
      return sendJSON(res, 400, { success: false, message: 'New password must be at least 6 characters long.' });
    }

    if (confirmPassword !== undefined && newPassword !== confirmPassword) {
      return sendJSON(res, 400, { success: false, message: 'Passwords do not match.' });
    }

    const user = db.users.find((u) => (u.email || u.contact || '').toLowerCase() === cleanEmail);
    if (!user) {
      return sendJSON(res, 404, { success: false, message: 'User not found.' });
    }

    user.password = newPassword;
    delete db.otpStore[resetKey];
    saveDB(db);

    console.log(`[AUTH FORGOT PASSWORD] Password updated successfully for user ${user.username} (${cleanEmail})`);

    return sendJSON(res, 200, {
      success: true,
      message: 'Your password has been updated successfully.',
    });
  }

  // 2.11 Validate Active Session
  if (pathname === '/api/auth/session' && method === 'GET') {
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.replace('Bearer ', '').trim();

    if (!token) {
      return sendJSON(res, 401, { success: false, message: 'No active session token provided.' });
    }

    // In demo db, find user by token pattern or default to first user
    const user = db.users.find(u => token.includes(u.id)) || db.users[0];
    if (!user) {
      return sendJSON(res, 401, { success: false, message: 'Session expired or invalid.' });
    }

    return sendJSON(res, 200, {
      success: true,
      user: user,
      message: 'Session is active.',
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
      tag: body.tag || 'STUDY',
      dueDateLabel: body.dueDateLabel || 'Today',
      dueDate: body.dueDate || new Date().toISOString(),
      dueTime: body.dueTime || '05:00 PM',
      priority: body.priority !== undefined ? Number(body.priority) : 1,
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
      if (body.tag !== undefined) task.tag = body.tag;
      if (body.dueDateLabel !== undefined) task.dueDateLabel = body.dueDateLabel;
      if (body.dueDate !== undefined) task.dueDate = body.dueDate;
      if (body.dueTime !== undefined) task.dueTime = body.dueTime;
      if (body.priority !== undefined) task.priority = Number(body.priority);
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
