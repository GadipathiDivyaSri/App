const fs = require('fs');
const path = require('path');
const url = require('url');
const https = require('https');

// Pure Node.js zero-dependency .env loader
try {
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const envLines = fs.readFileSync(envPath, 'utf8').split('\n');
    for (const line of envLines) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
        const [k, ...v] = trimmed.split('=');
        const key = k.trim();
        const val = v.join('=').trim().replace(/^["']|["']$/g, '');
        if (!process.env[key]) {
          process.env[key] = val;
        }
      }
    }
  }
} catch (e) {}

const DB_FILE = path.join(__dirname, 'data', 'db.json');

// Ensure DB directory and file exist
if (!fs.existsSync(path.join(__dirname, 'data'))) {
  fs.mkdirSync(path.join(__dirname, 'data'), { recursive: true });
}

function loadDB() {
  try {
    if (fs.existsSync(DB_FILE)) {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('Error reading db.json:', e);
  }
  return {
    users: [
      {
        id: 'u_1',
        username: 'kalyan',
        name: 'Kalyan',
        email: 'kalyan@wrindhaos.in',
        password: 'password123',
        isEmailVerified: true,
        focusScore: 88,
        activeStreak: 12,
        isPremium: false,
        referralCode: 'WRINDHA2026',
        createdAt: new Date().toISOString(),
      },
    ],
    tasks: [],
    expenses: [],
    habits: [],
    subjects: [],
    studyItems: [],
    journalEntries: [],
    careerNodes: [],
    otpStore: {},
  };
}

function saveDB(db) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
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

/**
 * Dispatch real live email / OTP via MSG91 API or mock fallback
 */
async function dispatchEmailOtp(email, otpCode, type = 'Verification') {
  const authKey = process.env.MSG91_AUTH_KEY;
  const templateId = process.env.MSG91_OTP_TEMPLATE_ID || 'default_otp_template';

  console.log(`[EMAIL OTP DISPATCH] [${type}] Sending 6-digit OTP to: ${email} -> CODE: [${otpCode}]`);

  if (!authKey) {
    return { success: true, mode: 'local', otpCode };
  }

  try {
    const payload = JSON.stringify({
      to: [{ email: email }],
      from: { email: process.env.MSG91_EMAIL_FROM || 'no-reply@wrindhaos.com', name: 'WrindhaOS' },
      template_id: templateId,
      variables: {
        otp: otpCode,
        OTP: otpCode,
        company_name: 'WrindhaOS',
      },
    });

    const options = {
      hostname: 'control.msg91.com',
      port: 443,
      path: `/api/v5/otp?template_id=${encodeURIComponent(templateId)}&mobile=${encodeURIComponent(email)}&authkey=${encodeURIComponent(authKey)}&otp=${encodeURIComponent(otpCode)}`,
      method: 'POST',
      headers: {
        'authkey': authKey,
        'Content-Type': 'application/json',
      },
    };

    return new Promise((resolve) => {
      const req = https.request(options, (msgRes) => {
        let resData = '';
        msgRes.on('data', (chunk) => (resData += chunk));
        msgRes.on('end', () => {
          resolve({ success: true, mode: 'live', response: resData });
        });
      });
      req.on('error', (err) => {
        resolve({ success: true, mode: 'local_fallback', otpCode });
      });
      req.write(payload);
      req.end();
    });
  } catch (err) {
    return { success: true, mode: 'local_fallback', otpCode };
  }
}

// RESERVED USERNAMES
const RESERVED_USERNAMES = [
  'admin', 'administrator', 'root', 'support', 'wrindha', 'wrindhaos',
  'system', 'moderator', 'api', 'help', 'official', 'auth', 'security', 'guest', 'superuser'
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
  if (clean.includes(' ')) {
    return { valid: false, error: 'Username cannot contain spaces.' };
  }
  if (RESERVED_USERNAMES.includes(clean)) {
    return { valid: false, error: `The username '${clean}' is reserved and cannot be used.` };
  }
  return { valid: true, clean };
}

function generateUsernameSuggestions(base) {
  const clean = base.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase() || 'user';
  return [
    `${clean}_01`,
    `${clean}19`,
    `${clean}_os`,
  ].filter(s => !db.users.some(u => (u.username || '').toLowerCase() === s.toLowerCase())).slice(0, 3);
}

// Main API Handler
async function handleApiRequest(req, res) {
  db = loadDB();
  const parsedUrl = url.parse(req.url, true);
  const rawPath = parsedUrl.pathname;
  const pathname = rawPath.replace(/^\/api\/v1\//, '/api/');
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

  // 1. HEALTH CHECK
  if (pathname === '/api/health' && method === 'GET') {
    return sendJSON(res, 200, {
      status: 'ONLINE',
      app: 'WrindhaOS Full Backend Service',
      version: '2.5.0',
      timestamp: new Date().toISOString(),
      stats: {
        usersCount: db.users.length,
        tasksCount: db.tasks.length,
        expensesCount: db.expenses.length,
        habitsCount: db.habits.length,
      },
    });
  }

  // ---------------------------------------------------------------------------
  // 2. AUTHENTICATION SUITE
  // ---------------------------------------------------------------------------

  // 2.1 Check Username Availability
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

  // 2.2 Create Account Step 1: Validate & Send Email OTP
  if (pathname === '/api/auth/register-initiate' && method === 'POST') {
    const { username, email, password, confirmPassword } = body;

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

    const cleanEmail = (email || '').trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!cleanEmail || !emailRegex.test(cleanEmail)) {
      return sendJSON(res, 400, { success: false, message: 'Please enter a valid email address.' });
    }
    if (db.users.some((u) => (u.email || '').toLowerCase() === cleanEmail)) {
      return sendJSON(res, 400, { success: false, message: 'An account with this email already exists.' });
    }

    if (!password || password.length < 8) {
      return sendJSON(res, 400, { success: false, message: 'Password must be at least 8 characters long.' });
    }
    if (confirmPassword !== undefined && password !== confirmPassword) {
      return sendJSON(res, 400, { success: false, message: 'Passwords do not match.' });
    }

    // 6-Digit Email OTP with 10-minute expiry (600s) & 60s cooldown
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const now = Date.now();

    db.otpStore[cleanEmail] = {
      code: otpCode,
      type: 'register',
      attempts: 0,
      maxAttempts: 5,
      createdAt: now,
      expiresAt: now + 10 * 60 * 1000, // 10 minutes
      lastSentAt: now,
      pendingUser: {
        username: val.clean,
        email: cleanEmail,
        password: password,
      },
    };
    saveDB(db);

    await dispatchEmailOtp(cleanEmail, otpCode, 'Registration');

    return sendJSON(res, 200, {
      success: true,
      message: 'Verification code sent to your email.',
      email: cleanEmail,
      expiresInSeconds: 600,
    });
  }

  // 2.3 Create Account Step 2: Verify OTP & Activate Account
  if (pathname === '/api/auth/register-verify' && method === 'POST') {
    const { email, otp } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const otpRecord = db.otpStore[cleanEmail];

    if (!otpRecord || otpRecord.type !== 'register') {
      return sendJSON(res, 400, {
        success: false,
        message: 'No pending registration found. Please sign up again.',
      });
    }

    if (Date.now() > otpRecord.expiresAt) {
      delete db.otpStore[cleanEmail];
      saveDB(db);
      return sendJSON(res, 400, {
        success: false,
        message: 'Verification code has expired. Please request a new one.',
      });
    }

    otpRecord.attempts = (otpRecord.attempts || 0) + 1;
    if (otpRecord.attempts > (otpRecord.maxAttempts || 5)) {
      delete db.otpStore[cleanEmail];
      saveDB(db);
      return sendJSON(res, 400, {
        success: false,
        message: 'Maximum verification attempts exceeded. Please sign up again.',
      });
    }

    if (otpRecord.code !== (otp || '').trim()) {
      saveDB(db);
      const remaining = (otpRecord.maxAttempts || 5) - otpRecord.attempts;
      return sendJSON(res, 400, {
        success: false,
        message: `Invalid verification code. ${remaining} attempt(s) remaining.`,
      });
    }

    // OTP is valid -> Activate and create User Profile
    const pending = otpRecord.pendingUser;
    const newUser = {
      id: 'u_' + Date.now(),
      username: pending.username,
      name: pending.username[0].toUpperCase() + pending.username.slice(1),
      email: cleanEmail,
      password: pending.password,
      isEmailVerified: true,
      focusScore: 85,
      activeStreak: 1,
      isPremium: false,
      referralCode: 'WOS' + Math.floor(1000 + Math.random() * 9000),
      createdAt: new Date().toISOString(),
      onboardingCompleted: false,
    };

    db.users.push(newUser);
    delete db.otpStore[cleanEmail]; // Invalidate single-use OTP
    saveDB(db);

    const token = 'jwt_' + Buffer.from(`${newUser.id}:${Date.now()}`).toString('base64');
    const sub = getUserSubscription(newUser.id);

    return sendJSON(res, 200, {
      success: true,
      message: 'Account verified and activated successfully!',
      token: token,
      user: {
        id: newUser.id,
        username: newUser.username,
        name: newUser.name,
        email: newUser.email,
        focusScore: newUser.focusScore,
        activeStreak: newUser.activeStreak,
        isPremium: sub.plan === 'pro' && sub.status === 'active',
        subscriptionPlan: sub.plan.toUpperCase(),
      },
      subscription: sub,
    });
  }

  // 2.4 Resend OTP
  if (pathname === '/api/auth/resend-otp' && method === 'POST') {
    const { email, type = 'register' } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const record = db.otpStore[cleanEmail];

    if (!record) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Session not found. Please restart the request.',
      });
    }

    const now = Date.now();
    const elapsedSinceLast = Math.floor((now - (record.lastSentAt || 0)) / 1000);
    if (elapsedSinceLast < 60) {
      const waitTime = 60 - elapsedSinceLast;
      return sendJSON(res, 429, {
        success: false,
        message: `Please wait ${waitTime}s before requesting another code.`,
      });
    }

    const newCode = Math.floor(100000 + Math.random() * 900000).toString();
    record.code = newCode;
    record.createdAt = now;
    record.expiresAt = now + 10 * 60 * 1000;
    record.lastSentAt = now;
    record.attempts = 0;
    saveDB(db);

    await dispatchEmailOtp(cleanEmail, newCode, type === 'reset' ? 'Password Reset' : 'Registration');

    return sendJSON(res, 200, {
      success: true,
      message: 'A new 6-digit code has been sent to your email.',
      expiresInSeconds: 600,
    });
  }

  // 2.5 Login (Username + Password)
  if (pathname === '/api/auth/login' && method === 'POST') {
    const { username, password } = body;
    const cleanUser = (username || '').trim().toLowerCase();

    // Find user by username or email
    const user = db.users.find(
      (u) =>
        (u.username || '').toLowerCase() === cleanUser ||
        (u.email || '').toLowerCase() === cleanUser
    );

    // Secure generic error to prevent username enumeration
    if (!user || user.password !== password) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Incorrect username or password.',
      });
    }

    // Check if email verification is complete
    if (user.isEmailVerified === false) {
      // Trigger verification OTP
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const now = Date.now();
      db.otpStore[user.email] = {
        code: otpCode,
        type: 'register',
        attempts: 0,
        maxAttempts: 5,
        createdAt: now,
        expiresAt: now + 10 * 60 * 1000,
        lastSentAt: now,
        pendingUser: user,
      };
      saveDB(db);
      await dispatchEmailOtp(user.email, otpCode, 'Verification Required');

      return sendJSON(res, 200, {
        success: false,
        isVerified: false,
        email: user.email,
        message: 'Please verify your email before logging in.',
      });
    }

    const token = 'jwt_' + Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
    const sub = getUserSubscription(user.id);

    return sendJSON(res, 200, {
      success: true,
      message: 'Login successful.',
      token: token,
      user: {
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        focusScore: user.focusScore || 85,
        activeStreak: user.activeStreak || 1,
        isPremium: sub.plan === 'pro' && sub.status === 'active',
        subscriptionPlan: sub.plan.toUpperCase(),
      },
      subscription: sub,
    });
  }

  // 2.6 Forgot Password Step 1: Request Reset OTP
  if (pathname === '/api/auth/forgot-password/initiate' && method === 'POST') {
    const { email } = body;
    const cleanEmail = (email || '').trim().toLowerCase();

    // Security: Always return generic message regardless of existence
    const user = db.users.find((u) => (u.email || '').toLowerCase() === cleanEmail);

    if (user) {
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const now = Date.now();
      db.otpStore[cleanEmail] = {
        code: otpCode,
        type: 'reset',
        attempts: 0,
        maxAttempts: 5,
        createdAt: now,
        expiresAt: now + 10 * 60 * 1000, // 10 minutes
        lastSentAt: now,
        userId: user.id,
      };
      saveDB(db);
      await dispatchEmailOtp(cleanEmail, otpCode, 'Password Reset');
    }

    return sendJSON(res, 200, {
      success: true,
      message: 'If an account exists with this email, a verification code has been sent.',
      email: cleanEmail,
    });
  }

  // 2.7 Forgot Password Step 2: Verify Reset OTP
  if (pathname === '/api/auth/forgot-password/verify-otp' && method === 'POST') {
    const { email, otp } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const otpRecord = db.otpStore[cleanEmail];

    if (!otpRecord || otpRecord.type !== 'reset') {
      return sendJSON(res, 400, {
        success: false,
        message: 'Invalid or expired password reset session. Please request a new code.',
      });
    }

    if (Date.now() > otpRecord.expiresAt) {
      delete db.otpStore[cleanEmail];
      saveDB(db);
      return sendJSON(res, 400, {
        success: false,
        message: 'Verification code has expired. Please request a new one.',
      });
    }

    otpRecord.attempts = (otpRecord.attempts || 0) + 1;
    if (otpRecord.attempts > (otpRecord.maxAttempts || 5)) {
      delete db.otpStore[cleanEmail];
      saveDB(db);
      return sendJSON(res, 400, {
        success: false,
        message: 'Maximum verification attempts exceeded. Please request a new code.',
      });
    }

    if (otpRecord.code !== (otp || '').trim()) {
      saveDB(db);
      const remaining = (otpRecord.maxAttempts || 5) - otpRecord.attempts;
      return sendJSON(res, 400, {
        success: false,
        message: `Invalid verification code. ${remaining} attempt(s) remaining.`,
      });
    }

    // Generate single-use resetToken
    const resetToken = 'rst_' + Buffer.from(`${cleanEmail}:${Date.now()}`).toString('base64');
    otpRecord.resetToken = resetToken;
    saveDB(db);

    return sendJSON(res, 200, {
      success: true,
      message: 'Identity verified successfully.',
      resetToken: resetToken,
    });
  }

  // 2.8 Forgot Password Step 3: Create New Password
  if (pathname === '/api/auth/forgot-password/reset' && method === 'POST') {
    const { email, resetToken, newPassword, confirmPassword } = body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const otpRecord = db.otpStore[cleanEmail];

    if (!otpRecord || otpRecord.resetToken !== resetToken) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Invalid or expired reset session. Please request a new code.',
      });
    }

    if (!newPassword || newPassword.length < 8) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Password must be at least 8 characters long.',
      });
    }

    if (confirmPassword && newPassword !== confirmPassword) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Passwords do not match.',
      });
    }

    const user = db.users.find((u) => (u.email || '').toLowerCase() === cleanEmail);
    if (!user) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Account not found.',
      });
    }

    // Update password securely
    user.password = newPassword;
    delete db.otpStore[cleanEmail]; // Clear single-use reset token
    saveDB(db);

    return sendJSON(res, 200, {
      success: true,
      message: 'Your password has been updated successfully.',
    });
  }

  // Helper to reliably extract authenticated user ID from Authorization header
  function getAuthUserId(req) {
    const authHeader = req.headers['authorization'] || '';
    if (authHeader.startsWith('Bearer jwt_')) {
      const raw = authHeader.replace('Bearer jwt_', '');
      try {
        const decoded = Buffer.from(raw, 'base64').toString('utf8');
        if (decoded && decoded.includes(':')) {
          const parts = decoded.split(':');
          if (parts[0] && /^u_[a-zA-Z0-9_-]+$/.test(parts[0])) return parts[0];
        }
      } catch (_) {}
      if (raw.includes(':')) {
        const parts = raw.split(':');
        if (parts[0]) return parts[0];
      }
      return raw || 'u_1';
    }
    return 'u_1';
  }

  // Helper to ensure each user has a valid subscription record
  function getUserSubscription(userId) {
    if (!db.subscriptions) db.subscriptions = [];
    let sub = db.subscriptions.find((s) => s.user_id === userId);
    if (!sub) {
      sub = {
        id: 'sub_free_' + userId,
        user_id: userId,
        plan: 'free',
        status: 'active',
        started_at: new Date().toISOString(),
        expires_at: null,
        payment_provider: 'NONE',
        transaction_id: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      db.subscriptions.push(sub);
      saveDB(db);
    }
    return sub;
  }

  // 2.9 Session Check / Refresh
  if (pathname === '/api/auth/session' && method === 'GET') {
    const userId = getAuthUserId(req);
    const user = db.users.find((u) => u.id === userId);
    if (user) {
      const sub = getUserSubscription(user.id);
      return sendJSON(res, 200, {
        success: true,
        user: {
          id: user.id,
          username: user.username,
          name: user.name,
          email: user.email,
          focusScore: user.focusScore || 85,
          activeStreak: user.activeStreak || 1,
          isPremium: sub.plan === 'pro' && sub.status === 'active',
          subscriptionPlan: sub.plan.toUpperCase(),
        },
        subscription: sub,
      });
    }
    return sendJSON(res, 401, { success: false, message: 'No active session.' });
  }

  // 2.10 Subscription Management (Read Only for Client)
  if (pathname === '/api/subscription/me' && method === 'GET') {
    const targetUserId = getAuthUserId(req);
    const sub = getUserSubscription(targetUserId);
    return sendJSON(res, 200, {
      success: true,
      subscription: sub,
    });
  }

  // 2.11 Logout
  if (pathname === '/api/auth/logout' && method === 'POST') {
    return sendJSON(res, 200, {
      success: true,
      message: 'Logged out successfully.',
    });
  }

  // ---------------------------------------------------------------------------
  // 3. APPLICATION CRUD ROUTES (Tasks, Habits, Expenses, etc.)
  // ---------------------------------------------------------------------------
  if (pathname === '/api/tasks' && method === 'GET') {
    return sendJSON(res, 200, db.tasks);
  }
  if (pathname === '/api/tasks' && method === 'POST') {
    const newTask = { id: 't_' + Date.now(), ...body };
    db.tasks.push(newTask);
    saveDB(db);
    return sendJSON(res, 201, newTask);
  }
  if (pathname.startsWith('/api/tasks/') && method === 'DELETE') {
    const id = pathname.split('/').pop();
    db.tasks = db.tasks.filter((t) => t.id !== id);
    saveDB(db);
    return sendJSON(res, 200, { success: true });
  }

  if (pathname === '/api/habits' && method === 'GET') {
    return sendJSON(res, 200, db.habits);
  }
  if (pathname === '/api/habits' && method === 'POST') {
    const targetUserId = getAuthUserId(req);
    const sub = getUserSubscription(targetUserId);
    const userHabits = (db.habits || []).filter((h) => h.userId === targetUserId || !h.userId);
    if (sub.plan === 'free' && userHabits.length >= 2) {
      return sendJSON(res, 403, {
        success: false,
        code: 'LIMIT_REACHED',
        title: 'Unlock Unlimited Habits',
        message: "You've reached the Free plan limit of 2 habits. Upgrade to WrindhaOS Pro to create and track unlimited habits.",
        requiresUpgrade: true,
      });
    }

    const newHabit = { id: 'h_' + Date.now(), userId: targetUserId, ...body };
    db.habits.push(newHabit);
    saveDB(db);
    return sendJSON(res, 201, newHabit);
  }

  if (pathname === '/api/subjects' && method === 'GET') {
    return sendJSON(res, 200, db.subjects || []);
  }
  if (pathname === '/api/subjects' && method === 'POST') {
    const targetUserId = getAuthUserId(req);
    const sub = getUserSubscription(targetUserId);
    const userSubjects = (db.subjects || []).filter((s) => s.userId === targetUserId || !s.userId);
    if (sub.plan === 'free' && userSubjects.length >= 2) {
      return sendJSON(res, 403, {
        success: false,
        code: 'LIMIT_REACHED',
        title: 'Unlock Unlimited Subjects',
        message: "You've reached the Free plan limit of 2 subjects. Upgrade to WrindhaOS Pro to manage unlimited subjects and organize your complete learning journey.",
        requiresUpgrade: true,
      });
    }

    const newSubject = { id: 'sub_' + Date.now(), userId: targetUserId, ...body };
    if (!db.subjects) db.subjects = [];
    db.subjects.push(newSubject);
    saveDB(db);
    return sendJSON(res, 201, newSubject);
  }

  if (pathname === '/api/expenses' && method === 'GET') {
    return sendJSON(res, 200, db.expenses);
  }
  if (pathname === '/api/expenses' && method === 'POST') {
    const newExpense = { id: 'e_' + Date.now(), ...body };
    db.expenses.push(newExpense);
    saveDB(db);
    return sendJSON(res, 201, newExpense);
  }

  // Fallback 404
  return sendJSON(res, 404, {
    success: false,
    message: `Route not found: ${method} ${rawPath}`,
  });
}

module.exports = { handleApiRequest };
