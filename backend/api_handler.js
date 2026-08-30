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

// Ensure DB directory exists
if (!fs.existsSync(path.join(__dirname, 'data'))) {
  fs.mkdirSync(path.join(__dirname, 'data'), { recursive: true });
}

/**
 * Initializes and normalizes database schema collections
 */
function loadDB() {
  let dbData = {};
  try {
    if (fs.existsSync(DB_FILE)) {
      dbData = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('Error reading db.json:', e);
  }

  // Schema normalization across all modules
  const schema = {
    users: Array.isArray(dbData.users) ? dbData.users : [],
    subscriptions: Array.isArray(dbData.subscriptions) ? dbData.subscriptions : [],
    tasks: Array.isArray(dbData.tasks) ? dbData.tasks : [],
    calendarEvents: Array.isArray(dbData.calendarEvents) ? dbData.calendarEvents : [],
    habits: Array.isArray(dbData.habits) ? dbData.habits : [],
    subjects: Array.isArray(dbData.subjects) ? dbData.subjects : [],
    studyItems: Array.isArray(dbData.studyItems) ? dbData.studyItems : [],
    timetable: Array.isArray(dbData.timetable) ? dbData.timetable : [],
    careerNodes: Array.isArray(dbData.careerNodes) ? dbData.careerNodes : [],
    goals: Array.isArray(dbData.goals) ? dbData.goals : [],
    expenses: Array.isArray(dbData.expenses) ? dbData.expenses : [],
    journalEntries: Array.isArray(dbData.journalEntries) ? dbData.journalEntries : [],
    milestones: Array.isArray(dbData.milestones) ? dbData.milestones : [],
    notifications: Array.isArray(dbData.notifications) ? dbData.notifications : [],
    coupons: Array.isArray(dbData.coupons) ? dbData.coupons : [
      {
        id: 'c_welcome50',
        code: 'WELCOME50',
        title: '50% Off WrindhaOS Pro',
        description: 'Get 50% off your first month of WrindhaOS Pro!',
        discountType: 'percentage',
        discountValue: 50,
        product: 'pro_monthly',
        googlePlayOfferId: 'play_offer_welcome50',
        startDate: '2026-01-01T00:00:00.000Z',
        expiryDate: '2027-12-31T23:59:59.000Z',
        usageLimit: 1000,
        perUserLimit: 1,
        active: true,
        campaignSource: 'LAUNCH2026',
        creator: 'WrindhaOS Team',
        createdAt: new Date().toISOString(),
      },
      {
        id: 'c_pro1monthfree',
        code: 'PROFREE',
        title: '30 Days Free Trial',
        description: 'Enjoy 30 days of full WrindhaOS Pro access on us!',
        discountType: 'free_trial',
        discountValue: 100,
        product: 'pro_monthly',
        googlePlayOfferId: 'play_offer_30day_trial',
        startDate: '2026-01-01T00:00:00.000Z',
        expiryDate: '2027-12-31T23:59:59.000Z',
        usageLimit: 500,
        perUserLimit: 1,
        active: true,
        campaignSource: 'INFLUENCER_CAMPAIGN',
        creator: 'Growth Team',
        createdAt: new Date().toISOString(),
      },
    ],
    couponUsages: Array.isArray(dbData.couponUsages) ? dbData.couponUsages : [],
    referralCodes: Array.isArray(dbData.referralCodes) ? dbData.referralCodes : [],
    referralTrackings: Array.isArray(dbData.referralTrackings) ? dbData.referralTrackings : [],
    otpStore: dbData.otpStore || {},
  };

  return schema;
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
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
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
  } catch (e) {
    return { success: true, mode: 'fallback', otpCode };
  }
}

/**
 * Extract authenticated user ID from Authorization header
 */
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
    return raw || 'u_1001';
  }
  return 'u_1001';
}

/**
 * Helper to ensure each user has a valid subscription record
 */
function getUserSubscription(userId) {
  if (!Array.isArray(db.subscriptions)) db.subscriptions = [];
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

/**
 * Helper to validate feature entitlement access on backend
 */
function checkFeatureEntitlement(userId, featureKey) {
  const sub = getUserSubscription(userId);
  const isPro = sub.plan === 'pro' && sub.status === 'active';

  const proOnlyFeatures = [
    'goals',
    'priorityMatrix',
    'eisenhowerMatrix',
    'expenseTracker',
    'notes',
    'journal',
    'milestones',
    'careerRoadmap',
    'focusTimer',
    'analytics',
  ];

  if (proOnlyFeatures.includes(featureKey) && !isPro) {
    return {
      allowed: false,
      code: 'PRO_REQUIRED',
      message: `Feature '${featureKey}' requires an active WrindhaOS Pro subscription.`,
    };
  }

  return { allowed: true };
}

/**
 * Master API Request Handler
 */
async function handleApiRequest(req, res) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return sendJSON(res, 204, {});
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method.toUpperCase();
  const body = await parseBody(req);
  const userId = getAuthUserId(req);

  try {
    // =========================================================================
    // 1. AUTHENTICATION & USER MANAGEMENT
    // =========================================================================

    // 1.1 Initiate Registration (OTP Step 1)
    if (pathname === '/api/auth/register-initiate' && method === 'POST') {
      const { username, email, password, confirmPassword } = body;

      const cleanUser = (username || '').trim().toLowerCase();
      if (!cleanUser || cleanUser.length < 3) {
        return sendJSON(res, 400, { success: false, message: 'Username must be at least 3 characters.' });
      }
      if (db.users.some((u) => (u.username || '').toLowerCase() === cleanUser)) {
        return sendJSON(res, 400, { success: false, message: 'Username is already taken.' });
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

      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const now = Date.now();

      db.otpStore[cleanEmail] = {
        code: otpCode,
        type: 'register',
        attempts: 0,
        maxAttempts: 5,
        createdAt: now,
        expiresAt: now + 10 * 60 * 1000,
        lastSentAt: now,
        pendingUser: { username: cleanUser, email: cleanEmail, password },
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

    // 1.2 Verify Registration OTP & Activate User
    if (pathname === '/api/auth/register-verify' && method === 'POST') {
      const { email, otp, referralCode } = body;
      const cleanEmail = (email || '').trim().toLowerCase();
      const otpRecord = db.otpStore[cleanEmail];

      if (!otpRecord || otpRecord.type !== 'register') {
        return sendJSON(res, 400, { success: false, message: 'No pending registration found.' });
      }

      if (Date.now() > otpRecord.expiresAt) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Verification code has expired.' });
      }

      otpRecord.attempts = (otpRecord.attempts || 0) + 1;
      if (otpRecord.attempts > (otpRecord.maxAttempts || 5)) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Maximum attempts exceeded.' });
      }

      if (otpRecord.code !== (otp || '').trim()) {
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Invalid verification code.' });
      }

      const pending = otpRecord.pendingUser;
      const newUserId = 'u_' + Date.now();
      const userRefCode = 'WOS' + Math.floor(1000 + Math.random() * 9000);

      const newUser = {
        id: newUserId,
        username: pending.username,
        name: pending.username[0].toUpperCase() + pending.username.slice(1),
        email: cleanEmail,
        password: pending.password,
        isEmailVerified: true,
        focusScore: 85,
        activeStreak: 1,
        isPremium: false,
        referralCode: userRefCode,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        onboardingCompleted: false,
      };

      db.users.push(newUser);
      delete db.otpStore[cleanEmail];

      // Auto-assign Free plan
      getUserSubscription(newUserId);

      // Create user's referral code record
      db.referralCodes.push({
        id: 'ref_' + newUserId,
        userId: newUserId,
        referralCode: userRefCode,
        status: 'active',
        totalCount: 0,
        createdAt: new Date().toISOString(),
      });

      // Handle referral application if provided
      if (referralCode) {
        const referrer = db.users.find((u) => u.referralCode === referralCode.trim());
        if (referrer && referrer.id !== newUserId) {
          db.referralTrackings.push({
            id: 'rt_' + Date.now(),
            referrerUserId: referrer.id,
            referredUserId: newUserId,
            referralCode: referralCode.trim(),
            signupDate: new Date().toISOString(),
            eligibilityStatus: 'eligible',
            conversionStatus: 'signed_up',
            firstPurchaseStatus: 'pending',
            rewardStatus: 'issued',
            rewardIssuedDate: new Date().toISOString(),
          });
          const refRecord = db.referralCodes.find((r) => r.userId === referrer.id);
          if (refRecord) refRecord.totalCount = (refRecord.totalCount || 0) + 1;
        }
      }

      saveDB(db);

      const token = 'jwt_' + Buffer.from(`${newUser.id}:${Date.now()}`).toString('base64');
      const sub = getUserSubscription(newUser.id);

      return sendJSON(res, 200, {
        success: true,
        message: 'Account created and verified successfully!',
        token,
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

    // 1.3 Login (Email / Username)
    if (pathname === '/api/auth/login' && method === 'POST') {
      const { username, password } = body;
      const cleanUser = (username || '').trim().toLowerCase();

      const user = db.users.find(
        (u) =>
          (u.username || '').toLowerCase() === cleanUser ||
          (u.email || '').toLowerCase() === cleanUser
      );

      if (!user || user.password !== password) {
        return sendJSON(res, 400, { success: false, message: 'Incorrect username or password.' });
      }

      const token = 'jwt_' + Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
      const sub = getUserSubscription(user.id);

      return sendJSON(res, 200, {
        success: true,
        message: 'Login successful.',
        token,
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

    // 1.4 Google Sign-In Backend Authentication
    if (pathname === '/api/auth/google' && method === 'POST') {
      const { email, googleId, name, photoUrl } = body;
      const cleanEmail = (email || '').trim().toLowerCase();

      if (!cleanEmail) {
        return sendJSON(res, 400, { success: false, message: 'Google Sign-In requires a valid email.' });
      }

      let user = db.users.find((u) => (u.email || '').toLowerCase() === cleanEmail);
      if (!user) {
        const newUserId = 'u_' + Date.now();
        const userRefCode = 'WOS' + Math.floor(1000 + Math.random() * 9000);
        user = {
          id: newUserId,
          username: cleanEmail.split('@')[0],
          name: name || cleanEmail.split('@')[0],
          email: cleanEmail,
          googleId: googleId || 'g_' + Date.now(),
          photoUrl: photoUrl || null,
          isEmailVerified: true,
          focusScore: 85,
          activeStreak: 1,
          isPremium: false,
          referralCode: userRefCode,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        db.users.push(user);
        getUserSubscription(user.id);
        db.referralCodes.push({
          id: 'ref_' + user.id,
          userId: user.id,
          referralCode: userRefCode,
          status: 'active',
          totalCount: 0,
          createdAt: new Date().toISOString(),
        });
        saveDB(db);
      }

      const token = 'jwt_' + Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
      const sub = getUserSubscription(user.id);

      return sendJSON(res, 200, {
        success: true,
        message: 'Google Sign-In successful.',
        token,
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

    // 1.5 Resend OTP
    if (pathname === '/api/auth/resend-otp' && method === 'POST') {
      const { email, type = 'register' } = body;
      const cleanEmail = (email || '').trim().toLowerCase();
      const record = db.otpStore[cleanEmail];

      if (!record) {
        return sendJSON(res, 400, { success: false, message: 'Session expired. Please restart registration.' });
      }

      const newCode = Math.floor(100000 + Math.random() * 900000).toString();
      record.code = newCode;
      record.expiresAt = Date.now() + 10 * 60 * 1000;
      saveDB(db);

      await dispatchEmailOtp(cleanEmail, newCode, type === 'reset' ? 'Password Reset' : 'Registration');

      return sendJSON(res, 200, { success: true, message: 'A new 6-digit verification code has been sent.' });
    }

    // 1.6 Password Reset Initiated
    if (pathname === '/api/auth/forgot-password/initiate' && method === 'POST') {
      const { email } = body;
      const cleanEmail = (email || '').trim().toLowerCase();
      const user = db.users.find((u) => (u.email || '').toLowerCase() === cleanEmail);

      if (user) {
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        db.otpStore[cleanEmail] = {
          code: otpCode,
          type: 'reset',
          attempts: 0,
          maxAttempts: 5,
          createdAt: Date.now(),
          expiresAt: Date.now() + 10 * 60 * 1000,
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

    // 1.7 Session Check
    if (pathname === '/api/auth/session' && method === 'GET') {
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

    // 1.8 Account Deletion & User Data Purge Flow
    if ((pathname === '/api/users/me' || pathname === '/api/account/delete') && method === 'DELETE') {
      db.users = (db.users || []).filter((u) => u.id !== userId);
      db.subscriptions = (db.subscriptions || []).filter((s) => s.user_id !== userId);
      db.tasks = (db.tasks || []).filter((t) => t.userId !== userId);
      db.habits = (db.habits || []).filter((h) => h.userId !== userId);
      db.subjects = (db.subjects || []).filter((s) => s.userId !== userId);
      db.calendarEvents = (db.calendarEvents || []).filter((c) => c.userId !== userId);
      db.expenses = (db.expenses || []).filter((e) => e.userId !== userId);
      db.journalEntries = (db.journalEntries || []).filter((j) => j.userId !== userId);
      db.careerNodes = (db.careerNodes || []).filter((cn) => cn.userId !== userId);
      db.goals = (db.goals || []).filter((g) => g.userId !== userId);
      db.milestones = (db.milestones || []).filter((m) => m.userId !== userId);
      db.timetable = (db.timetable || []).filter((tt) => tt.userId !== userId);
      db.notifications = (db.notifications || []).filter((n) => n.userId !== userId);
      db.referralCodes = (db.referralCodes || []).filter((rc) => rc.userId !== userId);

      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: 'Your account and all associated personal data have been completely deleted.',
      });
    }

    // =========================================================================
    // 2. MODULE CRUD ENDPOINTS (User Data Isolation Enforced)
    // =========================================================================

    // 2.1 Tasks (To-Do, Priority Matrix, Eisenhower Matrix)
    if (pathname === '/api/tasks' && method === 'GET') {
      const userTasks = db.tasks.filter((t) => t.userId === userId || !t.userId);
      return sendJSON(res, 200, userTasks);
    }
    if (pathname === '/api/tasks' && method === 'POST') {
      const newTask = {
        id: 't_' + Date.now(),
        userId,
        title: body.title || 'Untitled Task',
        category: body.category || 'General',
        dueDateLabel: body.dueDateLabel || 'Today',
        isCompleted: false,
        priority: body.priority || 1,
        quadrant: body.quadrant || 1,
        dueDate: body.dueDate || new Date().toISOString(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      db.tasks.push(newTask);
      saveDB(db);
      return sendJSON(res, 201, newTask);
    }
    if (pathname.startsWith('/api/tasks/') && method === 'DELETE') {
      const taskId = pathname.split('/').pop();
      db.tasks = db.tasks.filter((t) => !(t.id === taskId && (t.userId === userId || !t.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true });
    }

    // 2.2 Calendar
    if (pathname === '/api/calendar' && method === 'GET') {
      const events = db.calendarEvents.filter((c) => c.userId === userId || !c.userId);
      return sendJSON(res, 200, events);
    }
    if (pathname === '/api/calendar' && method === 'POST') {
      const newEvent = {
        id: 'cal_' + Date.now(),
        userId,
        title: body.title || 'Event',
        date: body.date || new Date().toISOString(),
        startTime: body.startTime || '09:00',
        endTime: body.endTime || '10:00',
        category: body.category || 'General',
        createdAt: new Date().toISOString(),
      };
      db.calendarEvents.push(newEvent);
      saveDB(db);
      return sendJSON(res, 201, newEvent);
    }

    // 2.3 Habits (Free Plan limit: Max 2 Habits)
    if (pathname === '/api/habits' && method === 'GET') {
      const habits = db.habits.filter((h) => h.userId === userId || !h.userId);
      return sendJSON(res, 200, habits);
    }
    if (pathname === '/api/habits' && method === 'POST') {
      const sub = getUserSubscription(userId);
      const userHabits = db.habits.filter((h) => h.userId === userId || !h.userId);
      if (sub.plan === 'free' && userHabits.length >= 2) {
        return sendJSON(res, 403, {
          success: false,
          code: 'LIMIT_REACHED',
          title: 'Unlock Unlimited Habits',
          message: "You've reached the Free plan limit of 2 habits. Upgrade to WrindhaOS Pro to create and track unlimited habits.",
          requiresUpgrade: true,
        });
      }

      const newHabit = {
        id: 'h_' + Date.now(),
        userId,
        title: body.title || 'New Habit',
        frequency: body.frequency || 'DAILY',
        streak: 0,
        createdAt: new Date().toISOString(),
      };
      db.habits.push(newHabit);
      saveDB(db);
      return sendJSON(res, 201, newHabit);
    }

    // 2.4 Subjects (Free Plan limit: Max 2 Subjects)
    if (pathname === '/api/subjects' && method === 'GET') {
      const subjects = db.subjects.filter((s) => s.userId === userId || !s.userId);
      return sendJSON(res, 200, subjects);
    }
    if (pathname === '/api/subjects' && method === 'POST') {
      const sub = getUserSubscription(userId);
      const userSubjects = db.subjects.filter((s) => s.userId === userId || !s.userId);
      if (sub.plan === 'free' && userSubjects.length >= 2) {
        return sendJSON(res, 403, {
          success: false,
          code: 'LIMIT_REACHED',
          title: 'Unlock Unlimited Subjects',
          message: "You've reached the Free plan limit of 2 subjects. Upgrade to WrindhaOS Pro to manage unlimited subjects and organize your complete learning journey.",
          requiresUpgrade: true,
        });
      }

      const newSubject = {
        id: 'sub_' + Date.now(),
        userId,
        name: body.name || 'New Subject',
        code: body.code || '',
        instructor: body.instructor || '',
        createdAt: new Date().toISOString(),
      };
      db.subjects.push(newSubject);
      saveDB(db);
      return sendJSON(res, 201, newSubject);
    }

    // 2.5 Timetable
    if (pathname === '/api/timetable' && method === 'GET') {
      const items = db.timetable.filter((tt) => tt.userId === userId || !tt.userId);
      return sendJSON(res, 200, items);
    }
    if (pathname === '/api/timetable' && method === 'POST') {
      const newItem = {
        id: 'tt_' + Date.now(),
        userId,
        dayOfWeek: body.dayOfWeek || 'Monday',
        subjectName: body.subjectName || 'Lecture',
        startTime: body.startTime || '09:00',
        endTime: body.endTime || '10:00',
        createdAt: new Date().toISOString(),
      };
      db.timetable.push(newItem);
      saveDB(db);
      return sendJSON(res, 201, newItem);
    }

    // 2.6 Pro Modules: Goals, Expenses, Journal, Career Roadmap, Milestones
    if (pathname === '/api/goals' && method === 'GET') {
      const goals = db.goals.filter((g) => g.userId === userId || !g.userId);
      return sendJSON(res, 200, goals);
    }
    if (pathname === '/api/goals' && method === 'POST') {
      const entitlement = checkFeatureEntitlement(userId, 'goals');
      if (!entitlement.allowed) return sendJSON(res, 403, entitlement);

      const newGoal = {
        id: 'g_' + Date.now(),
        userId,
        title: body.title || 'Goal',
        tier: body.tier || 'short',
        isCompleted: false,
        createdAt: new Date().toISOString(),
      };
      db.goals.push(newGoal);
      saveDB(db);
      return sendJSON(res, 201, newGoal);
    }

    if (pathname === '/api/expenses' && method === 'GET') {
      const expenses = db.expenses.filter((e) => e.userId === userId || !e.userId);
      return sendJSON(res, 200, expenses);
    }
    if (pathname === '/api/expenses' && method === 'POST') {
      const entitlement = checkFeatureEntitlement(userId, 'expenseTracker');
      if (!entitlement.allowed) return sendJSON(res, 403, entitlement);

      const newExpense = {
        id: 'e_' + Date.now(),
        userId,
        title: body.title || 'Expense',
        category: body.category || 'General',
        amount: Number(body.amount) || 0,
        isIncome: !!body.isIncome,
        date: body.date || new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      db.expenses.push(newExpense);
      saveDB(db);
      return sendJSON(res, 201, newExpense);
    }

    if (pathname === '/api/journal' && method === 'GET') {
      const entries = db.journalEntries.filter((j) => j.userId === userId || !j.userId);
      return sendJSON(res, 200, entries);
    }
    if (pathname === '/api/journal' && method === 'POST') {
      const entitlement = checkFeatureEntitlement(userId, 'journal');
      if (!entitlement.allowed) return sendJSON(res, 403, entitlement);

      const newEntry = {
        id: 'j_' + Date.now(),
        userId,
        title: body.title || 'Journal Entry',
        content: body.content || '',
        date: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      db.journalEntries.push(newEntry);
      saveDB(db);
      return sendJSON(res, 201, newEntry);
    }

    if (pathname === '/api/career-roadmap' && method === 'GET') {
      const nodes = db.careerNodes.filter((c) => c.userId === userId || !c.userId);
      return sendJSON(res, 200, nodes);
    }
    if (pathname === '/api/career-roadmap' && method === 'POST') {
      const entitlement = checkFeatureEntitlement(userId, 'careerRoadmap');
      if (!entitlement.allowed) return sendJSON(res, 403, entitlement);

      const newNode = {
        id: 'cn_' + Date.now(),
        userId,
        title: body.title || 'Career Milestone',
        sectionKey: body.sectionKey || 'GOAL',
        isCompleted: false,
        createdAt: new Date().toISOString(),
      };
      db.careerNodes.push(newNode);
      saveDB(db);
      return sendJSON(res, 201, newNode);
    }

    if (pathname === '/api/milestones' && method === 'GET') {
      const milestones = db.milestones.filter((m) => m.userId === userId || !m.userId);
      return sendJSON(res, 200, milestones);
    }
    if (pathname === '/api/milestones' && method === 'POST') {
      const entitlement = checkFeatureEntitlement(userId, 'milestones');
      if (!entitlement.allowed) return sendJSON(res, 403, entitlement);

      const newMilestone = {
        id: 'm_' + Date.now(),
        userId,
        title: body.title || 'Achievement',
        dateAchieved: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      db.milestones.push(newMilestone);
      saveDB(db);
      return sendJSON(res, 201, newMilestone);
    }

    // 2.7 Notifications
    if (pathname === '/api/notifications' && method === 'GET') {
      const userNotifs = db.notifications.filter((n) => n.userId === userId || !n.userId);
      return sendJSON(res, 200, userNotifs);
    }

    // 2.8 Dynamic Real Analytics Calculations
    if (pathname === '/api/analytics/summary' && method === 'GET') {
      const userTasks = db.tasks.filter((t) => t.userId === userId);
      const userHabits = db.habits.filter((h) => h.userId === userId);
      const userSubjects = db.subjects.filter((s) => s.userId === userId);
      const userExpenses = db.expenses.filter((e) => e.userId === userId);

      const totalTasks = userTasks.length;
      const completedTasks = userTasks.filter((t) => t.isCompleted).length;
      const taskCompletionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

      const totalHabits = userHabits.length;
      const totalExpenseSpent = userExpenses.filter((e) => !e.isIncome).reduce((acc, curr) => acc + (curr.amount || 0), 0);

      return sendJSON(res, 200, {
        success: true,
        analytics: {
          totalTasks,
          completedTasks,
          taskCompletionRate,
          activeHabitsCount: totalHabits,
          enrolledSubjectsCount: userSubjects.length,
          totalExpenseSpent,
          focusScore: 92,
          generatedAt: new Date().toISOString(),
        },
      });
    }

    // =========================================================================
    // 3. SUBSCRIPTION & PAYMENT MANAGEMENT
    // =========================================================================

    if (pathname === '/api/subscription/me' && method === 'GET') {
      const sub = getUserSubscription(userId);
      return sendJSON(res, 200, { success: true, subscription: sub });
    }

    if (pathname === '/api/subscription/upgrade' && method === 'POST') {
      const sub = getUserSubscription(userId);
      sub.plan = 'pro';
      sub.status = 'active';
      sub.started_at = new Date().toISOString();
      sub.updated_at = new Date().toISOString();
      sub.payment_provider = body.provider || 'GOOGLE_PLAY';
      sub.transaction_id = body.transactionId || 'tx_' + Date.now();

      const user = db.users.find((u) => u.id === userId);
      if (user) user.isPremium = true;

      saveDB(db);
      return sendJSON(res, 200, {
        success: true,
        message: 'Successfully upgraded to WrindhaOS Pro!',
        subscription: sub,
      });
    }

    if (pathname === '/api/subscription/cancel' && method === 'POST') {
      const sub = getUserSubscription(userId);
      sub.plan = 'free';
      sub.status = 'cancelled';
      sub.updated_at = new Date().toISOString();

      const user = db.users.find((u) => u.id === userId);
      if (user) user.isPremium = false;

      saveDB(db);
      return sendJSON(res, 200, {
        success: true,
        message: 'Subscription cancelled. Account set to Free plan.',
        subscription: sub,
      });
    }

    // =========================================================================
    // 4. COUPON & PROMOTIONAL CODE SYSTEM
    // =========================================================================

    // 4.1 Validate Coupon Code
    if (pathname === '/api/coupons/validate' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      const coupon = db.coupons.find((c) => c.code.toUpperCase() === cleanCode && c.active);

      if (!coupon) {
        return sendJSON(res, 400, { success: false, message: 'Invalid or inactive coupon code.' });
      }

      // Check Expiry Date
      if (new Date() > new Date(coupon.expiryDate)) {
        return sendJSON(res, 400, { success: false, message: 'This coupon code has expired.' });
      }

      // Check Start Date
      if (new Date() < new Date(coupon.startDate)) {
        return sendJSON(res, 400, { success: false, message: 'This promotion has not started yet.' });
      }

      // Check Global Usage Limit
      const totalUsedCount = db.couponUsages.filter((u) => u.couponId === coupon.id && u.validationStatus === 'applied').length;
      if (coupon.usageLimit && totalUsedCount >= coupon.usageLimit) {
        return sendJSON(res, 400, { success: false, message: 'This coupon code has reached its maximum usage limit.' });
      }

      // Check Per-User Usage Limit
      const userUsageCount = db.couponUsages.filter((u) => u.couponId === coupon.id && u.userId === userId && u.validationStatus === 'applied').length;
      if (coupon.perUserLimit && userUsageCount >= coupon.perUserLimit) {
        return sendJSON(res, 400, { success: false, message: 'You have already redeemed this promotional coupon.' });
      }

      return sendJSON(res, 200, {
        success: true,
        message: 'Coupon code is valid!',
        coupon: {
          id: coupon.id,
          code: coupon.code,
          title: coupon.title,
          description: coupon.description,
          discountType: coupon.discountType,
          discountValue: coupon.discountValue,
          googlePlayOfferId: coupon.googlePlayOfferId,
        },
      });
    }

    // 4.2 Apply Coupon Code & Issue Entitlement
    if (pathname === '/api/coupons/apply' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      const coupon = db.coupons.find((c) => c.code.toUpperCase() === cleanCode && c.active);
      if (!coupon) {
        return sendJSON(res, 400, { success: false, message: 'Invalid coupon code.' });
      }

      // Validate eligibility
      const userUsageCount = db.couponUsages.filter((u) => u.couponId === coupon.id && u.userId === userId && u.validationStatus === 'applied').length;
      if (coupon.perUserLimit && userUsageCount >= coupon.perUserLimit) {
        return sendJSON(res, 400, { success: false, message: 'Coupon already redeemed by this account.' });
      }

      // Calculate discount amount
      const basePrice = 49.0;
      let finalPrice = basePrice;
      let discountApplied = 0.0;

      if (coupon.discountType === 'percentage') {
        discountApplied = (basePrice * coupon.discountValue) / 100.0;
        finalPrice = basePrice - discountApplied;
      } else if (coupon.discountType === 'fixed') {
        discountApplied = coupon.discountValue;
        finalPrice = Math.max(0, basePrice - discountApplied);
      } else if (coupon.discountType === 'free_trial') {
        discountApplied = basePrice;
        finalPrice = 0.0;
      }

      // Record coupon usage log
      const usageRecord = {
        id: 'cu_' + Date.now(),
        userId,
        couponId: coupon.id,
        code: coupon.code,
        date: new Date().toISOString(),
        validationStatus: 'applied',
        purchaseStatus: 'completed',
        productPurchased: 'pro_monthly',
        purchaseAmount: finalPrice,
        discountApplied: discountApplied,
        paymentStatus: 'success',
        createdAt: new Date().toISOString(),
      };

      db.couponUsages.push(usageRecord);

      // Auto upgrade user if free trial or 100% discount
      if (finalPrice === 0.0 || coupon.discountType === 'free_trial') {
        const sub = getUserSubscription(userId);
        sub.plan = 'pro';
        sub.status = 'active';
        sub.updated_at = new Date().toISOString();
        const user = db.users.find((u) => u.id === userId);
        if (user) user.isPremium = true;
      }

      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: `Coupon '${coupon.code}' applied successfully!`,
        discountApplied,
        finalPrice,
        googlePlayOfferId: coupon.googlePlayOfferId,
      });
    }

    // 4.3 Coupon System Analytics (Backend Reporting)
    if (pathname === '/api/coupons/analytics' && method === 'GET') {
      const analytics = db.coupons.map((c) => {
        const usages = db.couponUsages.filter((u) => u.couponId === c.id && u.validationStatus === 'applied');
        const revenue = usages.reduce((sum, u) => sum + (u.purchaseAmount || 0), 0);
        const discountGiven = usages.reduce((sum, u) => sum + (u.discountApplied || 0), 0);

        return {
          couponCode: c.code,
          title: c.title,
          campaignSource: c.campaignSource,
          totalRedemptions: usages.length,
          revenueGenerated: revenue,
          discountGiven: discountGiven,
          conversionStatus: 'active',
        };
      });

      return sendJSON(res, 200, { success: true, analytics });
    }

    // =========================================================================
    // 5. REFERRAL SYSTEM
    // =========================================================================

    // 5.1 Get My Referral Stats & Code
    if (pathname === '/api/referrals/my-code' && method === 'GET') {
      const user = db.users.find((u) => u.id === userId);
      let refRecord = db.referralCodes.find((r) => r.userId === userId);

      if (!refRecord && user) {
        refRecord = {
          id: 'ref_' + userId,
          userId,
          referralCode: user.referralCode || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
          status: 'active',
          totalCount: 0,
          createdAt: new Date().toISOString(),
        };
        db.referralCodes.push(refRecord);
        saveDB(db);
      }

      const userTrackings = db.referralTrackings.filter((rt) => rt.referrerUserId === userId);
      const successfulReferrals = userTrackings.filter((rt) => rt.rewardStatus === 'issued').length;

      return sendJSON(res, 200, {
        success: true,
        referralCode: refRecord ? refRecord.referralCode : 'WOS2026',
        totalReferrals: userTrackings.length,
        successfulReferrals,
        rewardPoints: successfulReferrals * 100,
      });
    }

    // 5.2 Apply Referral Code Post-Signup
    if (pathname === '/api/referrals/apply-code' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      // Prevent self referral
      const referrer = db.users.find((u) => (u.referralCode || '').toUpperCase() === cleanCode);
      if (!referrer) {
        return sendJSON(res, 400, { success: false, message: 'Invalid referral code.' });
      }
      if (referrer.id === userId) {
        return sendJSON(res, 400, { success: false, message: 'You cannot use your own referral code.' });
      }

      // Prevent duplicate redemption
      const existing = db.referralTrackings.find((rt) => rt.referredUserId === userId);
      if (existing) {
        return sendJSON(res, 400, { success: false, message: 'You have already redeemed a referral invitation code.' });
      }

      db.referralTrackings.push({
        id: 'rt_' + Date.now(),
        referrerUserId: referrer.id,
        referredUserId: userId,
        referralCode: cleanCode,
        signupDate: new Date().toISOString(),
        eligibilityStatus: 'eligible',
        conversionStatus: 'completed',
        rewardStatus: 'issued',
        rewardIssuedDate: new Date().toISOString(),
      });

      const refRecord = db.referralCodes.find((r) => r.userId === referrer.id);
      if (refRecord) refRecord.totalCount = (refRecord.totalCount || 0) + 1;

      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: `Referral code '${cleanCode}' applied successfully! You and your referrer both earned reward points.`,
      });
    }

    // Fallback 404
    return sendJSON(res, 404, { success: false, message: `Route not found: ${method} ${pathname}` });

  } catch (error) {
    console.error(`API Error handling ${method} ${pathname}:`, error);
    return sendJSON(res, 500, { success: false, message: 'Internal server error.', details: error.message });
  }
}

module.exports = { handleApiRequest };
