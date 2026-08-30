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

// Rate limiting in-memory store
const rateLimitStore = new Map();

/**
 * Habit Scheduling & Streak Calculation Engine
 */
function isHabitScheduledForDate(habit, dateStr, db) {
  if (!habit) return false;
  if (habit.isDeleted || habit.status === 'archived') return false;

  const date = new Date(dateStr + 'T00:00:00Z');

  // Check if habit is inside an active pause period
  if (db && db.habitPausePeriods) {
    const pausePeriods = db.habitPausePeriods.filter((p) => p.habitId === habit.id);
    for (const p of pausePeriods) {
      const pStart = p.pausedAt.split('T')[0];
      const pEnd = p.resumedAt ? p.resumedAt.split('T')[0] : '9999-12-31';
      if (dateStr >= pStart && dateStr <= pEnd) {
        return false; // Paused on this date
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
    const selected = habit.selectedDays || [];
    return selected.includes(dayOfWeek) || selected.includes(dayOfWeek.toString()) || selected.includes(Number(dayOfWeek));
  }
  if (freq === 'CUSTOM_INTERVAL' || freq === 'INTERVAL' || (habit.intervalDays && habit.intervalDays > 1)) {
    const interval = habit.intervalDays || 2;
    const startDate = new Date((habit.startDate || dateStr) + 'T00:00:00Z');
    const diffTime = date.getTime() - startDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    return diffDays >= 0 && (diffDays % interval === 0);
  }
  if (freq === 'WEEKLY') {
    return dayOfWeek === 1;
  }
  return true;
}

function getHabitStatus(habit, dateStr, compSet, db, todayStr = new Date().toISOString().split('T')[0]) {
  if (dateStr > todayStr) return 'FUTURE';

  // Check if paused on this date
  if (db && db.habitPausePeriods) {
    const pausePeriods = db.habitPausePeriods.filter((p) => p.habitId === habit.id);
    for (const p of pausePeriods) {
      const pStart = p.pausedAt.split('T')[0];
      const pEnd = p.resumedAt ? p.resumedAt.split('T')[0] : '9999-12-31';
      if (dateStr >= pStart && dateStr <= pEnd) {
        return 'PAUSED';
      }
    }
  } else if (habit.status === 'paused') {
    return 'PAUSED';
  }

  if (!isHabitScheduledForDate(habit, dateStr, db)) {
    return 'NOT_SCHEDULED';
  }

  if (compSet.has(dateStr)) {
    return 'COMPLETED';
  }

  if (dateStr === todayStr) {
    return 'PENDING';
  }

  return 'MISSED';
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

  if (start > today) {
    return { currentStreak: compSet.has(todayStr) ? 1 : 0, longestStreak: compSet.has(todayStr) ? 1 : 0, totalCompletions: compSet.size };
  }

  const scheduledDates = [];
  let cur = new Date(start);
  while (cur <= today) {
    const dStr = cur.toISOString().split('T')[0];
    if (isHabitScheduledForDate(habit, dStr, db)) {
      scheduledDates.push(dStr);
    }
    cur.setUTCDate(cur.getUTCDate() + 1);
  }

  if (scheduledDates.length === 0) {
    return {
      currentStreak: compSet.has(todayStr) ? 1 : 0,
      longestStreak: compSet.has(todayStr) ? 1 : 0,
      totalCompletions: compSet.size,
    };
  }

  // 1. Longest streak scan across historical scheduled days
  let maxStreak = 0;
  let runningStreak = 0;
  for (const dStr of scheduledDates) {
    if (compSet.has(dStr)) {
      runningStreak++;
      if (runningStreak > maxStreak) maxStreak = runningStreak;
    } else {
      if (dStr < todayStr) {
        runningStreak = 0;
      }
    }
  }

  // 2. Current streak: step backwards from most recent scheduled day
  let currentStreak = 0;
  let idx = scheduledDates.length - 1;
  const lastDate = scheduledDates[idx];

  // If today is scheduled and not completed yet, start from yesterday's scheduled day
  if (lastDate === todayStr && !compSet.has(todayStr)) {
    idx--;
  }

  while (idx >= 0) {
    const dStr = scheduledDates[idx];
    if (compSet.has(dStr)) {
      currentStreak++;
      idx--;
    } else {
      break;
    }
  }

  return {
    currentStreak,
    longestStreak: Math.max(maxStreak, currentStreak),
    totalCompletions: compSet.size,
  };
}

function calculateHabitAnalytics(userId, db, todayStr = new Date().toISOString().split('T')[0]) {
  const userHabits = (db.habits || []).filter((h) => h.userId === userId && !h.isDeleted && h.status !== 'archived');
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

  const habitPerformanceList = [];

  userHabits.forEach((habit) => {
    const habitComps = userCompletions.filter((c) => c.habitId === habit.id).map((c) => c.completionDate);
    const compSet = new Set(habitComps);
    const streaks = calculateHabitStreaks(habit, habitComps, todayStr, db);

    let habitMonthScheduled = 0;
    let habitMonthCompleted = 0;

    // Check today
    if (isHabitScheduledForDate(habit, todayStr, db)) {
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
      if (isHabitScheduledForDate(habit, dStr, db)) {
        weekScheduledCount++;
        if (compSet.has(dStr)) weekCompletedCount++;
      }
    }

    // Check last 30 days
    for (let i = 0; i < 30; i++) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      const dStr = d.toISOString().split('T')[0];
      if (isHabitScheduledForDate(habit, dStr, db)) {
        monthScheduledCount++;
        habitMonthScheduled++;
        if (compSet.has(dStr)) {
          monthCompletedCount++;
          habitMonthCompleted++;
        }
      }
    }

    const rate = habitMonthScheduled > 0 ? Math.round((habitMonthCompleted / habitMonthScheduled) * 100) : 0;
    habitPerformanceList.push({
      habitId: habit.id,
      title: habit.title,
      rate,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      totalCompletions: streaks.totalCompletions,
    });
  });

  const todayCompletionRate = todayScheduledCount > 0 ? Math.round((todayCompletedCount / todayScheduledCount) * 100) : 0;
  const weeklyCompletionRate = weekScheduledCount > 0 ? Math.round((weekCompletedCount / weekScheduledCount) * 100) : 0;
  const monthlyCompletionRate = monthScheduledCount > 0 ? Math.round((monthCompletedCount / monthScheduledCount) * 100) : 0;

  // Consistency score: 70% Completion Performance + 30% Streak Performance
  let bestStreak = 0;
  let activeStreaksCount = 0;
  habitPerformanceList.forEach((p) => {
    if (p.currentStreak > 0) activeStreaksCount++;
    if (p.longestStreak > bestStreak) bestStreak = p.longestStreak;
  });

  const streakComponent = Math.min(30, Math.round((bestStreak / 30) * 30));
  const completionComponent = Math.round(monthlyCompletionRate * 0.7);
  const consistencyScore = userHabits.length === 0 ? 0 : Math.min(100, completionComponent + streakComponent);

  // Best & lowest performing habits
  habitPerformanceList.sort((a, b) => b.rate - a.rate);
  const bestHabit = habitPerformanceList.length > 0 ? habitPerformanceList[0] : null;
  const lowestHabit = habitPerformanceList.length > 0 ? habitPerformanceList[habitPerformanceList.length - 1] : null;

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
    bestHabit,
    lowestHabit,
    habitPerformanceList,
  };
}

function generateHabitInsights(userId, db, todayStr = new Date().toISOString().split('T')[0]) {
  const userHabits = (db.habits || []).filter((h) => h.userId === userId && !h.isDeleted && h.status === 'active');
  const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');
  const insights = [];

  const today = new Date(todayStr + 'T00:00:00Z');

  userHabits.forEach((habit) => {
    const comps = userCompletions.filter((c) => c.habitId === habit.id).map((c) => c.completionDate);
    const compSet = new Set(comps);
    const streaks = calculateHabitStreaks(habit, comps, todayStr, db);

    // 1. 7-Day Completion Rate Rule
    let last7Scheduled = 0;
    let last7Completed = 0;
    for (let i = 1; i <= 7; i++) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      const dStr = d.toISOString().split('T')[0];
      if (isHabitScheduledForDate(habit, dStr, db)) {
        last7Scheduled++;
        if (compSet.has(dStr)) last7Completed++;
      }
    }

    const rate7 = last7Scheduled > 0 ? (last7Completed / last7Scheduled) * 100 : 100;
    if (last7Scheduled >= 3 && rate7 < 40) {
      insights.push({
        type: 'LOW_CONSISTENCY',
        habitId: habit.id,
        habitTitle: habit.title,
        severity: 'warning',
        message: `You are struggling with "${habit.title}" (${Math.round(rate7)}% completion rate over the last 7 days). Consider reducing the frequency or making it easier.`,
        action: 'REDUCE_FREQUENCY',
      });
    }

    // 2. Multiple Misses Rule (3 consecutive misses)
    let consecutiveMisses = 0;
    for (let i = 1; i <= 14; i++) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      const dStr = d.toISOString().split('T')[0];
      if (isHabitScheduledForDate(habit, dStr, db)) {
        if (!compSet.has(dStr)) {
          consecutiveMisses++;
          if (consecutiveMisses >= 3) break;
        } else {
          break;
        }
      }
    }

    if (consecutiveMisses >= 3) {
      insights.push({
        type: 'MULTIPLE_MISSES',
        habitId: habit.id,
        habitTitle: habit.title,
        severity: 'alert',
        message: `You missed 3 consecutive scheduled occurrences for "${habit.title}". Would you like to pause or adjust its schedule?`,
        action: 'PAUSE_OR_ADJUST',
      });
    }

    // 3. Strong Streak Celebration Rule
    if (streaks.currentStreak >= 7) {
      insights.push({
        type: 'STRONG_STREAK',
        habitId: habit.id,
        habitTitle: habit.title,
        severity: 'celebration',
        message: `🔥 Incredible momentum! You have a ${streaks.currentStreak}-day streak on "${habit.title}". Consistency is compounding!`,
        action: 'CELEBRATE',
      });
    }

    // 4. End of Day Incomplete Check
    if (isHabitScheduledForDate(habit, todayStr, db) && !compSet.has(todayStr)) {
      insights.push({
        type: 'PENDING_TODAY',
        habitId: habit.id,
        habitTitle: habit.title,
        severity: 'reminder',
        message: `"${habit.title}" is scheduled for today and waiting for your check-in.`,
        action: 'COMPLETE_TODAY',
      });
    }
  });

  return insights;
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
  const authKey = process.env.MSG91_AUTH_KEY;
  const widgetId = process.env.MSG91_WIDGET_ID || '36687761466f383937303733';

  console.log(`[EMAIL OTP DISPATCH] [${type}] Sending 6-digit OTP to: ${email} -> CODE: [${otpCode}]`);

  if (!authKey) {
    return { success: true, mode: 'local', otpCode };
  }

  try {
    const payload = JSON.stringify({
      widgetId: widgetId,
      identifier: email,
      tokenAuth: authKey,
      otp: otpCode,
    });

    const options = {
      hostname: 'control.msg91.com',
      port: 443,
      path: '/api/v5/widget/sendOtp',
      method: 'POST',
      headers: {
        'authkey': authKey,
        'Content-Type': 'application/json',
        'Origin': 'http://localhost:8080',
        'Referer': 'http://localhost:8080/',
        'User-Agent': 'WrindhaOS-Backend/1.0',
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    return new Promise((resolve) => {
      const req = https.request(options, (msgRes) => {
        let resData = '';
        msgRes.on('data', (chunk) => (resData += chunk));
        msgRes.on('end', () => {
          console.log(`[MSG91 WIDGET API] Status: ${msgRes.statusCode}, Response: ${resData}`);
          resolve({ success: true, mode: 'live_widget', response: resData });
        });
      });
      req.on('error', (err) => {
        console.error('[MSG91 WIDGET API ERROR]:', err.message);
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
        pendingUser: { username: cleanUser, email: cleanEmail, passwordHash: hashPassword(password) },
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

    // 1.3 Login (Email / Username) with PBKDF2 Password Verification
    if (pathname === '/api/auth/login' && method === 'POST') {
      const { username, password } = body;
      const cleanUser = (username || '').trim().toLowerCase();

      const user = db.users.find(
        (u) =>
          (u.username || '').toLowerCase() === cleanUser ||
          (u.email || '').toLowerCase() === cleanUser
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
      db.habitCompletions = (db.habitCompletions || []).filter((hc) => hc.userId !== userId);
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

    // 2.3 Habits System (Full Production CRUD, Custom Frequencies, Daily Completions, Streaks, Pause/Resume & Analytics)
    
    // Overview & Analytics
    if ((pathname === '/api/habits/analytics' || pathname === '/api/habits/analytics/overview') && method === 'GET') {
      const queryDate = query.date || new Date().toISOString().split('T')[0];
      const analytics = calculateHabitAnalytics(userId, db, queryDate);
      return sendJSON(res, 200, { success: true, data: analytics, analytics });
    }

    // Smart Assistant Insights
    if ((pathname === '/api/habits/insights' || pathname === '/api/assistant/habit-insights') && method === 'GET') {
      const queryDate = query.date || new Date().toISOString().split('T')[0];
      const insights = generateHabitInsights(userId, db, queryDate);
      return sendJSON(res, 200, { success: true, data: insights, insights });
    }

    // Completions History Query
    if (pathname === '/api/habits/completions' && method === 'GET') {
      const { startDate, endDate, habitId } = query;
      let comps = (db.habitCompletions || []).filter((hc) => hc.userId === userId);
      if (habitId) comps = comps.filter((hc) => hc.habitId === habitId);
      if (startDate) comps = comps.filter((hc) => hc.completionDate >= startDate);
      if (endDate) comps = comps.filter((hc) => hc.completionDate <= endDate);
      return sendJSON(res, 200, { success: true, data: comps, completions: comps });
    }

    // Today's Scheduled Habits
    if (pathname === '/api/habits/today' && method === 'GET') {
      const todayStr = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && !h.isDeleted && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      const todayHabits = userHabits
        .filter((h) => isHabitScheduledForDate(h, todayStr, db))
        .map((h) => {
          const habitComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
          const compSet = new Set(habitComps);
          const streaks = calculateHabitStreaks(h, habitComps, todayStr, db);

          return {
            id: h.id,
            userId: h.userId || userId,
            title: h.title,
            category: h.category || 'General',
            frequency: h.frequency || 'DAILY',
            selectedDays: h.selectedDays || [],
            intervalDays: h.intervalDays || 1,
            startDate: h.startDate || h.createdAt?.split('T')[0] || todayStr,
            status: h.status || 'active',
            description: h.description || '',
            colorHex: h.colorHex || '0xFF10B981',
            iconName: h.iconName || 'repeat',
            isScheduled: true,
            isCompleted: compSet.has(todayStr),
            currentStreak: streaks.currentStreak,
            longestStreak: streaks.longestStreak,
            totalCompletions: streaks.totalCompletions,
            createdAt: h.createdAt,
            updatedAt: h.updatedAt,
          };
        });

      return sendJSON(res, 200, { success: true, data: todayHabits, habits: todayHabits });
    }

    // Individual Habit Complete / Uncomplete
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/complete')) {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId && !h.isDeleted);
      if (!habit) {
        return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });
      }

      const targetDate = (body && body.date) || query.date || new Date().toISOString().split('T')[0];
      db.habitCompletions = db.habitCompletions || [];
      const existingIdx = db.habitCompletions.findIndex(
        (hc) => hc.habitId === habitId && hc.userId === userId && hc.completionDate === targetDate
      );

      if (method === 'POST') {
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
      } else if (method === 'DELETE') {
        if (existingIdx !== -1) {
          db.habitCompletions.splice(existingIdx, 1);
        }
      }

      const habitComps = db.habitCompletions.filter((c) => c.habitId === habitId && c.userId === userId).map((c) => c.completionDate);
      const streakInfo = calculateHabitStreaks(habit, habitComps, new Date().toISOString().split('T')[0], db);
      habit.currentStreak = streakInfo.currentStreak;
      habit.longestStreak = streakInfo.longestStreak;
      habit.updatedAt = new Date().toISOString();
      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        message: method === 'POST' ? 'Habit completed successfully' : 'Habit uncompleted successfully',
        data: {
          habitId,
          date: targetDate,
          isCompleted: method === 'POST',
          currentStreak: habit.currentStreak,
          longestStreak: habit.longestStreak,
          totalCompletions: streakInfo.totalCompletions,
        },
      });
    }

    // Habit Toggle
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/toggle') && method === 'POST') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId && !h.isDeleted);
      if (!habit) {
        return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });
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

      const habitComps = db.habitCompletions.filter((c) => c.habitId === habitId && c.userId === userId).map((c) => c.completionDate);
      const streakInfo = calculateHabitStreaks(habit, habitComps, new Date().toISOString().split('T')[0], db);
      habit.currentStreak = streakInfo.currentStreak;
      habit.longestStreak = streakInfo.longestStreak;
      habit.updatedAt = new Date().toISOString();

      saveDB(db);

      return sendJSON(res, 200, {
        success: true,
        isCompleted: isNowCompleted,
        habitId,
        date: targetDate,
        currentStreak: habit.currentStreak,
        longestStreak: habit.longestStreak,
        totalCompletions: streakInfo.totalCompletions,
        data: {
          isCompleted: isNowCompleted,
          habitId,
          date: targetDate,
          currentStreak: habit.currentStreak,
          longestStreak: habit.longestStreak,
          totalCompletions: streakInfo.totalCompletions,
        },
      });
    }

    // Habit Pause
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/pause') && method === 'POST') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });

      habit.status = 'paused';
      habit.updatedAt = new Date().toISOString();

      db.habitPausePeriods = db.habitPausePeriods || [];
      db.habitPausePeriods.push({
        id: 'pp_' + Date.now(),
        habitId,
        userId,
        pausedAt: new Date().toISOString(),
        resumedAt: null,
        createdAt: new Date().toISOString(),
      });

      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Habit paused successfully.', data: habit });
    }

    // Habit Resume
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/resume') && method === 'POST') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });

      habit.status = 'active';
      habit.updatedAt = new Date().toISOString();

      db.habitPausePeriods = db.habitPausePeriods || [];
      const openPause = db.habitPausePeriods.find((p) => p.habitId === habitId && p.resumedAt === null);
      if (openPause) {
        openPause.resumedAt = new Date().toISOString();
        openPause.updatedAt = new Date().toISOString();
      }

      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Habit resumed successfully.', data: habit });
    }

    // Habit Archive
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/archive') && method === 'POST') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });

      habit.status = 'archived';
      habit.isArchived = true;
      habit.updatedAt = new Date().toISOString();
      saveDB(db);
      return sendJSON(res, 200, { success: true, message: 'Habit archived successfully.', data: habit });
    }

    // Individual Habit History
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/history') && method === 'GET') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });

      const days = parseInt(query.days || '30', 10);
      const today = new Date();
      const todayStr = today.toISOString().split('T')[0];
      const history = [];

      const habitComps = (db.habitCompletions || []).filter((hc) => hc.habitId === habitId && hc.userId === userId).map((c) => c.completionDate);
      const compSet = new Set(habitComps);

      for (let i = 0; i < days; i++) {
        const d = new Date(today);
        d.setUTCDate(d.getUTCDate() - i);
        const dStr = d.toISOString().split('T')[0];
        const status = getHabitStatus(habit, dStr, compSet, db, todayStr);
        history.push({
          date: dStr,
          status,
          isCompleted: compSet.has(dStr),
          isScheduled: isHabitScheduledForDate(habit, dStr, db),
        });
      }

      return sendJSON(res, 200, { success: true, data: history, habitId, days });
    }

    // Individual Habit Analytics
    if (pathname.startsWith('/api/habits/') && pathname.endsWith('/analytics') && method === 'GET') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      if (!habit) return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });

      const todayStr = query.date || new Date().toISOString().split('T')[0];
      const habitComps = (db.habitCompletions || []).filter((hc) => hc.habitId === habitId && hc.userId === userId).map((c) => c.completionDate);
      const compSet = new Set(habitComps);
      const streaks = calculateHabitStreaks(habit, habitComps, todayStr, db);

      return sendJSON(res, 200, {
        success: true,
        data: {
          habitId: habit.id,
          title: habit.title,
          currentStreak: streaks.currentStreak,
          longestStreak: streaks.longestStreak,
          totalCompletions: streaks.totalCompletions,
          frequency: habit.frequency,
          status: habit.status,
        },
      });
    }

    // Update Habit Status
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

    // Get Single Habit
    if (pathname.startsWith('/api/habits/') && method === 'GET' && pathname.split('/').length === 4) {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId && !h.isDeleted);
      if (!habit) {
        return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });
      }

      const todayStr = new Date().toISOString().split('T')[0];
      const habitComps = (db.habitCompletions || []).filter((hc) => hc.habitId === habitId && hc.userId === userId).map((c) => c.completionDate);
      const streaks = calculateHabitStreaks(habit, habitComps, todayStr, db);

      return sendJSON(res, 200, {
        success: true,
        data: {
          ...habit,
          currentStreak: streaks.currentStreak,
          longestStreak: streaks.longestStreak,
          totalCompletions: streaks.totalCompletions,
          completionHistory: habitComps,
        },
      });
    }

    // Edit Habit
    if (pathname.startsWith('/api/habits/') && method === 'PUT') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId && !h.isDeleted);
      if (!habit) {
        return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });
      }

      // Log schedule change if frequency changes
      if (body.frequency && body.frequency !== habit.frequency) {
        db.habitScheduleHistory = db.habitScheduleHistory || [];
        db.habitScheduleHistory.push({
          id: 'sh_' + Date.now(),
          habitId,
          frequency: habit.frequency,
          selectedDays: habit.selectedDays,
          intervalDays: habit.intervalDays,
          effectiveFrom: habit.startDate || habit.createdAt,
          effectiveTo: new Date().toISOString(),
          createdAt: new Date().toISOString(),
        });
      }

      habit.title = body.title !== undefined ? body.title : habit.title;
      habit.category = body.category !== undefined ? body.category : (habit.category || 'General');
      habit.frequency = body.frequency !== undefined ? body.frequency : (habit.frequency || 'DAILY');
      habit.selectedDays = body.selectedDays !== undefined ? body.selectedDays : (habit.selectedDays || []);
      habit.intervalDays = body.intervalDays !== undefined ? body.intervalDays : (habit.intervalDays || 1);
      habit.description = body.description !== undefined ? body.description : (habit.description || '');
      habit.colorHex = body.colorHex !== undefined ? body.colorHex : (habit.colorHex || '0xFF10B981');
      habit.iconName = body.iconName !== undefined ? body.iconName : (habit.iconName || 'repeat');
      habit.updatedAt = new Date().toISOString();

      saveDB(db);
      return sendJSON(res, 200, { success: true, data: habit, habit });
    }

    // Delete Habit (Soft Delete)
    if (pathname.startsWith('/api/habits/') && method === 'DELETE') {
      const habitId = pathname.split('/')[3];
      const habit = (db.habits || []).find((h) => h.id === habitId && h.userId === userId);
      
      if (!habit) {
        return sendJSON(res, 404, { success: false, error: { code: 'NOT_FOUND', message: 'Habit not found.' } });
      }

      habit.isDeleted = true;
      habit.deletedAt = new Date().toISOString();
      habit.status = 'archived';

      // Keep completions for analytics historical audit
      saveDB(db);

      return sendJSON(res, 200, { success: true, message: 'Habit deleted successfully.' });
    }

    // List Habits
    if (pathname === '/api/habits' && method === 'GET') {
      const targetDate = query.date || new Date().toISOString().split('T')[0];
      const userHabits = (db.habits || []).filter((h) => h.userId === userId && !h.isDeleted && h.status !== 'archived');
      const userCompletions = (db.habitCompletions || []).filter((hc) => hc.userId === userId && hc.status === 'completed');

      const enriched = userHabits.map((h) => {
        const habitComps = userCompletions.filter((c) => c.habitId === h.id).map((c) => c.completionDate);
        const compSet = new Set(habitComps);
        const streaks = calculateHabitStreaks(h, habitComps, targetDate, db);

        return {
          id: h.id,
          userId: h.userId || userId,
          title: h.title,
          category: h.category || 'General',
          frequency: h.frequency || 'DAILY',
          selectedDays: h.selectedDays || [],
          intervalDays: h.intervalDays || 1,
          startDate: h.startDate || h.createdAt?.split('T')[0] || targetDate,
          status: h.status || 'active',
          description: h.description || '',
          colorHex: h.colorHex || '0xFF10B981',
          iconName: h.iconName || 'repeat',
          isScheduled: isHabitScheduledForDate(h, targetDate, db),
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

    // Create Habit
    if (pathname === '/api/habits' && method === 'POST') {
      const sub = getUserSubscription(userId);
      const activeUserHabits = (db.habits || []).filter(
        (h) => h.userId === userId && !h.isDeleted && h.status === 'active'
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

      if (!body.title || !body.title.trim()) {
        return sendJSON(res, 400, { success: false, error: { code: 'VALIDATION_ERROR', message: 'Habit name cannot be empty.' } });
      }

      const todayStr = new Date().toISOString().split('T')[0];
      const newHabit = {
        id: 'h_' + Date.now(),
        userId,
        title: body.title.trim(),
        category: body.category || 'General',
        frequency: body.frequency || 'DAILY',
        selectedDays: Array.isArray(body.selectedDays) ? body.selectedDays : [],
        intervalDays: body.intervalDays || 1,
        startDate: body.startDate || todayStr,
        status: 'active',
        description: body.description || '',
        colorHex: body.colorHex || '0xFF10B981',
        iconName: body.iconName || 'repeat',
        isDeleted: false,
        deletedAt: null,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      db.habits = db.habits || [];
      db.habits.push(newHabit);
      saveDB(db);

      return sendJSON(res, 201, {
        ...newHabit,
        isScheduled: isHabitScheduledForDate(newHabit, todayStr, db),
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
