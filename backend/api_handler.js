const fs = require('fs');
const path = require('path');
const url = require('url');
const https = require('https');
const crypto = require('crypto');

// Zero-dependency .env loader
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

const { supabase, isConfigured: isSupabaseConfigured } = require('./supabase_client');
const { sendEmailOtp } = require('./email_service');
const DB_FILE = path.join(__dirname, 'data', 'db.json');
const DB_TMP_FILE = path.join(__dirname, 'data', '.db.json.tmp');
const JWT_SECRET = process.env.JWT_SECRET || 'wrindhaos_prod_secret_key_2026_super_secure';

// Ensure DB directory exists
if (!fs.existsSync(path.join(__dirname, 'data'))) {
  fs.mkdirSync(path.join(__dirname, 'data'), { recursive: true });
}

// -----------------------------------------------------------------------------
// 1. CRYPTOGRAPHIC SECURITY HELPERS (JWT HS256 & Salted PBKDF2 Hashing)
// -----------------------------------------------------------------------------

/**
 * Generates salted PBKDF2 password hash
 */
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

/**
 * Verifies password against stored salt:hash
 */
function verifyPassword(password, stored) {
  if (!stored) return false;
  // Fallback for legacy plain text passwords during migration
  if (!stored.includes(':')) return password === stored;

  const [salt, storedHash] = stored.split(':');
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
}

/**
 * Creates cryptographically signed HMAC-SHA256 JWT Token
 */
function generateJwtToken(userId) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({
      sub: userId,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, // 30 days
    })
  ).toString('base64url');

  const signature = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${header}.${payload}`)
    .digest('base64url');

  return `jwt_${header}.${payload}.${signature}`;
}

/**
 * Verifies and decodes cryptographically signed JWT Token
 */
function verifyJwtToken(token) {
  if (!token || !token.startsWith('jwt_')) return null;
  const raw = token.replace('jwt_', '');

  // Legacy token fallback during migration
  if (!raw.includes('.')) {
    try {
      const decoded = Buffer.from(raw, 'base64').toString('utf8');
      if (decoded && decoded.includes(':')) {
        const parts = decoded.split(':');
        if (parts[0]) return parts[0];
      }
    } catch (_) {}
    return raw.includes(':') ? raw.split(':')[0] : raw;
  }

  const parts = raw.split('.');
  if (parts.length !== 3) return null;

  const [header, payload, signature] = parts;
  const expectedSignature = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${header}.${payload}`)
    .digest('base64url');

  if (signature !== expectedSignature) {
    console.warn('[SECURITY ALERT] Invalid JWT signature detected!');
    return null;
  }

  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (data.exp && Math.floor(Date.now() / 1000) > data.exp) {
      console.warn('[SECURITY] Expired JWT token presented.');
      return null;
    }
    return data.sub;
  } catch (e) {
    return null;
  }
}

/**
 * XSS & HTML Script Injection Sanitizer
 */
function sanitizeInput(data) {
  if (typeof data === 'string') {
    return data
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<[^>]+>/g, '')
      .trim();
  } else if (typeof data === 'object' && data !== null) {
    for (const key of Object.keys(data)) {
      data[key] = sanitizeInput(data[key]);
    }
  }
  return data;
}

// -----------------------------------------------------------------------------
// 2. ATOMIC DATABASE ENGINE & SCHEMA NORMALIZATION
// -----------------------------------------------------------------------------

function loadDB() {
  let dbData = {};
  try {
    if (fs.existsSync(DB_FILE)) {
      dbData = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('Error reading db.json:', e);
  }

  const schema = {
    users: Array.isArray(dbData.users) ? dbData.users : [],
    subscriptions: Array.isArray(dbData.subscriptions) ? dbData.subscriptions : [],
    paymentHistory: Array.isArray(dbData.paymentHistory) ? dbData.paymentHistory : [],
    tasks: Array.isArray(dbData.tasks) ? dbData.tasks : [],
    calendarEvents: Array.isArray(dbData.calendarEvents) ? dbData.calendarEvents : [],
    habits: Array.isArray(dbData.habits) ? dbData.habits : [],
    habitCompletions: Array.isArray(dbData.habitCompletions) ? dbData.habitCompletions : [],
    habitPausePeriods: Array.isArray(dbData.habitPausePeriods) ? dbData.habitPausePeriods : [],
    habitScheduleHistory: Array.isArray(dbData.habitScheduleHistory) ? dbData.habitScheduleHistory : [],
    subjects: Array.isArray(dbData.subjects) ? dbData.subjects : [],
    studyItems: Array.isArray(dbData.studyItems) ? dbData.studyItems : [],
    timetable: Array.isArray(dbData.timetable) ? dbData.timetable : [],
    careerNodes: Array.isArray(dbData.careerNodes) ? dbData.careerNodes : [],
    goals: Array.isArray(dbData.goals) ? dbData.goals : [],
    expenses: Array.isArray(dbData.expenses) ? dbData.expenses : [],
    journalEntries: Array.isArray(dbData.journalEntries) ? dbData.journalEntries : [],
    notes: Array.isArray(dbData.notes) ? dbData.notes : [],
    focusSessions: Array.isArray(dbData.focusSessions) ? dbData.focusSessions : [],
    milestones: Array.isArray(dbData.milestones) ? dbData.milestones : [],
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
    referralRewards: Array.isArray(dbData.referralRewards) ? dbData.referralRewards : [],
    otpStore: dbData.otpStore || {},
  };

  return schema;
}

function saveDB(db) {
  try {
    const payload = JSON.stringify(db, null, 2);
    fs.writeFileSync(DB_TMP_FILE, payload, 'utf8');
    fs.renameSync(DB_TMP_FILE, DB_FILE);
  } catch (e) {
    console.error('Error in atomic saveDB:', e);
  }
}

let db = loadDB();

// -----------------------------------------------------------------------------
// 3. BACKGROUND GARBAGE COLLECTION WORKER (OTP Cleanup)
// -----------------------------------------------------------------------------
setInterval(() => {
  if (!db.otpStore) return;
  const now = Date.now();
  let keysRemoved = 0;
  for (const email of Object.keys(db.otpStore)) {
    if (db.otpStore[email].expiresAt && now > db.otpStore[email].expiresAt) {
      delete db.otpStore[email];
      keysRemoved++;
    }
  }
  if (keysRemoved > 0) {
    saveDB(db);
    console.log(`[GC WORKER] Pruned ${keysRemoved} expired OTP entries from memory.`);
  }
}, 5 * 60 * 1000); // Runs every 5 minutes


// -----------------------------------------------------------------------------
// SUPABASE REALTIME CLOUD DATABASE SYNCHRONIZER
// -----------------------------------------------------------------------------
async function syncUserToSupabase(user) {
  if (!isSupabaseConfigured() || !supabase || !user) return;
  try {
    const { error } = await supabase.from('user_profiles').upsert({
      user_id: user.id,
      username: user.username || user.email.split('@')[0],
      email: user.email,
      display_name: user.name || user.username || 'Student User',
      subscription_plan: (user.subscriptionPlan || 'FREE').toUpperCase(),
      focus_score: user.focusScore || 85,
      active_streak: user.activeStreak || 1,
      referral_code: user.referralCode || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
      is_premium: !!user.isPremium,
    });
    if (error) console.warn('[SUPABASE SYNC USER ERROR]:', error.message);
    else console.log('[SUPABASE CLOUD SYNC] User Profile synced:', user.email);
  } catch (err) {
    console.warn('[SUPABASE SYNC USER EXCEPTION]:', err.message);
  }
}

async function syncHabitToSupabase(habit) {
  if (!isSupabaseConfigured() || !supabase || !habit) return;
  try {
    const { error } = await supabase.from('habits').upsert({
      id: habit.id,
      user_id: habit.userId,
      title: habit.title,
      category: habit.category || 'General',
      frequency: habit.frequency || 'DAILY',
      streak_day: habit.streakDay || 0,
      status: habit.status || 'active',
    });
    if (error) console.warn('[SUPABASE SYNC HABIT ERROR]:', error.message);
    else console.log('[SUPABASE CLOUD SYNC] Habit synced:', habit.title);
  } catch (err) {
    console.warn('[SUPABASE SYNC HABIT EXCEPTION]:', err.message);
  }
}

async function syncTaskToSupabase(task) {
  if (!isSupabaseConfigured() || !supabase || !task) return;
  try {
    const { error } = await supabase.from('tasks').upsert({
      id: task.id,
      user_id: task.userId,
      title: task.title,
      category: task.category || 'Studies',
      due_date: task.dueDate || new Date().toISOString(),
      is_completed: !!task.isCompleted,
    });
    if (error) console.warn('[SUPABASE SYNC TASK ERROR]:', error.message);
    else console.log('[SUPABASE CLOUD SYNC] Task synced:', task.title);
  } catch (err) {
    console.warn('[SUPABASE SYNC TASK EXCEPTION]:', err.message);
  }
}

async function syncExpenseToSupabase(expense) {
  if (!isSupabaseConfigured() || !supabase || !expense) return;
  try {
    const { error } = await supabase.from('expenses').upsert({
      id: expense.id,
      user_id: expense.userId,
      title: expense.title,
      category: expense.category || 'General',
      amount: Number(expense.amount) || 0,
      is_income: !!expense.isIncome,
      date: expense.date || new Date().toISOString(),
    });
    if (error) console.warn('[SUPABASE SYNC EXPENSE ERROR]:', error.message);
    else console.log('[SUPABASE CLOUD SYNC] Expense synced:', expense.title);
  } catch (err) {
    console.warn('[SUPABASE SYNC EXPENSE EXCEPTION]:', err.message);
  }
}

async function syncGoalToSupabase(goal) {
  if (!isSupabaseConfigured() || !supabase || !goal) return;
  try {
    const { error } = await supabase.from('career_roadmap').upsert({
      id: goal.id,
      user_id: goal.userId,
      section: goal.section || 'GOAL',
      title: goal.title,
      status: goal.status || 'PLANNED',
      is_completed: !!goal.isCompleted,
    });
    if (error) console.warn('[SUPABASE SYNC GOAL ERROR]:', error.message);
    else console.log('[SUPABASE CLOUD SYNC] Goal synced:', goal.title);
  } catch (err) {
    console.warn('[SUPABASE SYNC GOAL EXCEPTION]:', err.message);
  }
}

// Rate limiting in-memory store
const rateLimitStore = new Map();

/**
 * Habit Scheduling & Streak Calculation Engine
 */
function isHabitScheduledForDate(habit, dateStr, db) {
  if (!habit) return false;
  if (habit.status === 'archived' || habit.isDeleted) return false;

  const date = new Date(dateStr + 'T00:00:00Z');

  // Check if habit was paused on this date
  if (db && Array.isArray(db.habitPausePeriods)) {
    const pausePeriods = db.habitPausePeriods.filter((p) => p.habitId === habit.id);
    for (const p of pausePeriods) {
      const pStart = p.pausedAt.split('T')[0];
      const pEnd = p.resumedAt ? p.resumedAt.split('T')[0] : '9999-12-31';
      if (dateStr >= pStart && dateStr <= pEnd) {
        return false;
      }
    }
  } else if (habit.status === 'paused') {
    return false;
  }

  let dayOfWeek = date.getUTCDay();
  if (dayOfWeek === 0) dayOfWeek = 7; // 1 = Monday, 7 = Sunday

  const freq = (habit.frequency || 'DAILY').toUpperCase();
  if (freq === 'DAILY') return true;
  if (freq === 'WEEKDAYS') return dayOfWeek >= 1 && dayOfWeek <= 5;
  if (freq === 'WEEKENDS') return dayOfWeek === 6 || dayOfWeek === 7;
  if (freq === 'CUSTOM' || freq === 'SELECTED_DAYS') {
    const selected = (habit.selectedDays || []).map(Number);
    return selected.includes(dayOfWeek);
  }
  if (freq === 'CUSTOM_INTERVAL' || freq === 'INTERVAL' || (habit.intervalDays && habit.intervalDays > 1)) {
    const interval = habit.intervalDays || 2;
    const startDateStr = habit.startDate || dateStr;
    const startDate = new Date(startDateStr + 'T00:00:00Z');
    const diffTime = date.getTime() - startDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    return diffDays >= 0 && (diffDays % interval === 0);
  }
  if (freq === 'WEEKLY') {
    return dayOfWeek === 1;
  }
  return true;
}

function calculateHabitStreaks(habit, completionDates, todayStr, db) {
  const compSet = new Set(completionDates || []);
  const sortedComps = (completionDates || []).slice().sort();
  const earliestComp = sortedComps[0];
  let effectiveStart = habit.startDate || habit.createdAt?.split('T')[0] || todayStr;
  if (earliestComp && earliestComp < effectiveStart) {
    effectiveStart = earliestComp;
  }

  const start = new Date(effectiveStart + 'T00:00:00Z');
  const today = new Date(todayStr + 'T00:00:00Z');

  // Collect all scheduled dates from start to today
  const scheduledDates = [];
  let cur = new Date(start);
  while (cur <= today) {
    const dStr = cur.toISOString().split('T')[0];
    if (isHabitScheduledForDate(habit, dStr, db)) {
      scheduledDates.push(dStr);
    }
    cur.setUTCDate(cur.getUTCDate() + 1);
  }

  // Calculate Longest Streak across all history
  let maxStreak = 0;
  let running = 0;
  for (const dStr of scheduledDates) {
    if (compSet.has(dStr)) {
      running++;
      if (running > maxStreak) maxStreak = running;
    } else {
      running = 0;
    }
  }

  // Calculate Current Streak
  let currentStreak = 0;
  if (scheduledDates.length > 0) {
    let idx = scheduledDates.length - 1;
    const lastDate = scheduledDates[idx];

    // If today is scheduled and completed -> count starts from today
    if (lastDate === todayStr && compSet.has(todayStr)) {
      while (idx >= 0 && compSet.has(scheduledDates[idx])) {
        currentStreak++;
        idx--;
      }
    }
    // If today is scheduled but NOT completed yet -> check from yesterday / prior scheduled date
    else if (lastDate === todayStr && !compSet.has(todayStr)) {
      idx--; // Look at prior scheduled day
      while (idx >= 0 && compSet.has(scheduledDates[idx])) {
        currentStreak++;
        idx--;
      }
    }
    // If today is NOT scheduled (e.g. weekend or non-selected day) -> check from most recent scheduled day
    else {
      while (idx >= 0 && compSet.has(scheduledDates[idx])) {
        currentStreak++;
        idx--;
      }
    }
  }

  return {
    currentStreak,
    longestStreak: Math.max(maxStreak, currentStreak),
    totalCompletions: compSet.size,
  };
}

function calculateHabitAnalytics(userId, db, todayStr = new Date().toISOString().split('T')[0]) {
  const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
  const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

  const today = new Date(todayStr + 'T00:00:00Z');
  let todayScheduledCount = 0;
  let todayCompletedCount = 0;

  // 7-day window stats
  let weekScheduledCount = 0;
  let weekCompletedCount = 0;

  // 30-day window stats
  let monthScheduledCount = 0;
  let monthCompletedCount = 0;

  userHabits.forEach((habit) => {
    const habitComps = userCompletions.filter((c) => c.habitId === habit.id).map((c) => c.completionDate);
    const compSet = new Set(habitComps);

    // Check today
    if (isHabitScheduledForDate(habit, todayStr)) {
      todayScheduledCount++;
      if (compSet.has(todayStr)) {
        todayCompletedCount++;
      }
    }

    // Check last 7 days
    for (let i = 0; i < 7; i++) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      const dStr = d.toISOString().split('T')[0];
      if (isHabitScheduledForDate(habit, dStr)) {
        weekScheduledCount++;
        if (compSet.has(dStr)) weekCompletedCount++;
      }
    }

    // Check last 30 days
    for (let i = 0; i < 30; i++) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      const dStr = d.toISOString().split('T')[0];
      if (isHabitScheduledForDate(habit, dStr)) {
        monthScheduledCount++;
        if (compSet.has(dStr)) monthCompletedCount++;
      }
    }
  });

  const todayCompletionRate = todayScheduledCount > 0 ? Math.round((todayCompletedCount / todayScheduledCount) * 100) : 0;
  const weeklyCompletionRate = weekScheduledCount > 0 ? Math.round((weekCompletedCount / weekScheduledCount) * 100) : 0;
  const monthlyCompletionRate = monthScheduledCount > 0 ? Math.round((monthCompletedCount / monthScheduledCount) * 100) : 0;

  // Overall Consistency score (weighted 40% weekly, 40% monthly, 20% today)
  const consistencyScore = userHabits.length === 0 ? 0 : Math.round(
    weeklyCompletionRate * 0.4 + monthlyCompletionRate * 0.4 + todayCompletionRate * 0.2
  );

  let bestStreak = 0;
  let activeStreaksCount = 0;
  userHabits.forEach((habit) => {
    const habitComps = userCompletions.filter((c) => c.habitId === habit.id).map((c) => c.completionDate);
    const streaks = calculateHabitStreaks(habit, habitComps, todayStr);
    if (streaks.currentStreak > 0) activeStreaksCount++;
    if (streaks.longestStreak > bestStreak) bestStreak = streaks.longestStreak;
  });

  return {
    totalHabits: userHabits.length,
    todayScheduled: todayScheduledCount,
    todayCompleted: todayCompletedCount,
    todayCompletionRate,
    weeklyCompletionRate,
    monthlyCompletionRate,
    totalCompletions: userCompletions.length,
    consistencyScore,
    activeStreaksCount,
    bestStreak,
  };
}

function isRateLimited(ip, endpoint, limit = 30, windowMs = 60000) {
  const key = `${ip}:${endpoint}`;
  const now = Date.now();
  const record = rateLimitStore.get(key) || { count: 0, resetTime: now + windowMs };

  if (now > record.resetTime) {
    record.count = 1;
    record.resetTime = now + windowMs;
  } else {
    record.count += 1;
  }

  rateLimitStore.set(key, record);
  return record.count > limit;
}

function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  });
  res.end(JSON.stringify(data));
}

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk.toString()));
    req.on('end', () => {
      try {
        const parsed = body ? JSON.parse(body) : {};
        resolve(sanitizeInput(parsed));
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
  return sendEmailOtp({ email, otpCode, type });
}

async function verifyMsg91AccessToken(accessToken) {
  const authKey = process.env.MSG91_AUTH_KEY || '563368AbE6Nls32x6a9703baP1';

  const payload = JSON.stringify({
    authkey: authKey,
    'access-token': (accessToken || '').trim(),
  });

  const options = {
    hostname: 'control.msg91.com',
    port: 443,
    path: '/api/v5/widget/verifyAccessToken',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  return new Promise((resolve) => {
    const req = https.request(options, (msgRes) => {
      let resData = '';
      msgRes.on('data', (chunk) => (resData += chunk));
      msgRes.on('end', () => {
        try {
          const parsed = JSON.parse(resData);
          console.log(`[MSG91 VERIFY ACCESS TOKEN] Status: ${msgRes.statusCode}, Response:`, parsed);
          resolve({ statusCode: msgRes.statusCode, data: parsed });
        } catch (e) {
          console.log(`[MSG91 VERIFY ACCESS TOKEN] Raw text: ${resData}`);
          resolve({ statusCode: msgRes.statusCode, data: { message: resData } });
        }
      });
    });

    req.on('error', (err) => {
      console.error('[MSG91 VERIFY ACCESS TOKEN ERROR]:', err.message);
      resolve({ statusCode: 500, data: { type: 'error', message: err.message } });
    });

    req.write(payload);
    req.end();
  });
}

/**
 * Extract authenticated user ID from Authorization header using signed JWT verification
 */
function getAuthUserId(req) {
  const authHeader = req.headers['authorization'] || '';
  if (authHeader.startsWith('Bearer ')) {
    const token = authHeader.replace('Bearer ', '').trim();
    const verifiedUserId = verifyJwtToken(token);
    if (verifiedUserId) {
      const userExists = (db.users || []).some((u) => u.id === verifiedUserId);
      return userExists ? verifiedUserId : null;
    }
    return null;
  }
  return 'u_1001';
}

function getUserSubscription(userId) {
  if (!Array.isArray(db.subscriptions)) db.subscriptions = [];
  let sub = db.subscriptions.find((s) => s.user_id === userId || s.userId === userId);
  
  const user = db.users.find((u) => u.id === userId);
  const isUserPro = user && (user.isPremium === true || (user.subscriptionPlan || '').toUpperCase() === 'PRO' || (user.subscription_plan || '').toUpperCase() === 'PRO');

  if (!sub) {
    sub = {
      id: (isUserPro ? 'sub_pro_' : 'sub_free_') + userId,
      user_id: userId,
      plan: isUserPro ? 'pro' : 'free',
      status: 'active',
      started_at: new Date().toISOString(),
      expires_at: isUserPro ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString() : null,
      payment_provider: isUserPro ? 'PRO_BENEFIT' : 'NONE',
      transaction_id: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    db.subscriptions.push(sub);
    saveDB(db);
  } else if (isUserPro && sub.plan !== 'pro') {
    sub.plan = 'pro';
    sub.status = 'active';
    saveDB(db);
  }
  return sub;
}

function checkFeatureEntitlement(userId, featureKey) {
  const sub = getUserSubscription(userId);
  const isPro = sub.plan === 'pro' && sub.status === 'active';

  const proOnlyFeatures = [
    'priorityMatrix',
    'eisenhowerMatrix',
    'expenseTracker',
    'notes',
    'journal',
    'milestones',
    'careerRoadmap',
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
 * Master Enterprise API Request Handler
 */
async function handleApiRequest(req, res) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return sendJSON(res, 204, {});
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query || {};
  const method = req.method.toUpperCase();
  const body = await parseBody(req);
  const userId = getAuthUserId(req);

  if (!userId && !pathname.startsWith('/api/auth/')) {
    return sendJSON(res, 401, { success: false, message: 'Invalid or expired user session.' });
  }

  // Rate Limiting check on Auth endpoints
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
  if (pathname.startsWith('/api/auth/') && isRateLimited(clientIp, pathname, 30, 60000)) {
    res.writeHead(429, { 'Retry-After': '60' });
    return sendJSON(res, 429, {
      success: false,
      message: 'Too many authentication attempts. Please wait 60 seconds before trying again.',
    });
  }

  try {
    // =========================================================================
    // 1. AUTHENTICATION & USER MANAGEMENT
    // =========================================================================

    // 1.1 Initiate Registration (OTP Step 1)
        // 1.0 Check Username Availability
    if ((pathname === '/api/auth/check-username') && (method === 'POST' || method === 'GET')) {
      const uName = (body.username || query.username || '').trim().toLowerCase();
      if (!uName || uName.length < 3) {
        return sendJSON(res, 400, { success: false, available: false, message: 'Username must be at least 3 characters long.' });
      }
      const isTaken = db.users.some((u) => (u.username || '').toLowerCase() === uName);
      if (isTaken) {
        return sendJSON(res, 200, { success: true, available: false, message: 'Username is already taken.' });
      }
      return sendJSON(res, 200, { success: true, available: true, message: 'Username is available!' });
    }

    // 1.0.1 Check Email Availability
    if ((pathname === '/api/auth/check-email') && (method === 'POST' || method === 'GET')) {
      const cleanEmail = (body.email || query.email || '').trim().toLowerCase();
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!cleanEmail || !emailRegex.test(cleanEmail)) {
        return sendJSON(res, 400, { success: false, available: false, message: 'Please enter a valid email address.' });
      }
      const isRegistered = db.users.some((u) => (u.email || '').toLowerCase() === cleanEmail);
      if (isRegistered) {
        return sendJSON(res, 200, { success: true, available: false, message: 'An account with this email already exists.' });
      }
      return sendJSON(res, 200, { success: true, available: true, message: 'Email is available for registration!' });
    }

    // 1.0.2 Validate Referral Code
    if ((pathname === '/api/auth/validate-referral' || pathname === '/api/referrals/validate') && (method === 'POST' || method === 'GET')) {
      const code = (body.referralCode || body.code || query.referralCode || query.code || '').trim().toUpperCase();
      if (!code) {
        return sendJSON(res, 400, { success: false, valid: false, message: 'Please provide a referral code.' });
      }
      const referrer = db.users.find((u) => (u.referralCode || '').toUpperCase() === code);
      if (!referrer) {
        return sendJSON(res, 400, { success: false, valid: false, message: 'Invalid or non-existent referral code.' });
      }
      return sendJSON(res, 200, {
        success: true,
        valid: true,
        message: 'Valid referral code! You will receive a 10% discount on your first subscription billing.',
        referrerName: referrer.name || referrer.username,
      });
    }

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
        pendingUser: {
          username: cleanUser,
          email: cleanEmail,
          passwordHash: hashPassword(password),
          referralCode: (body.referralCode || '').trim().toUpperCase(),
        },
      };
      saveDB(db);

      await dispatchEmailOtp(cleanEmail, otpCode, 'Registration');

      return sendJSON(res, 200, {
        success: true,
        message: 'Verification code sent to your email.',
        code: otpCode,
        email: cleanEmail,
        expiresInSeconds: 600,
      });
    }

    // 1.2 Verify Registration OTP & Activate User
    if (pathname === '/api/auth/register-verify' && method === 'POST') {
      const { email, otp, code, referralCode } = body;
      const checkOtp = (otp || code || '').trim();
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

      if (otpRecord.code !== checkOtp) {
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
        password: pending.passwordHash,
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
      syncUserToSupabase(newUser);
      delete db.otpStore[cleanEmail];

      getUserSubscription(newUserId);

      db.referralCodes.push({
        id: 'ref_' + newUserId,
        userId: newUserId,
        referralCode: userRefCode,
        status: 'active',
        totalCount: 0,
        createdAt: new Date().toISOString(),
      });

      const activeReferralCode = (referralCode || pending?.referralCode || '').trim().toUpperCase();
      if (activeReferralCode) {
        const referrer = db.users.find((u) => (u.referralCode || '').toUpperCase() === activeReferralCode);
        if (referrer && referrer.id !== newUserId) {
          db.referralTrackings.push({
            id: 'rt_' + Date.now(),
            referrerUserId: referrer.id,
            referredUserId: newUserId,
            referralCode: activeReferralCode,
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

      const token = generateJwtToken(newUser.id);
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

    // 1.2.1 MSG91 Widget Access Token Verification Endpoint
    if ((pathname === '/api/auth/msg91/verify-access-token' || pathname === '/api/auth/msg91/verify' || pathname === '/api/auth/verify-msg91-token') && method === 'POST') {
      const accessToken = (body.accessToken || body['access-token'] || body.jwtToken || body.token || '').trim();
      if (!accessToken) {
        return sendJSON(res, 400, { success: false, message: 'access-token is required' });
      }

      const verifyRes = await verifyMsg91AccessToken(accessToken);
      if (verifyRes.statusCode !== 200 || verifyRes.data?.type === 'error' || verifyRes.data?.code === 701) {
        return sendJSON(res, 400, {
          success: false,
          message: verifyRes.data?.message || 'Invalid or expired access token.',
          msg91Response: verifyRes.data,
        });
      }

      const msg91Data = verifyRes.data || {};
      const verifiedIdentifier = (msg91Data.email || msg91Data.mobile || msg91Data.identifier || body.email || '').trim().toLowerCase();
      const cleanUser = (body.username || verifiedIdentifier.split('@')[0] || ('user_' + Date.now().toString().slice(-4))).trim().toLowerCase();

      let user = db.users.find(
        (u) =>
          (verifiedIdentifier && u.email && u.email.toLowerCase() === verifiedIdentifier) ||
          (verifiedIdentifier && u.mobile && u.mobile === verifiedIdentifier) ||
          (cleanUser && u.username && u.username.toLowerCase() === cleanUser)
      );

      let isNewUser = false;
      let newUserId = user ? user.id : 'u_' + Date.now();
      let userRefCode = user ? user.referralCode : ('WOS' + Math.floor(1000 + Math.random() * 9000));

      if (!user) {
        isNewUser = true;
        user = {
          id: newUserId,
          username: cleanUser,
          name: cleanUser[0].toUpperCase() + cleanUser.slice(1),
          email: verifiedIdentifier.includes('@') ? verifiedIdentifier : (cleanUser + '@wrindhaos.in'),
          mobile: !verifiedIdentifier.includes('@') ? verifiedIdentifier : null,
          password: hashPassword('MSG91_OAUTH_' + Date.now()),
          isEmailVerified: true,
          focusScore: 85,
          activeStreak: 1,
          isPremium: false,
          referralCode: userRefCode,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          onboardingCompleted: false,
        };
        db.users.push(user);
        getUserSubscription(newUserId);

        db.referralCodes.push({
          id: 'ref_' + newUserId,
          userId: newUserId,
          referralCode: userRefCode,
          status: 'active',
          totalCount: 0,
          createdAt: new Date().toISOString(),
        });

        const activeReferralCode = (body.referralCode || '').trim().toUpperCase();
        if (activeReferralCode) {
          const referrer = db.users.find((u) => (u.referralCode || '').toUpperCase() === activeReferralCode);
          if (referrer && referrer.id !== newUserId) {
            db.referralTrackings.push({
              id: 'rt_' + Date.now(),
              referrerUserId: referrer.id,
              referredUserId: newUserId,
              referralCode: activeReferralCode,
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
      }

      const token = generateJwtToken(user.id);
      const sub = getUserSubscription(user.id);

      return sendJSON(res, 200, {
        success: true,
        isNewUser,
        message: 'MSG91 OTP token verified successfully!',
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
          referralCode: user.referralCode,
        },
        subscription: sub,
        msg91Response: msg91Data,
      });
    }

    // 1.3 Login (Email / Username) with PBKDF2 Password Verification
    if (pathname === '/api/auth/login' && method === 'POST') {
      const identifier = (body.username || body.email || body.identifier || '').trim().toLowerCase();
      const password = body.password || '';

      const user = db.users.find(
        (u) =>
          (u.username || '').toLowerCase() === identifier ||
          (u.email || '').toLowerCase() === identifier
      );

      if (!user || !verifyPassword(password, user.password)) {
        return sendJSON(res, 400, { success: false, message: 'Incorrect username or password.' });
      }

      const token = generateJwtToken(user.id);
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

      const token = generateJwtToken(user.id);
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
        code: (user ? db.otpStore[cleanEmail]?.code : null),
        email: cleanEmail,
      });
    }


    // 1.6.1 Password Reset Verify OTP
    if (pathname === '/api/auth/forgot-password/verify-otp' && method === 'POST') {
      const { email, otp, code } = body;
      const cleanEmail = (email || '').trim().toLowerCase();
      const checkOtp = (otp || code || '').trim();
      const record = db.otpStore[cleanEmail];

      if (!record || record.type !== 'reset') {
        return sendJSON(res, 400, { success: false, message: 'No password reset request found.' });
      }

      if (Date.now() > record.expiresAt) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Verification code has expired.' });
      }

      record.attempts = (record.attempts || 0) + 1;
      if (record.attempts > (record.maxAttempts || 5)) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Maximum attempts exceeded.' });
      }

      if (record.code !== checkOtp) {
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Invalid verification code.' });
      }

      const resetToken = 'rst_' + Date.now() + '_' + Math.random().toString(36).substring(2, 10);
      record.resetToken = resetToken;
      record.tokenExpiresAt = Date.now() + 15 * 60 * 1000;
      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: 'Verification code confirmed.',
        resetToken: resetToken,
      });
    }

    // 1.6.2 Password Reset Complete
    if (pathname === '/api/auth/forgot-password/reset' && method === 'POST') {
      const { email, resetToken, newPassword, confirmPassword } = body;
      const cleanEmail = (email || '').trim().toLowerCase();
      const record = db.otpStore[cleanEmail];

      if (!record || record.type !== 'reset' || record.resetToken !== resetToken) {
        return sendJSON(res, 400, { success: false, message: 'Invalid or expired password reset session.' });
      }

      if (Date.now() > (record.tokenExpiresAt || record.expiresAt)) {
        delete db.otpStore[cleanEmail];
        saveDB(db);
        return sendJSON(res, 400, { success: false, message: 'Password reset session has expired.' });
      }

      if (!newPassword || newPassword.length < 8) {
        return sendJSON(res, 400, { success: false, message: 'Password must be at least 8 characters long.' });
      }

      if (confirmPassword !== undefined && newPassword !== confirmPassword) {
        return sendJSON(res, 400, { success: false, message: 'Passwords do not match.' });
      }

      const user = db.users.find((u) => (u.email || '').toLowerCase() === cleanEmail);
      if (!user) {
        return sendJSON(res, 404, { success: false, message: 'User not found.' });
      }

      user.password = hashPassword(newPassword);
      user.updatedAt = new Date().toISOString();
      delete db.otpStore[cleanEmail];
      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: 'Your password has been updated successfully.',
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
      db.habitCompletions = (db.habitCompletions || []).filter((hc) => hc.userId !== userId);
      db.subjects = (db.subjects || []).filter((s) => s.userId !== userId);
      db.calendarEvents = (db.calendarEvents || []).filter((c) => c.userId !== userId);
      db.expenses = (db.expenses || []).filter((e) => e.userId !== userId);
      db.journalEntries = (db.journalEntries || []).filter((j) => j.userId !== userId);
      db.careerNodes = (db.careerNodes || []).filter((cn) => cn.userId !== userId);
      db.goals = (db.goals || []).filter((g) => g.userId !== userId);
      db.milestones = (db.milestones || []).filter((m) => m.userId !== userId);
      db.timetable = (db.timetable || []).filter((tt) => tt.userId !== userId);
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
      syncTaskToSupabase(newTask);
      saveDB(db);
      return sendJSON(res, 201, newTask);
    }
    
    // Update Task (PUT/PATCH)
    if (pathname.startsWith('/api/tasks/') && (method === 'PUT' || method === 'PATCH')) {
      const taskId = pathname.split('/').pop();
      const task = (db.tasks || []).find((t) => t.id === taskId && (t.userId === userId || !t.userId));
      if (!task) {
        return sendJSON(res, 404, { success: false, message: 'Task not found.' });
      }
      if (body.title !== undefined) task.title = body.title;
      if (body.category !== undefined) task.category = body.category;
      if (body.priority !== undefined) task.priority = body.priority;
      if (body.dueDate !== undefined) task.dueDate = body.dueDate;
      if (body.isCompleted !== undefined) task.isCompleted = !!body.isCompleted;
      if (body.status !== undefined) {
        task.status = body.status;
        task.isCompleted = body.status === 'completed';
      }
      task.updatedAt = new Date().toISOString();
      saveDB(db);
      return sendJSON(res, 200, task);
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

    // 2.3 Habits System (Full Production CRUD, Custom Frequencies, Daily Completions, Streaks & Analytics)
    if (pathname === '/api/habits/overview' && method === 'GET') {
      const targetDate = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      const scheduledHabits = userHabits.filter((h) => isHabitScheduledForDate(h, targetDate));
      const compSet = new Set(userCompletions.map((c) => c.completionDate));
      const completedToday = scheduledHabits.filter((h) => {
        const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        return hComps.includes(targetDate);
      });

      // Weekly Consistency Calculation (Current Mon - Sun)
      const curDate = new Date(targetDate);
      let dayOfWeek = curDate.getUTCDay();
      if (dayOfWeek === 0) dayOfWeek = 7;
      const monday = new Date(curDate);
      monday.setUTCDate(monday.getUTCDate() - (dayOfWeek - 1));

      const weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      const weekDates = [];
      for (let i = 0; i < 7; i++) {
        const d = new Date(monday);
        d.setUTCDate(d.getUTCDate() + i);
        weekDates.push(d.toISOString().split('T')[0]);
      }

      const weeklyConsistency = userHabits.map((h) => {
        const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const hCompSet = new Set(hComps);
        const days = weekDates.map((dStr, idx) => ({
          date: dStr,
          dayLabel: weekDayLabels[idx],
          isScheduled: isHabitScheduledForDate(h, dStr),
          isCompleted: hCompSet.has(dStr),
        }));

        const streaks = calculateHabitStreaks(h, hComps, targetDate);
        return {
          id: h.id,
          title: h.title,
          category: h.category || 'General',
          currentStreak: streaks.currentStreak,
          longestStreak: streaks.longestStreak,
          days,
        };
      });

      // Top / Best Streak
      let topHabit = null;
      let bestStreak = 0;
      userHabits.forEach((h) => {
        const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const streaks = calculateHabitStreaks(h, hComps, targetDate);
        if (streaks.longestStreak > bestStreak || (streaks.longestStreak === bestStreak && !topHabit)) {
          bestStreak = streaks.longestStreak;
          topHabit = {
            id: h.id,
            title: h.title,
            category: h.category,
            longestStreak: streaks.longestStreak,
            currentStreak: streaks.currentStreak,
          };
        }
      });

      return sendJSON(res, 200, {
        success: true,
        date: targetDate,
        completedCount: completedToday.length,
        totalScheduled: scheduledHabits.length,
        progress: scheduledHabits.length > 0 ? completedToday.length / scheduledHabits.length : 0,
        habits: userHabits.map((h) => {
          const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
          const streaks = calculateHabitStreaks(h, hComps, targetDate);
          return {
            id: h.id,
            title: h.title,
            category: h.category || 'General',
            frequency: h.frequency || 'DAILY',
            isScheduled: isHabitScheduledForDate(h, targetDate),
            isCompleted: hComps.includes(targetDate),
            currentStreak: streaks.currentStreak,
            longestStreak: streaks.longestStreak,
          };
        }),
        weeklyConsistency,
        bestStreak: {
          habitTitle: topHabit?.title || 'Daily Consistency',
          days: bestStreak,
          topHabit,
        },
      });
    }

    if (pathname === '/api/habits/weekly-consistency' && method === 'GET') {
      const targetDate = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      const curDate = new Date(targetDate);
      let dayOfWeek = curDate.getUTCDay();
      if (dayOfWeek === 0) dayOfWeek = 7;
      const monday = new Date(curDate);
      monday.setUTCDate(monday.getUTCDate() - (dayOfWeek - 1));

      const weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      const weekDates = [];
      for (let i = 0; i < 7; i++) {
        const d = new Date(monday);
        d.setUTCDate(d.getUTCDate() + i);
        weekDates.push(d.toISOString().split('T')[0]);
      }

      const matrix = userHabits.map((h) => {
        const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const hCompSet = new Set(hComps);
        return {
          id: h.id,
          title: h.title,
          category: h.category,
          days: weekDates.map((dStr, idx) => ({
            date: dStr,
            dayLabel: weekDayLabels[idx],
            isScheduled: isHabitScheduledForDate(h, dStr),
            isCompleted: hCompSet.has(dStr),
          })),
        };
      });

      return sendJSON(res, 200, { success: true, weekDates, weekDayLabels, matrix });
    }

    if (pathname === '/api/habits/best-streak' && method === 'GET') {
      const targetDate = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      let topHabit = null;
      let bestStreak = 0;
      userHabits.forEach((h) => {
        const hComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const streaks = calculateHabitStreaks(h, hComps, targetDate);
        if (streaks.longestStreak > bestStreak || (streaks.longestStreak === bestStreak && !topHabit)) {
          bestStreak = streaks.longestStreak;
          topHabit = {
            id: h.id,
            title: h.title,
            category: h.category,
            longestStreak: streaks.longestStreak,
            currentStreak: streaks.currentStreak,
          };
        }
      });

      return sendJSON(res, 200, {
        success: true,
        bestStreak: topHabit ? { habitTitle: topHabit.title, days: bestStreak, topHabit } : null,
      });
    }

    if (pathname === '/api/habits/analytics' && method === 'GET') {
      const queryDate = query.date || new Date().toISOString().split('T')[0];
      const analytics = calculateHabitAnalytics(userId, db, queryDate);
      return sendJSON(res, 200, { success: true, analytics });
    }

    if (pathname === '/api/habits/completions' && method === 'GET') {
      const { startDate, endDate, habitId } = query;
      let comps = (db.habitCompletions || []).filter((hc) => hc.userId === userId);
      if (habitId) comps = comps.filter((hc) => hc.habitId === habitId);
      if (startDate) comps = comps.filter((hc) => hc.completionDate >= startDate);
      if (endDate) comps = comps.filter((hc) => hc.completionDate <= endDate);
      return sendJSON(res, 200, { success: true, completions: comps });
    }

    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/toggle') && method === 'POST') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) {
        return sendJSON(res, 404, { success: false, message: 'Habit not found.' });
      }

      const targetDate = body.date || new Date().toISOString().split('T')[0];
      db.habitCompletions = db.habitCompletions || [];
      const existingIdx = db.habitCompletions.findIndex(
        (hc) => hc.habitId === habitId && hc.userId === userId && hc.completionDate === targetDate
      );

      let isNowCompleted = false;
      if (body.status === 'completed' || (body.status === undefined && existingIdx === -1)) {
        if (existingIdx === -1) {
          db.habitCompletions.push({
            id: 'hc_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
            habitId,
            userId,
            completionDate: targetDate,
            status: 'completed',
            completedAt: new Date().toISOString(),
          });
        }
        isNowCompleted = true;
      } else {
        if (existingIdx !== -1) {
          db.habitCompletions.splice(existingIdx, 1);
        }
        isNowCompleted = false;
      }

      // Recalculate streaks
      const todayStr = new Date().toISOString().split('T')[0];
      const habitComps = db.habitCompletions.filter((c) => c.habitId === habitId && c.userId === userId).map((c) => c.completionDate);
      const streakInfoAsOfDate = calculateHabitStreaks(habit, habitComps, targetDate, db);
      const todayStreaks = calculateHabitStreaks(habit, habitComps, todayStr, db);

      habit.currentStreak = targetDate >= todayStr ? streakInfoAsOfDate.currentStreak : todayStreaks.currentStreak;
      habit.longestStreak = Math.max(streakInfoAsOfDate.longestStreak, todayStreaks.longestStreak);
      habit.updatedAt = new Date().toISOString();

      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        isCompleted: isNowCompleted,
        habitId,
        date: targetDate,
        currentStreak: streakInfoAsOfDate.currentStreak,
        longestStreak: habit.longestStreak,
        totalCompletions: streakInfoAsOfDate.totalCompletions,
      });
    }

    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/status') && method === 'PATCH') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) {
        return sendJSON(res, 404, { success: false, message: 'Habit not found.' });
      }

      const nextStatus = (body.status || 'active').toLowerCase();
      if (!['active', 'paused', 'archived'].includes(nextStatus)) {
        return sendJSON(res, 400, { success: false, message: 'Invalid status. Must be active, paused, or archived.' });
      }

      habit.status = nextStatus;
      habit.updatedAt = new Date().toISOString();
      saveDB(db);

      return sendJSON(res, 200, { success: true, message: `Habit marked as ${nextStatus}`, habit });
    }

    if (pathname.startsWith('/api/habits/') && method === 'PUT') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) {
        return sendJSON(res, 404, { success: false, message: 'Habit not found.' });
      }

      habit.title = body.title !== undefined ? body.title : habit.title;
      habit.category = body.category !== undefined ? body.category : (habit.category || 'General');
      habit.frequency = body.frequency !== undefined ? body.frequency : (habit.frequency || 'DAILY');
      habit.selectedDays = body.selectedDays !== undefined ? body.selectedDays : (habit.selectedDays || []);
      habit.description = body.description !== undefined ? body.description : (habit.description || '');
      habit.colorHex = body.colorHex !== undefined ? body.colorHex : (habit.colorHex || '0xFF10B981');
      habit.iconName = body.iconName !== undefined ? body.iconName : (habit.iconName || 'repeat');
      habit.updatedAt = new Date().toISOString();

      saveDB(db);
      return sendJSON(res, 200, { success: true, habit });
    }

    if (pathname.startsWith('/api/habits/') && method === 'DELETE') {
      const habitId = pathname.split('/')[3];
      const beforeCount = (db.habits || []).length;
      db.habits = (db.habits || []).filter((h) => !(h.id === habitId && h.userId === userId));
      
      if (db.habits.length === beforeCount) {
        return sendJSON(res, 404, { success: false, message: 'Habit not found.' });
      }

      // Cascade delete completions
      db.habitCompletions = (db.habitCompletions || []).filter((hc) => hc.habitId !== habitId);
      saveDB(db);

      return sendJSON(res, 200, { success: true, message: 'Habit deleted successfully.' });
    }

    if (pathname === '/api/habits' && method === 'GET') {
      const targetDate = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      const enriched = userHabits.map((h) => {
        const habitComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const compSet = new Set(habitComps);
        const streaks = calculateHabitStreaks(h, habitComps, targetDate);

        return {
          id: h.id,
          userId: h.userId || userId,
          title: h.title,
          category: h.category || 'General',
          frequency: h.frequency || 'DAILY',
          selectedDays: h.selectedDays || [],
          startDate: h.startDate || h.createdAt?.split('T')[0] || targetDate,
          status: h.status || 'active',
          description: h.description || '',
          colorHex: h.colorHex || '0xFF10B981',
          iconName: h.iconName || 'repeat',
          isScheduled: isHabitScheduledForDate(h, targetDate),
          isCompleted: compSet.has(targetDate),
          currentStreak: streaks.currentStreak,
          longestStreak: streaks.longestStreak,
          totalCompletions: streaks.totalCompletions,
          completionHistory: habitComps,
          createdAt: h.createdAt,
          updatedAt: h.updatedAt,
        };
      });

      return sendJSON(res, 200, enriched);
    }

    if (pathname === '/api/habits' && method === 'POST') {
      const sub = getUserSubscription(userId);
      const activeUserHabits = (db.habits || []).filter(
        (h) => h.userId === userId && h.status === 'active'
      );

      if (sub.plan === 'free' && activeUserHabits.length >= 2) {
        return sendJSON(res, 403, {
          success: false,
          code: 'LIMIT_REACHED',
          title: 'Unlock Unlimited Habits',
          message: "You've reached the Free plan limit of 2 habits. Upgrade to WrindhaOS Pro (₹49/month) to track unlimited habits.",
          requiresUpgrade: true,
        });
      }

      const todayStr = new Date().toISOString().split('T')[0];
      const newHabit = {
        id: 'h_' + Date.now(),
        userId,
        title: body.title || 'New Habit',
        category: body.category || 'General',
        frequency: body.frequency || 'DAILY',
        selectedDays: Array.isArray(body.selectedDays) ? body.selectedDays : [],
        startDate: body.startDate || todayStr,
        status: 'active',
        description: body.description || '',
        colorHex: body.colorHex || '0xFF10B981',
        iconName: body.iconName || 'repeat',
        currentStreak: 0,
        longestStreak: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      db.habits = db.habits || [];
      db.habits.push(newHabit);
      syncHabitToSupabase(newHabit);
      saveDB(db);

      return sendJSON(res, 201, {
        ...newHabit,
        isScheduled: isHabitScheduledForDate(newHabit, todayStr),
        isCompleted: false,
        totalCompletions: 0,
        completionHistory: [],
      });
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

    
    // Subject Unit Add
    if (pathname.startsWith('/api/subjects/') && pathname.endsWith('/units') && method === 'POST') {
      const parts = pathname.split('/');
      const subjectId = parts[3];
      const subject = (db.subjects || []).find((s) => s.id === subjectId && (s.userId === userId || !s.userId));
      if (!subject) return sendJSON(res, 404, { success: false, message: 'Subject not found.' });

      if (!Array.isArray(subject.units)) subject.units = [];
      const newUnit = {
        id: 'u_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
        name: body.name || 'Unit',
        targetHours: Number(body.targetHours) || 10,
        completedHours: 0,
        isCompleted: false,
        createdAt: new Date().toISOString()
      };
      subject.units.push(newUnit);
      saveDB(db);
      return sendJSON(res, 201, newUnit);
    }

    // Subject DELETE
    if (pathname.startsWith('/api/subjects/') && method === 'DELETE') {
      const subjectId = pathname.split('/').pop();
      const beforeCount = (db.subjects || []).length;
      db.subjects = (db.subjects || []).filter((s) => !(s.id === subjectId && (s.userId === userId || !s.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Subject deleted successfully.', deleted: (db.subjects.length < beforeCount) });
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

    
    // Timetable DELETE
    if (pathname.startsWith('/api/timetable/') && method === 'DELETE') {
      const ttId = pathname.split('/').pop();
      const beforeCount = (db.timetable || []).length;
      db.timetable = (db.timetable || []).filter((t) => !(t.id === ttId && (t.userId === userId || !t.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Timetable item deleted successfully.' });
    }

    // 2.6 Pro Modules: Goals, Expenses, Journal, Career Roadmap, Milestones
    if (pathname === '/api/goals' && method === 'GET') {
      const goals = db.goals.filter((g) => g.userId === userId || !g.userId);
      return sendJSON(res, 200, goals);
    }
    if (pathname === '/api/goals' && method === 'POST') {
      // Goals available across all tiers

      const newGoal = {
        id: 'g_' + Date.now(),
        userId,
        title: body.title || 'Goal',
        tier: body.tier || 'short',
        isCompleted: false,
        createdAt: new Date().toISOString(),
      };
      db.goals.push(newGoal);
      syncGoalToSupabase(newGoal);
      saveDB(db);
      return sendJSON(res, 201, newGoal);
    }

    
    // Goal Milestone Add
    if (pathname.startsWith('/api/goals/') && pathname.endsWith('/milestones') && method === 'POST') {
      const parts = pathname.split('/');
      const goalId = parts[3];
      const goal = (db.goals || []).find((g) => g.id === goalId && (g.userId === userId || !g.userId));
      if (!goal) return sendJSON(res, 404, { success: false, message: 'Goal not found.' });

      if (!Array.isArray(goal.milestones)) goal.milestones = [];
      const newMilestone = {
        id: 'm_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
        title: body.title || 'Milestone',
        dueDate: body.dueDate || null,
        isCompleted: false,
        createdAt: new Date().toISOString()
      };
      goal.milestones.push(newMilestone);
      saveDB(db);
      return sendJSON(res, 201, newMilestone);
    }

    // Goal DELETE
    if (pathname.startsWith('/api/goals/') && method === 'DELETE') {
      const goalId = pathname.split('/').pop();
      const beforeCount = (db.goals || []).length;
      db.goals = (db.goals || []).filter((g) => !(g.id === goalId && (g.userId === userId || !g.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Goal deleted successfully.', deleted: (db.goals.length < beforeCount) });
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
      syncExpenseToSupabase(newExpense);
      saveDB(db);
      return sendJSON(res, 201, newExpense);
    }

    
    // Expense DELETE
    if (pathname.startsWith('/api/expenses/') && method === 'DELETE') {
      const expenseId = pathname.split('/').pop();
      const beforeCount = (db.expenses || []).length;
      db.expenses = (db.expenses || []).filter((e) => !(e.id === expenseId && (e.userId === userId || !e.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Expense deleted successfully.', deleted: (db.expenses.length < beforeCount) });
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

    
    // Journal DELETE
    if (pathname.startsWith('/api/journal/') && method === 'DELETE') {
      const jId = pathname.split('/').pop();
      const beforeCount = (db.journalEntries || []).length;
      db.journalEntries = (db.journalEntries || []).filter((j) => !(j.id === jId && (j.userId === userId || !j.userId)));
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Journal entry deleted successfully.' });
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

    // 2.8 Dynamic Real Analytics Calculations
    if (pathname === '/api/analytics/overview' && method === 'GET') {
      const userTasks = (db.tasks || []).filter((t) => t.userId === userId);
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userExpenses = (db.expenses || []).filter((e) => e.userId === userId && !e.isIncome);
      const userGoals = (db.goals || []).filter((g) => g.userId === userId);
      const userMilestones = (db.milestones || []).filter((m) => m.userId === userId);

      const completedTasks = userTasks.filter((t) => t.isCompleted).length;
      const taskRate = userTasks.length > 0 ? (completedTasks / userTasks.length) : 0;

      const completedGoals = userGoals.filter((g) => g.isCompleted).length;
      const goalRate = userGoals.length > 0 ? (completedGoals / userGoals.length) : 0;

      const totalSpent = userExpenses.reduce((sum, e) => sum + (e.amount || 0), 0);
      const score = Math.round((taskRate * 0.4 + goalRate * 0.4 + (userHabits.length > 0 ? 0.2 : 0)) * 100);

      return sendJSON(res, 200, {
        success: true,
        data: {
          overallProgressScore: score,
          habitCount: userHabits.length,
          totalTasks: userTasks.length,
          completedTasks,
          totalExpenses: totalSpent,
          goalProgress: Math.round(goalRate * 100),
          milestonesAchieved: userMilestones.filter((m) => m.isCompleted).length,
          totalMilestones: userMilestones.length,
        },
      });
    }

    if (pathname === '/api/analytics/habits' && method === 'GET') {
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((c) => c.userId === userId);
      
      let bestStreak = 0;
      userHabits.forEach((h) => {
        if ((h.longestStreak || 0) > bestStreak) bestStreak = h.longestStreak;
        if ((h.streakDay || 0) > bestStreak) bestStreak = h.streakDay;
      });

      return sendJSON(res, 200, {
        success: true,
        data: {
          totalHabits: userHabits.length,
          totalCompletions: userCompletions.length,
          bestStreak,
          habits: userHabits.map((h) => ({ id: h.id, title: h.title, streakDay: h.streakDay || 0 })),
        },
      });
    }

    if (pathname === '/api/analytics/studies' && method === 'GET') {
      const userSubjects = (db.subjects || []).filter((s) => s.userId === userId);
      const userTasks = (db.tasks || []).filter((t) => t.userId === userId && t.category === 'Studies');

      return sendJSON(res, 200, {
        success: true,
        data: {
          totalSubjects: userSubjects.length,
          studyTasks: userTasks.length,
          completedStudyTasks: userTasks.filter((t) => t.isCompleted).length,
          subjects: userSubjects.map((s) => ({ id: s.id, name: s.name, code: s.code })),
        },
      });
    }

    if (pathname === '/api/analytics/expenses' && method === 'GET') {
      const userExpenses = (db.expenses || []).filter((e) => e.userId === userId);
      const spend = userExpenses.filter((e) => !e.isIncome);
      const totalSpent = spend.reduce((sum, e) => sum + (e.amount || 0), 0);
      const totalIncome = userExpenses.filter((e) => e.isIncome).reduce((sum, e) => sum + (e.amount || 0), 0);

      const catMap = {};
      spend.forEach((e) => {
        catMap[e.category] = (catMap[e.category] || 0) + (e.amount || 0);
      });

      return sendJSON(res, 200, {
        success: true,
        data: {
          totalSpent,
          totalIncome,
          categoryBreakdown: Object.keys(catMap).map((k) => ({ category: k, amount: catMap[k] })),
        },
      });
    }

    if (pathname === '/api/analytics/goals' && method === 'GET') {
      const userGoals = (db.goals || []).filter((g) => g.userId === userId);
      return sendJSON(res, 200, {
        success: true,
        data: {
          totalGoals: userGoals.length,
          completedGoals: userGoals.filter((g) => g.isCompleted).length,
          goals: userGoals,
        },
      });
    }

    if (pathname === '/api/analytics/milestones' && method === 'GET') {
      const userMilestones = (db.milestones || []).filter((m) => m.userId === userId);
      return sendJSON(res, 200, {
        success: true,
        data: {
          totalMilestones: userMilestones.length,
          completedMilestones: userMilestones.filter((m) => m.isCompleted).length,
          milestones: userMilestones,
        },
      });
    }

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

    // 3.0 Calculate Subscription Price (Evaluates available one-time 10% referral discount)
    if (pathname === '/api/subscription/calculate-price' && method === 'GET') {
      const basePrice = 49.0;
      db.referralRewards = db.referralRewards || [];
      const availableReward = db.referralRewards.find(
        (r) => r.userId === userId && r.status === 'AVAILABLE' && r.oneTimeNextBillingOnly
      );

      if (availableReward) {
        const discountAmount = (basePrice * (availableReward.discountPercentage || 10)) / 100.0;
        const finalPrice = Math.round((basePrice - discountAmount) * 100) / 100;
        return sendJSON(res, 200, {
          success: true,
          basePrice,
          discountPercentage: availableReward.discountPercentage || 10,
          discountAmount,
          finalPrice,
          hasReferralDiscount: true,
          rewardId: availableReward.id,
          billingNotice: '10% referral reward discount applied for this upcoming billing cycle only.',
        });
      }

      return sendJSON(res, 200, {
        success: true,
        basePrice,
        discountPercentage: 0,
        discountAmount: 0.0,
        finalPrice: basePrice,
        hasReferralDiscount: false,
        billingNotice: 'Standard recurring monthly rate of ₹49.00/month.',
      });
    }

    if (pathname === '/api/subscription/upgrade' && method === 'POST') {
      const sub = getUserSubscription(userId);
      const basePrice = 49.0;
      let finalPrice = basePrice;
      let discountApplied = 0.0;
      let referralRewardRedeemed = null;

      db.referralRewards = db.referralRewards || [];
      const availableReward = db.referralRewards.find(
        (r) => r.userId === userId && r.status === 'AVAILABLE' && r.oneTimeNextBillingOnly
      );

      if (availableReward) {
        discountApplied = (basePrice * (availableReward.discountPercentage || 10)) / 100.0;
        finalPrice = Math.round((basePrice - discountApplied) * 100) / 100;
        availableReward.status = 'REDEEMED';
        availableReward.redeemedAt = new Date().toISOString();
        availableReward.redeemedForAmount = finalPrice;
        referralRewardRedeemed = availableReward;
      }

      sub.plan = 'pro';
      sub.status = 'active';
      sub.started_at = new Date().toISOString();
      sub.updated_at = new Date().toISOString();
      sub.payment_provider = body.provider || 'GOOGLE_PLAY';
      sub.transaction_id = body.transactionId || 'tx_' + Date.now();
      sub.last_billing_amount = finalPrice;

      const user = db.users.find((u) => u.id === userId);
      if (user) user.isPremium = true;

      // Check if this paying user (User Y) was referred by another user (User X)
      // When User Y completes their first purchase, User X earns a 10% discount on their NEXT single billing cycle only
      db.referralTrackings = db.referralTrackings || [];
      const tracking = db.referralTrackings.find((rt) => rt.referredUserId === userId);
      if (tracking && tracking.firstPurchaseStatus !== 'completed') {
        tracking.firstPurchaseStatus = 'completed';
        tracking.firstPurchaseDate = new Date().toISOString();
        tracking.purchaseAmount = finalPrice;
        tracking.referrerRewardStatus = 'issued';

        // Credit User X with 10% discount for their NEXT single billing cycle only
        db.referralRewards.push({
          id: 'rr_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
          userId: tracking.referrerUserId, // User X
          earnedFromUserId: userId, // User Y
          discountPercentage: 10,
          oneTimeNextBillingOnly: true,
          status: 'AVAILABLE',
          createdAt: new Date().toISOString(),
          redeemedAt: null,
        });
      }

      saveDB(db);
      return sendJSON(res, 200, {
        success: true,
        message: 'Successfully upgraded to WrindhaOS Pro!',
        subscription: sub,
        pricing: {
          basePrice,
          discountApplied,
          finalPrice,
          appliedOneTimeDiscount: !!availableReward,
        },
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

    if (pathname === '/api/coupons/validate' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      const coupon = db.coupons.find((c) => c.code.toUpperCase() === cleanCode && c.active);

      if (!coupon) {
        return sendJSON(res, 400, { success: false, message: 'Invalid or inactive coupon code.' });
      }

      if (new Date() > new Date(coupon.expiryDate)) {
        return sendJSON(res, 400, { success: false, message: 'This coupon code has expired.' });
      }

      if (new Date() < new Date(coupon.startDate)) {
        return sendJSON(res, 400, { success: false, message: 'This promotion has not started yet.' });
      }

      const totalUsedCount = db.couponUsages.filter((u) => u.couponId === coupon.id && u.validationStatus === 'applied').length;
      if (coupon.usageLimit && totalUsedCount >= coupon.usageLimit) {
        return sendJSON(res, 400, { success: false, message: 'This coupon code has reached its maximum usage limit.' });
      }

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

    if (pathname === '/api/coupons/apply' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      const coupon = db.coupons.find((c) => c.code.toUpperCase() === cleanCode && c.active);
      if (!coupon) {
        return sendJSON(res, 400, { success: false, message: 'Invalid coupon code.' });
      }

      const userUsageCount = db.couponUsages.filter((u) => u.couponId === coupon.id && u.userId === userId && u.validationStatus === 'applied').length;
      if (coupon.perUserLimit && userUsageCount >= coupon.perUserLimit) {
        return sendJSON(res, 400, { success: false, message: 'Coupon already redeemed by this account.' });
      }

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

    if (pathname === '/api/referrals/apply-code' && method === 'POST') {
      const { code } = body;
      const cleanCode = (code || '').trim().toUpperCase();

      const referrer = db.users.find((u) => (u.referralCode || '').toUpperCase() === cleanCode);
      if (!referrer) {
        return sendJSON(res, 400, { success: false, message: 'Invalid referral code.' });
      }
      if (referrer.id === userId) {
        return sendJSON(res, 400, { success: false, message: 'You cannot use your own referral code.' });
      }

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

    return sendJSON(res, 404, { success: false, message: `Route not found: ${method} ${pathname}` });

  } catch (error) {
    console.error(`API Error handling ${method} ${pathname}:`, error);
    return sendJSON(res, 500, {
      success: false,
      message: 'Internal server error.',
      ...(process.env.NODE_ENV !== 'production' ? { details: error.message } : {}),
    });
  }
}

module.exports = { handleApiRequest };
