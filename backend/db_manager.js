const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { supabase, isConfigured: isSupabaseConfigured } = require('./supabase_client');

const DB_FILE = path.join(__dirname, 'data', 'db.json');
const DB_TMP_FILE = path.join(__dirname, 'data', '.db.json.tmp');

// Ensure DB directory exists
if (!fs.existsSync(path.join(__dirname, 'data'))) {
  fs.mkdirSync(path.join(__dirname, 'data'), { recursive: true });
}

// -----------------------------------------------------------------------------
// 1. CRYPTOGRAPHIC SECURITY HELPERS (Salted PBKDF2 Hashing & Verification)
// -----------------------------------------------------------------------------
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  if (!stored) return false;
  if (!stored.includes(':')) return password === stored;
  try {
    const [salt, storedHash] = stored.split(':');
    const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
    return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
  } catch (_) {
    return false;
  }
}

// -----------------------------------------------------------------------------
// 2. CANONICAL DATABASE SCHEMA TEMPLATE
// -----------------------------------------------------------------------------
function getEmptyDatabaseSchema() {
  return {
    user_profiles: [],
    user_subscriptions: [],
    tasks: [],
    habits: [],
    habit_logs: [],
    expenses: [],
    monthly_budgets: [],
    goals: [],
    career_milestones: [],
    study_subjects: [],
    study_units: [],
    calendar_events: [],
    user_referrals: [],
    payment_history: [],
    coupons: [
      { code: 'STUDENT100', discountPercent: 100, maxUses: 1000, plan: 'pro', active: true },
      { code: 'PROVIP', discountPercent: 100, maxUses: 1000, plan: 'pro', active: true }
    ],
    coupon_usages: [],
    auth_otps: {}
  };
}

// -----------------------------------------------------------------------------
// 3. ATOMIC DISK PERSISTENCE & LEGACY DATA MIGRATOR
// -----------------------------------------------------------------------------
let memoryDb = null;

function loadDatabase() {
  if (memoryDb) return memoryDb;
  const initial = getEmptyDatabaseSchema();

  if (!fs.existsSync(DB_FILE)) {
    saveDatabase(initial);
    memoryDb = initial;
    return memoryDb;
  }

  try {
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    const loaded = JSON.parse(raw);

    // Merge loaded data with canonical schema and migrate legacy key names
    const db = getEmptyDatabaseSchema();

    // Migrate Users -> user_profiles
    const rawUsers = loaded.user_profiles || loaded.users || [];
    db.user_profiles = rawUsers.map(u => ({
      id: u.id || u.user_id,
      user_id: u.user_id || u.id,
      username: u.username || u.email?.split('@')[0] || 'user',
      name: u.name || u.display_name || u.username || 'Student User',
      display_name: u.display_name || u.name || u.username || 'Student User',
      email: (u.email || '').toLowerCase().trim(),
      password: u.password || u.password_hash || u.passwordHash,
      password_hash: u.password_hash || u.password || u.passwordHash,
      is_premium: !!(u.is_premium || u.isPremium || u.subscription_plan === 'PRO' || u.subscriptionPlan === 'PRO'),
      isPremium: !!(u.is_premium || u.isPremium || u.subscription_plan === 'PRO' || u.subscriptionPlan === 'PRO'),
      subscription_plan: (u.subscription_plan || u.subscriptionPlan || (u.isPremium ? 'PRO' : 'FREE')).toUpperCase(),
      subscriptionPlan: (u.subscription_plan || u.subscriptionPlan || (u.isPremium ? 'PRO' : 'FREE')).toUpperCase(),
      focus_score: u.focus_score ?? u.focusScore ?? 80,
      focusScore: u.focus_score ?? u.focusScore ?? 80,
      active_streak: u.active_streak ?? u.activeStreak ?? 0,
      activeStreak: u.active_streak ?? u.activeStreak ?? 0,
      referral_code: u.referral_code || u.referralCode || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
      referralCode: u.referral_code || u.referralCode || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
      is_email_verified: !!(u.is_email_verified || u.isEmailVerified),
      created_at: u.created_at || u.createdAt || new Date().toISOString(),
      updated_at: u.updated_at || u.updatedAt || new Date().toISOString(),
    }));

    // Migrate Subscriptions -> user_subscriptions
    const rawSubs = loaded.user_subscriptions || loaded.subscriptions || [];
    db.user_subscriptions = rawSubs.map(s => {
      const uid = s.user_id || s.userId;
      const isPro = (s.plan || '').toLowerCase() === 'pro' || (s.plan || '').toLowerCase() === 'premium';
      return {
        id: s.id || `sub_${uid}`,
        user_id: uid,
        userId: uid,
        plan: isPro ? 'pro' : 'free',
        status: s.status || 'active',
        started_at: s.started_at || s.startedAt || new Date().toISOString(),
        expires_at: s.expires_at || s.expiresAt || null,
        payment_provider: s.payment_provider || s.paymentProvider || 'NONE',
        transaction_id: s.transaction_id || s.transactionId || null,
        created_at: s.created_at || s.createdAt || new Date().toISOString(),
        updated_at: s.updated_at || s.updatedAt || new Date().toISOString(),
      };
    });

    // Migrate Tasks -> tasks
    const rawTasks = loaded.tasks || [];
    db.tasks = rawTasks.map(t => {
      const uid = t.user_id || t.userId;
      const isDone = !!(t.is_completed ?? t.isCompleted);
      return {
        id: t.id || `t_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        user_id: uid,
        userId: uid,
        title: t.title || 'Untitled Task',
        description: t.description || '',
        category: t.category || 'Studies',
        tag: t.tag || 'STUDY',
        priority: t.priority ?? 1,
        quadrant: t.quadrant || 'Q1_DO_FIRST',
        due_date: t.due_date || t.dueDate || new Date().toISOString().split('T')[0],
        dueDate: t.due_date || t.dueDate || new Date().toISOString().split('T')[0],
        due_time: t.due_time || t.dueTime || '18:00',
        dueTime: t.due_time || t.dueTime || '18:00',
        is_completed: isDone,
        isCompleted: isDone,
        completed_at: t.completed_at || t.completedAt || (isDone ? new Date().toISOString() : null),
        created_at: t.created_at || t.createdAt || new Date().toISOString(),
        updated_at: t.updated_at || t.updatedAt || new Date().toISOString(),
      };
    });

    // Migrate Habits -> habits
    const rawHabits = loaded.habits || [];
    db.habits = rawHabits.map(h => {
      const uid = h.user_id || h.userId;
      return {
        id: h.id || `h_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        user_id: uid,
        userId: uid,
        title: h.title || 'Habit',
        description: h.description || '',
        category: h.category || 'General',
        frequency: h.frequency || 'DAILY',
        selected_days: h.selected_days || h.selectedDays || [1, 2, 3, 4, 5, 6, 7],
        selectedDays: h.selected_days || h.selectedDays || [1, 2, 3, 4, 5, 6, 7],
        preferred_time: h.preferred_time || h.preferredTime || '08:00:00',
        icon_name: h.icon_name || h.iconName || 'repeat',
        iconName: h.icon_name || h.iconName || 'repeat',
        color_hex: h.color_hex || h.colorHex || '#10B981',
        colorHex: h.color_hex || h.colorHex || '#10B981',
        status: h.status || 'active',
        streak_day: h.streak_day || h.streakDay || 0,
        streakDay: h.streak_day || h.streakDay || 0,
        created_at: h.created_at || h.createdAt || new Date().toISOString(),
        updated_at: h.updated_at || h.updatedAt || new Date().toISOString(),
      };
    });

    // Migrate Habit Logs -> habit_logs
    db.habit_logs = (loaded.habit_logs || loaded.habitCompletions || []).map(hl => ({
      id: hl.id || `hl_${Date.now()}`,
      habit_id: hl.habit_id || hl.habitId,
      habitId: hl.habit_id || hl.habitId,
      user_id: hl.user_id || hl.userId,
      userId: hl.user_id || hl.userId,
      completed_date: hl.completed_date || hl.date || hl.completedDate,
      date: hl.completed_date || hl.date || hl.completedDate,
      completed_at: hl.completed_at || hl.completedAt || new Date().toISOString(),
    }));

    // Migrate Expenses -> expenses
    db.expenses = (loaded.expenses || []).map(e => ({
      id: e.id || `e_${Date.now()}`,
      user_id: e.user_id || e.userId,
      userId: e.user_id || e.userId,
      title: e.title || 'Expense',
      amount: Number(e.amount) || 0,
      category: e.category || 'General',
      is_income: !!(e.is_income || e.isIncome),
      isIncome: !!(e.is_income || e.isIncome),
      payment_method: e.payment_method || e.paymentMethod || 'UPI',
      expense_date: e.expense_date || e.date || new Date().toISOString(),
      date: e.expense_date || e.date || new Date().toISOString(),
      created_at: e.created_at || e.createdAt || new Date().toISOString(),
    }));

    // Migrate Monthly Budgets -> monthly_budgets
    db.monthly_budgets = (loaded.monthly_budgets || loaded.monthlyBudgets || []).map(b => ({
      id: b.id || `mb_${Date.now()}`,
      user_id: b.user_id || b.userId,
      userId: b.user_id || b.userId,
      budget_month: b.budget_month || b.budgetMonth || new Date().toISOString().substring(0, 7),
      total_budget_limit: Number(b.total_budget_limit || b.totalBudgetLimit || b.limit || 10000),
      created_at: b.created_at || new Date().toISOString(),
    }));

    // Migrate Goals -> goals
    db.goals = (loaded.goals || loaded.careerNodes || []).map(g => ({
      id: g.id || `g_${Date.now()}`,
      user_id: g.user_id || g.userId,
      userId: g.user_id || g.userId,
      title: g.title || 'Goal',
      timeframe: g.timeframe || g.tier || 'SHORT',
      target_date: g.target_date || g.targetDate || null,
      aligned_purpose: g.aligned_purpose || g.alignedPurpose || '',
      progress_percentage: g.progress_percentage || g.progress || 0,
      is_achieved: !!(g.is_achieved || g.isCompleted || g.isAchieved),
      isCompleted: !!(g.is_achieved || g.isCompleted || g.isAchieved),
      created_at: g.created_at || new Date().toISOString(),
    }));

    // Migrate Career Milestones -> career_milestones
    db.career_milestones = (loaded.career_milestones || loaded.milestones || []).map(m => ({
      id: m.id || `cm_${Date.now()}`,
      user_id: m.user_id || m.userId,
      userId: m.user_id || m.userId,
      milestone_title: m.milestone_title || m.title,
      title: m.milestone_title || m.title,
      category: m.category || 'Career',
      target_date: m.target_date || m.targetDate || new Date().toISOString(),
      is_completed: !!(m.is_completed || m.isCompleted),
      impact_badge: m.impact_badge || m.impactBadge || 'High Impact',
      created_at: m.created_at || new Date().toISOString(),
    }));

    // Migrate Study Subjects -> study_subjects
    db.study_subjects = (loaded.study_subjects || loaded.subjects || []).map(s => ({
      id: s.id || `s_${Date.now()}`,
      user_id: s.user_id || s.userId,
      userId: s.user_id || s.userId,
      subject_name: s.subject_name || s.name || 'Subject',
      name: s.subject_name || s.name || 'Subject',
      color_hex: s.color_hex || s.colorHex || '#0D5CE5',
      colorHex: s.color_hex || s.colorHex || '#0D5CE5',
      total_hours_logged: Number(s.total_hours_logged || s.hoursLogged || 0),
      created_at: s.created_at || new Date().toISOString(),
    }));

    // Migrate Study Units -> study_units
    db.study_units = (loaded.study_units || loaded.studyItems || []).map(u => ({
      id: u.id || `su_${Date.now()}`,
      user_id: u.user_id || u.userId,
      userId: u.user_id || u.userId,
      subject_id: u.subject_id || u.subjectId,
      subjectId: u.subject_id || u.subjectId,
      unit_title: u.unit_title || u.title || 'Unit',
      title: u.unit_title || u.title || 'Unit',
      target_hours: Number(u.target_hours || u.targetHours || 10),
      completed_hours: Number(u.completed_hours || u.completedHours || 0),
      is_completed: !!(u.is_completed || u.isCompleted),
      created_at: u.created_at || new Date().toISOString(),
    }));

    // Migrate Calendar Events -> calendar_events
    db.calendar_events = (loaded.calendar_events || loaded.calendarEvents || []).map(ce => ({
      id: ce.id || `ce_${Date.now()}`,
      user_id: ce.user_id || ce.userId,
      userId: ce.user_id || ce.userId,
      title: ce.title || 'Event',
      description: ce.description || '',
      start_time: ce.start_time || ce.startTime || new Date().toISOString(),
      end_time: ce.end_time || ce.endTime || new Date().toISOString(),
      location: ce.location || '',
      event_type: ce.event_type || ce.eventType || 'Focus Session',
      is_completed: !!(ce.is_completed || ce.isCompleted),
      created_at: ce.created_at || new Date().toISOString(),
    }));

    // Migrate Referrals -> user_referrals
    db.user_referrals = (loaded.user_referrals || loaded.referralTrackings || []).map(r => ({
      id: r.id || `ref_${Date.now()}`,
      referrer_id: r.referrer_id || r.referrerUserId,
      referee_id: r.referee_id || r.refereeUserId,
      referral_code: r.referral_code || r.referralCode,
      discount_percentage: r.discount_percentage || 10,
      status: r.status || 'SUCCESSFUL',
      created_at: r.created_at || new Date().toISOString(),
    }));

    // Other tables
    db.payment_history = loaded.payment_history || loaded.paymentHistory || [];
    db.coupons = loaded.coupons || db.coupons;
    db.coupon_usages = loaded.coupon_usages || loaded.couponUsages || [];
    db.auth_otps = loaded.auth_otps || loaded.otpStore || {};

    memoryDb = db;
    saveDatabase(db);
    return memoryDb;
  } catch (err) {
    console.error('Error loading database file, initializing clean schema:', err);
    memoryDb = initial;
    saveDatabase(initial);
    return memoryDb;
  }
}

function saveDatabase(data) {
  try {
    memoryDb = data;
    const jsonStr = JSON.stringify(data, null, 2);
    fs.writeFileSync(DB_TMP_FILE, jsonStr, 'utf8');
    fs.renameSync(DB_TMP_FILE, DB_FILE);
  } catch (err) {
    console.error('Error persisting database to disk:', err);
  }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// 4. SUPABASE SYNCHRONIZATION BRIDGE (LIVE CLOUD POSTGRESQL SYNC)
// -----------------------------------------------------------------------------
async function syncToSupabase(entityType, record) {
  if (!isSupabaseConfigured() || !supabase || !record) return;
  try {
    const uid = record.user_id || record.userId;
    if (!uid) return;

    if (entityType === 'profiles' || entityType === 'user_profiles') {
      await supabase.from('profiles').upsert({
        id: uid,
        username: record.username || record.email?.split('@')[0],
        name: record.name || record.display_name || 'Student User',
        email: record.email,
        referral_code: record.referral_code || record.referralCode || 'WRINDHA',
      }, { onConflict: 'id' });
    } else if (entityType === 'subscriptions' || entityType === 'user_subscriptions') {
      await supabase.from('subscriptions').upsert({
        user_id: uid,
        plan: (record.plan || '').toLowerCase() === 'pro' ? 'premium' : 'free',
        status: record.status || 'active',
        started_at: record.started_at || record.startedAt || new Date().toISOString(),
      }, { onConflict: 'user_id' });
    } else if (entityType === 'tasks') {
      await supabase.from('tasks').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        title: record.title || 'Task',
        category: record.category || 'Studies',
        priority: Number(record.priority) || 1,
        is_completed: !!(record.is_completed ?? record.isCompleted),
      });
    } else if (entityType === 'habits') {
      const freq = (record.frequency || 'daily').toLowerCase();
      const validFreq = ['daily', 'weekdays', 'weekends', 'custom'].includes(freq) ? freq : 'daily';
      await supabase.from('habits').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        title: record.title || 'Habit',
        category: record.category || 'General',
        frequency: validFreq,
        status: record.status || 'active',
      });
    } else if (entityType === 'expenses') {
      await supabase.from('expenses').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        title: record.title || 'Expense',
        amount: Number(record.amount) || 0,
        category: record.category || 'General',
        transaction_type: (record.is_income || record.isIncome) ? 'income' : 'expense',
      });
    } else if (entityType === 'subjects' || entityType === 'study_subjects') {
      await supabase.from('subjects').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        name: record.name || record.subject_name || 'Subject',
        color: record.color_hex || record.colorHex || '#0D5CE5',
      });
    } else if (entityType === 'goals') {
      await supabase.from('goals').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        title: record.title || 'Goal',
        timeframe: (record.timeframe || 'SHORT').toUpperCase(),
        is_achieved: !!(record.is_achieved || record.isCompleted || record.isAchieved),
      });
    } else if (entityType === 'calendar_events') {
      await supabase.from('calendar_events').upsert({
        id: record.id?.includes('-') ? record.id : undefined,
        user_id: uid,
        title: record.title || 'Event',
        start_time: record.start_time || record.startTime || new Date().toISOString(),
        end_time: record.end_time || record.endTime || new Date().toISOString(),
      });
    }
  } catch (err) {
    // Non-blocking resilient logging
    console.warn(`[Supabase Sync Warning] (${entityType}):`, err.message);
  }
}

async function deleteFromSupabase(table, matchObj) {
  if (!isSupabaseConfigured() || !supabase) return;
  try {
    const tableName = table === 'user_profiles' ? 'profiles' : (table === 'user_subscriptions' ? 'subscriptions' : table);
    await supabase.from(tableName).delete().match(matchObj);
  } catch (_) {}
}

// -----------------------------------------------------------------------------
// 5. UNIFIED DATABASE ACCESS LAYER (DATA ISOLATION & CRUD ENGINE)
// -----------------------------------------------------------------------------
class DatabaseManager {
  // ---------------------------------------------------------------------------
  // AUTHENTICATION & USER PROFILES
  // ---------------------------------------------------------------------------
  static getUserById(userId) {
    if (!userId) return null;
    const db = loadDatabase();
    return db.user_profiles.find(u => u.id === userId || u.user_id === userId) || null;
  }

  static getUserByEmailOrUsername(identifier) {
    if (!identifier) return null;
    const clean = identifier.trim().toLowerCase();
    const db = loadDatabase();
    return db.user_profiles.find(
      u => (u.username || '').toLowerCase() === clean || (u.email || '').toLowerCase() === clean
    ) || null;
  }

  static createUser(userData) {
    const db = loadDatabase();
    const userId = userData.id || `u_${Date.now()}`;
    const cleanUsername = (userData.username || '').trim().toLowerCase();
    const cleanEmail = (userData.email || '').trim().toLowerCase();

    const newUser = {
      id: userId,
      user_id: userId,
      username: cleanUsername,
      name: userData.name || userData.display_name || (cleanUsername ? cleanUsername[0].toUpperCase() + cleanUsername.slice(1) : 'Student User'),
      display_name: userData.display_name || userData.name || (cleanUsername ? cleanUsername[0].toUpperCase() + cleanUsername.slice(1) : 'Student User'),
      email: cleanEmail,
      password: userData.password_hash || userData.password,
      password_hash: userData.password_hash || userData.password,
      is_premium: !!userData.is_premium,
      isPremium: !!userData.is_premium,
      subscription_plan: (userData.subscription_plan || 'FREE').toUpperCase(),
      subscriptionPlan: (userData.subscription_plan || 'FREE').toUpperCase(),
      focus_score: userData.focus_score ?? 85,
      focusScore: userData.focus_score ?? 85,
      active_streak: userData.active_streak ?? 1,
      activeStreak: userData.active_streak ?? 1,
      referral_code: userData.referral_code || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
      referralCode: userData.referral_code || ('WOS' + Math.floor(1000 + Math.random() * 9000)),
      is_email_verified: !!userData.is_email_verified,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.user_profiles.push(newUser);

    // Create default subscription for the user
    const newSub = {
      id: `sub_${userId}`,
      user_id: userId,
      userId: userId,
      plan: newUser.is_premium ? 'pro' : 'free',
      status: 'active',
      started_at: new Date().toISOString(),
      expires_at: newUser.is_premium ? '2030-12-31T23:59:59.000Z' : null,
      payment_provider: newUser.is_premium ? 'SEED_VIP' : 'NONE',
      transaction_id: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    db.user_subscriptions.push(newSub);

    saveDatabase(db);

    // Sync to Supabase
    syncToSupabase('user_profiles', {
      user_id: newUser.user_id,
      username: newUser.username,
      email: newUser.email,
      display_name: newUser.display_name,
      subscription_plan: newUser.subscription_plan,
      is_premium: newUser.is_premium,
      focus_score: newUser.focus_score,
      active_streak: newUser.active_streak,
      referral_code: newUser.referral_code,
    });
    syncToSupabase('user_subscriptions', {
      user_id: newSub.user_id,
      plan: newSub.plan,
      status: newSub.status,
      started_at: newSub.started_at,
      expires_at: newSub.expires_at,
    });

    return newUser;
  }

  static updateUser(userId, updates) {
    const db = loadDatabase();
    const idx = db.user_profiles.findIndex(u => u.id === userId || u.user_id === userId);
    if (idx === -1) return null;

    const user = db.user_profiles[idx];
    if (updates.name) {
      user.name = updates.name;
      user.display_name = updates.name;
    }
    if (updates.display_name) {
      user.name = updates.display_name;
      user.display_name = updates.display_name;
    }
    if (updates.focus_score !== undefined) {
      user.focus_score = updates.focus_score;
      user.focusScore = updates.focus_score;
    }
    if (updates.active_streak !== undefined) {
      user.active_streak = updates.active_streak;
      user.activeStreak = updates.active_streak;
    }
    if (updates.is_premium !== undefined) {
      user.is_premium = !!updates.is_premium;
      user.isPremium = !!updates.is_premium;
    }
    if (updates.subscription_plan) {
      user.subscription_plan = updates.subscription_plan.toUpperCase();
      user.subscriptionPlan = updates.subscription_plan.toUpperCase();
    }
    user.updated_at = new Date().toISOString();

    saveDatabase(db);

    syncToSupabase('user_profiles', {
      user_id: user.user_id,
      display_name: user.display_name,
      focus_score: user.focus_score,
      active_streak: user.active_streak,
      is_premium: user.is_premium,
      subscription_plan: user.subscription_plan,
    });

    return user;
  }

  static deleteUser(userId) {
    const db = loadDatabase();
    db.user_profiles = db.user_profiles.filter(u => u.id !== userId && u.user_id !== userId);
    db.user_subscriptions = db.user_subscriptions.filter(s => s.user_id !== userId && s.userId !== userId);
    db.tasks = db.tasks.filter(t => t.user_id !== userId && t.userId !== userId);
    db.habits = db.habits.filter(h => h.user_id !== userId && h.userId !== userId);
    db.habit_logs = db.habit_logs.filter(hl => hl.user_id !== userId && hl.userId !== userId);
    db.expenses = db.expenses.filter(e => e.user_id !== userId && e.userId !== userId);
    db.monthly_budgets = db.monthly_budgets.filter(b => b.user_id !== userId && b.userId !== userId);
    db.goals = db.goals.filter(g => g.user_id !== userId && g.userId !== userId);
    db.study_subjects = db.study_subjects.filter(s => s.user_id !== userId && s.userId !== userId);
    db.study_units = db.study_units.filter(u => u.user_id !== userId && u.userId !== userId);
    db.calendar_events = db.calendar_events.filter(ce => ce.user_id !== userId && ce.userId !== userId);

    saveDatabase(db);

    deleteFromSupabase('user_profiles', { user_id: userId });
    deleteFromSupabase('user_subscriptions', { user_id: userId });
    return true;
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS
  // ---------------------------------------------------------------------------
  static getUserSubscription(userId) {
    if (!userId) return { plan: 'free', status: 'active', is_pro: false, isPro: false };
    const db = loadDatabase();
    let sub = db.user_subscriptions.find(s => s.user_id === userId || s.userId === userId);
    const user = this.getUserById(userId);

    const isPro = (sub && sub.plan === 'pro') || (user && (user.is_premium || user.subscription_plan === 'PRO'));

    if (!sub) {
      sub = {
        id: `sub_${userId}`,
        user_id: userId,
        userId: userId,
        plan: isPro ? 'pro' : 'free',
        status: 'active',
        started_at: new Date().toISOString(),
        expires_at: isPro ? '2030-12-31T23:59:59.000Z' : null,
        payment_provider: isPro ? 'VIP' : 'NONE',
        transaction_id: null,
      };
      db.user_subscriptions.push(sub);
      saveDatabase(db);
    } else if (isPro && sub.plan !== 'pro') {
      sub.plan = 'pro';
      sub.status = 'active';
      saveDatabase(db);
    }

    return {
      ...sub,
      is_pro: sub.plan === 'pro',
      isPro: sub.plan === 'pro',
    };
  }

  static upgradeSubscription(userId, plan = 'pro', provider = 'MANUAL', txnId = null) {
    const db = loadDatabase();
    let sub = db.user_subscriptions.find(s => s.user_id === userId || s.userId === userId);
    if (!sub) {
      sub = {
        id: `sub_${userId}`,
        user_id: userId,
        userId: userId,
        plan: plan.toLowerCase(),
        status: 'active',
        started_at: new Date().toISOString(),
        expires_at: '2030-12-31T23:59:59.000Z',
        payment_provider: provider,
        transaction_id: txnId || `txn_${Date.now()}`,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      db.user_subscriptions.push(sub);
    } else {
      sub.plan = plan.toLowerCase();
      sub.status = 'active';
      sub.expires_at = '2030-12-31T23:59:59.000Z';
      sub.payment_provider = provider;
      sub.transaction_id = txnId || sub.transaction_id;
      sub.updated_at = new Date().toISOString();
    }

    // Sync user profile
    const user = db.user_profiles.find(u => u.id === userId || u.user_id === userId);
    if (user) {
      user.is_premium = sub.plan === 'pro';
      user.isPremium = sub.plan === 'pro';
      user.subscription_plan = sub.plan.toUpperCase();
      user.subscriptionPlan = sub.plan.toUpperCase();
      user.updated_at = new Date().toISOString();
    }

    saveDatabase(db);

    syncToSupabase('user_subscriptions', {
      user_id: sub.user_id,
      plan: sub.plan,
      status: sub.status,
      started_at: sub.started_at,
      expires_at: sub.expires_at,
      payment_provider: sub.payment_provider,
    });

    return sub;
  }

  // ---------------------------------------------------------------------------
  // TASKS (STRICT USER ISOLATION)
  // ---------------------------------------------------------------------------
  static getTasks(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.tasks.filter(t => t.user_id === userId || t.userId === userId);
  }

  static createTask(userId, taskData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const taskId = taskData.id || `t_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const isDone = !!(taskData.is_completed ?? taskData.isCompleted);
    const dueDate = taskData.due_date || taskData.dueDate || new Date().toISOString().split('T')[0];
    const dueTime = taskData.due_time || taskData.dueTime || '18:00';

    const newTask = {
      id: taskId,
      user_id: userId,
      userId: userId,
      title: taskData.title || 'Untitled Task',
      description: taskData.description || '',
      category: taskData.category || 'Studies',
      tag: taskData.tag || 'STUDY',
      priority: Number(taskData.priority) || 1,
      quadrant: taskData.quadrant || 'Q1_DO_FIRST',
      due_date: dueDate,
      dueDate: dueDate,
      due_time: dueTime,
      dueTime: dueTime,
      is_completed: isDone,
      isCompleted: isDone,
      completed_at: isDone ? new Date().toISOString() : null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.tasks.push(newTask);
    saveDatabase(db);

    syncToSupabase('tasks', {
      id: newTask.id,
      user_id: newTask.user_id,
      title: newTask.title,
      description: newTask.description,
      category: newTask.category,
      tag: newTask.tag,
      priority: newTask.priority,
      quadrant: newTask.quadrant,
      due_date: newTask.due_date,
      is_completed: newTask.is_completed,
    });

    return newTask;
  }

  static updateTask(userId, taskId, updates) {
    if (!userId || !taskId) return null;
    const db = loadDatabase();
    const idx = db.tasks.findIndex(t => t.id === taskId && (t.user_id === userId || t.userId === userId));
    if (idx === -1) return null;

    const task = db.tasks[idx];
    if (updates.title !== undefined) task.title = updates.title;
    if (updates.description !== undefined) task.description = updates.description;
    if (updates.category !== undefined) task.category = updates.category;
    if (updates.tag !== undefined) task.tag = updates.tag;
    if (updates.priority !== undefined) task.priority = Number(updates.priority);
    if (updates.quadrant !== undefined) task.quadrant = updates.quadrant;

    if (updates.due_date !== undefined || updates.dueDate !== undefined) {
      const d = updates.due_date || updates.dueDate;
      task.due_date = d;
      task.dueDate = d;
    }
    if (updates.due_time !== undefined || updates.dueTime !== undefined) {
      const tm = updates.due_time || updates.dueTime;
      task.due_time = tm;
      task.dueTime = tm;
    }

    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      const done = !!(updates.is_completed ?? updates.isCompleted);
      task.is_completed = done;
      task.isCompleted = done;
      task.completed_at = done ? (task.completed_at || new Date().toISOString()) : null;
    }

    task.updated_at = new Date().toISOString();
    saveDatabase(db);

    syncToSupabase('tasks', {
      id: task.id,
      user_id: task.user_id,
      title: task.title,
      category: task.category,
      priority: task.priority,
      due_date: task.due_date,
      is_completed: task.is_completed,
    });

    return task;
  }

  static deleteTask(userId, taskId) {
    if (!userId || !taskId) return false;
    const db = loadDatabase();
    const initialLen = db.tasks.length;
    db.tasks = db.tasks.filter(t => !(t.id === taskId && (t.user_id === userId || t.userId === userId)));
    if (db.tasks.length !== initialLen) {
      saveDatabase(db);
      deleteFromSupabase('tasks', { id: taskId, user_id: userId });
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // HABITS (STRICT USER ISOLATION & PLAN LIMITS)
  // ---------------------------------------------------------------------------
  static getHabits(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.habits.filter(h => (h.user_id === userId || h.userId === userId) && h.status !== 'archived');
  }

  static getHabitOverview(userId, targetDateStr = null) {
    if (!userId) return { scheduledHabits: [], totalScheduled: 0, completedCount: 0, completionRate: 0 };
    const dateStr = targetDateStr || new Date().toISOString().split('T')[0];
    const userHabits = this.getHabits(userId);
    const db = loadDatabase();
    const userLogs = db.habit_logs.filter(hl => hl.user_id === userId || hl.userId === userId);

    const scheduled = userHabits.map(h => {
      const completed = userLogs.some(hl => (hl.habit_id === h.id || hl.habitId === h.id) && (hl.completed_date === dateStr || hl.date === dateStr));
      return {
        ...h,
        isCompleted: completed,
        is_completed: completed,
      };
    });

    const completedCount = scheduled.filter(h => h.isCompleted).length;
    const totalScheduled = scheduled.length;
    const completionRate = totalScheduled > 0 ? completedCount / totalScheduled : 0;

    return {
      date: dateStr,
      scheduledHabits: scheduled,
      totalScheduled,
      completedCount,
      completionRate,
    };
  }

  static createHabit(userId, habitData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const sub = this.getUserSubscription(userId);
    const activeHabits = db.habits.filter(h => (h.user_id === userId || h.userId === userId) && h.status === 'active');

    // Free tier max 2 active habits
    if (!sub.isPro && activeHabits.length >= 2) {
      return {
        error: 'FREE_LIMIT_REACHED',
        message: 'Free tier is limited to 2 active habits. Upgrade to Pro for unlimited habits.',
      };
    }

    const habitId = habitData.id || `h_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const newHabit = {
      id: habitId,
      user_id: userId,
      userId: userId,
      title: habitData.title || 'New Habit',
      description: habitData.description || '',
      category: habitData.category || 'General',
      frequency: habitData.frequency || 'DAILY',
      selected_days: habitData.selected_days || habitData.selectedDays || [1, 2, 3, 4, 5, 6, 7],
      selectedDays: habitData.selected_days || habitData.selectedDays || [1, 2, 3, 4, 5, 6, 7],
      preferred_time: habitData.preferred_time || habitData.preferredTime || '08:00:00',
      icon_name: habitData.icon_name || habitData.iconName || 'repeat',
      iconName: habitData.icon_name || habitData.iconName || 'repeat',
      color_hex: habitData.color_hex || habitData.colorHex || '#10B981',
      colorHex: habitData.color_hex || habitData.colorHex || '#10B981',
      status: 'active',
      streak_day: 0,
      streakDay: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.habits.push(newHabit);
    saveDatabase(db);

    syncToSupabase('habits', {
      id: newHabit.id,
      user_id: newHabit.user_id,
      title: newHabit.title,
      description: newHabit.description,
      category: newHabit.category,
      frequency: newHabit.frequency,
      color_hex: newHabit.color_hex,
      status: newHabit.status,
    });

    return newHabit;
  }

  static updateHabit(userId, habitId, updates) {
    if (!userId || !habitId) return null;
    const db = loadDatabase();
    const idx = db.habits.findIndex(h => h.id === habitId && (h.user_id === userId || h.userId === userId));
    if (idx === -1) return null;

    const habit = db.habits[idx];
    if (updates.title !== undefined) habit.title = updates.title;
    if (updates.description !== undefined) habit.description = updates.description;
    if (updates.category !== undefined) habit.category = updates.category;
    if (updates.frequency !== undefined) habit.frequency = updates.frequency;
    if (updates.selected_days || updates.selectedDays) {
      const days = updates.selected_days || updates.selectedDays;
      habit.selected_days = days;
      habit.selectedDays = days;
    }
    if (updates.preferred_time || updates.preferredTime) {
      const tm = updates.preferred_time || updates.preferredTime;
      habit.preferred_time = tm;
      habit.preferredTime = tm;
    }
    if (updates.icon_name || updates.iconName) {
      const ic = updates.icon_name || updates.iconName;
      habit.icon_name = ic;
      habit.iconName = ic;
    }
    if (updates.color_hex || updates.colorHex) {
      const cl = updates.color_hex || updates.colorHex;
      habit.color_hex = cl;
      habit.colorHex = cl;
    }
    if (updates.status !== undefined) habit.status = updates.status;

    habit.updated_at = new Date().toISOString();
    saveDatabase(db);

    syncToSupabase('habits', {
      id: habit.id,
      user_id: habit.user_id,
      title: habit.title,
      category: habit.category,
      status: habit.status,
    });

    return habit;
  }

  static deleteHabit(userId, habitId) {
    if (!userId || !habitId) return false;
    const db = loadDatabase();
    const initialLen = db.habits.length;
    db.habits = db.habits.filter(h => !(h.id === habitId && (h.user_id === userId || h.userId === userId)));
    db.habit_logs = db.habit_logs.filter(hl => !(hl.habit_id === habitId && (hl.user_id === userId || hl.userId === userId)));
    if (db.habits.length !== initialLen) {
      saveDatabase(db);
      deleteFromSupabase('habits', { id: habitId, user_id: userId });
      deleteFromSupabase('habit_logs', { habit_id: habitId, user_id: userId });
      return true;
    }
    return false;
  }

  static toggleHabitCompletion(userId, habitId, dateStr = null) {
    if (!userId || !habitId) return null;
    const targetDate = dateStr || new Date().toISOString().split('T')[0];
    const db = loadDatabase();

    const existingIdx = db.habit_logs.findIndex(
      hl => (hl.habit_id === habitId || hl.habitId === habitId) &&
            (hl.user_id === userId || hl.userId === userId) &&
            (hl.completed_date === targetDate || hl.date === targetDate)
    );

    let isCompleted = false;
    if (existingIdx !== -1) {
      db.habit_logs.splice(existingIdx, 1);
      isCompleted = false;
      deleteFromSupabase('habit_logs', { habit_id: habitId, user_id: userId, completed_date: targetDate });
    } else {
      const log = {
        id: `hl_${Date.now()}`,
        habit_id: habitId,
        habitId: habitId,
        user_id: userId,
        userId: userId,
        completed_date: targetDate,
        date: targetDate,
        completed_at: new Date().toISOString(),
      };
      db.habit_logs.push(log);
      isCompleted = true;
      syncToSupabase('habit_logs', {
        habit_id: log.habit_id,
        user_id: log.user_id,
        completed_date: log.completed_date,
      });
    }

    saveDatabase(db);
    return { habitId, date: targetDate, isCompleted };
  }

  // ---------------------------------------------------------------------------
  // EXPENSES (PRO TIER GATED & USER ISOLATION)
  // ---------------------------------------------------------------------------
  static getExpenses(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.expenses.filter(e => e.user_id === userId || e.userId === userId);
  }

  static createExpense(userId, expenseData) {
    if (!userId) throw new Error('userId is required');
    const sub = this.getUserSubscription(userId);
    if (!sub.isPro) {
      return {
        error: 'PRO_REQUIRED',
        message: 'Expense tracking is exclusively available on WrindhaOS Pro.',
      };
    }

    const db = loadDatabase();
    const expenseId = expenseData.id || `e_${Date.now()}`;
    const newExp = {
      id: expenseId,
      user_id: userId,
      userId: userId,
      title: expenseData.title || 'Expense',
      amount: Number(expenseData.amount) || 0,
      category: expenseData.category || 'General',
      is_income: !!(expenseData.is_income ?? expenseData.isIncome),
      isIncome: !!(expenseData.is_income ?? expenseData.isIncome),
      payment_method: expenseData.payment_method || expenseData.paymentMethod || 'UPI',
      expense_date: expenseData.expense_date || expenseData.date || new Date().toISOString(),
      date: expenseData.expense_date || expenseData.date || new Date().toISOString(),
      created_at: new Date().toISOString(),
    };

    db.expenses.push(newExp);
    saveDatabase(db);

    syncToSupabase('expenses', {
      id: newExp.id,
      user_id: newExp.user_id,
      title: newExp.title,
      amount: newExp.amount,
      category: newExp.category,
      is_income: newExp.is_income,
      expense_date: newExp.expense_date,
    });

    return newExp;
  }

  static deleteExpense(userId, expenseId) {
    if (!userId || !expenseId) return false;
    const db = loadDatabase();
    const initialLen = db.expenses.length;
    db.expenses = db.expenses.filter(e => !(e.id === expenseId && (e.user_id === userId || e.userId === userId)));
    if (db.expenses.length !== initialLen) {
      saveDatabase(db);
      deleteFromSupabase('expenses', { id: expenseId, user_id: userId });
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // STUDY SUBJECTS & CURRICULUM
  // ---------------------------------------------------------------------------
  static getSubjects(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.study_subjects.filter(s => s.user_id === userId || s.userId === userId);
  }

  static createSubject(userId, subjectData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const sub = this.getUserSubscription(userId);
    const userSubs = db.study_subjects.filter(s => s.user_id === userId || s.userId === userId);

    if (!sub.isPro && userSubs.length >= 2) {
      return {
        error: 'FREE_LIMIT_REACHED',
        message: 'Free tier is limited to 2 subjects. Upgrade to Pro for unlimited subjects.',
      };
    }

    const subjId = subjectData.id || `s_${Date.now()}`;
    const name = subjectData.subject_name || subjectData.name || 'Subject';
    const color = subjectData.color_hex || subjectData.colorHex || '#0D5CE5';

    const newSubj = {
      id: subjId,
      user_id: userId,
      userId: userId,
      subject_name: name,
      name: name,
      color_hex: color,
      colorHex: color,
      total_hours_logged: 0,
      created_at: new Date().toISOString(),
    };

    db.study_subjects.push(newSubj);
    saveDatabase(db);

    syncToSupabase('study_subjects', {
      id: newSubj.id,
      user_id: newSubj.user_id,
      subject_name: newSubj.subject_name,
      color_hex: newSubj.color_hex,
    });

    return newSubj;
  }

  // ---------------------------------------------------------------------------
  // GOALS & CAREER ROADMAP (PRO TIER GATED)
  // ---------------------------------------------------------------------------
  static getGoals(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.goals.filter(g => g.user_id === userId || g.userId === userId);
  }

  static createGoal(userId, goalData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const goalId = goalData.id || `g_${Date.now()}`;
    const isDone = !!(goalData.is_achieved || goalData.isCompleted || goalData.isAchieved);

    const newGoal = {
      id: goalId,
      user_id: userId,
      userId: userId,
      title: goalData.title || 'Goal',
      timeframe: goalData.timeframe || goalData.tier || 'SHORT',
      target_date: goalData.target_date || goalData.targetDate || null,
      aligned_purpose: goalData.aligned_purpose || goalData.alignedPurpose || '',
      progress_percentage: Number(goalData.progress_percentage || goalData.progress || 0),
      is_achieved: isDone,
      isCompleted: isDone,
      created_at: new Date().toISOString(),
    };

    db.goals.push(newGoal);
    saveDatabase(db);

    syncToSupabase('goals', {
      id: newGoal.id,
      user_id: newGoal.user_id,
      title: newGoal.title,
      timeframe: newGoal.timeframe,
      is_achieved: newGoal.is_achieved,
    });

    return newGoal;
  }

  // ---------------------------------------------------------------------------
  // CALENDAR EVENTS
  // ---------------------------------------------------------------------------
  static getCalendarEvents(userId) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.calendar_events.filter(ce => ce.user_id === userId || ce.userId === userId);
  }

  static createCalendarEvent(userId, eventData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const eventId = eventData.id || `ce_${Date.now()}`;

    const newEvent = {
      id: eventId,
      user_id: userId,
      userId: userId,
      title: eventData.title || 'Event',
      description: eventData.description || '',
      start_time: eventData.start_time || eventData.startTime || new Date().toISOString(),
      end_time: eventData.end_time || eventData.endTime || new Date().toISOString(),
      location: eventData.location || '',
      event_type: eventData.event_type || eventData.eventType || 'Focus Session',
      is_completed: !!(eventData.is_completed || eventData.isCompleted),
      created_at: new Date().toISOString(),
    };

    db.calendar_events.push(newEvent);
    saveDatabase(db);

    syncToSupabase('calendar_events', {
      id: newEvent.id,
      user_id: newEvent.user_id,
      title: newEvent.title,
      start_time: newEvent.start_time,
      end_time: newEvent.end_time,
    });

    return newEvent;
  }

  // ---------------------------------------------------------------------------
  // COUPONS & REFERRALS
  // ---------------------------------------------------------------------------
  static applyCoupon(userId, code) {
    if (!userId || !code) return { success: false, message: 'Invalid coupon code.' };
    const cleanCode = code.trim().toUpperCase();
    const db = loadDatabase();

    const coupon = db.coupons.find(c => c.code.toUpperCase() === cleanCode && c.active);
    if (!coupon) {
      return { success: false, message: 'Invalid or expired coupon code.' };
    }

    // Upgrade user subscription to PRO
    const sub = this.upgradeSubscription(userId, coupon.plan || 'pro', 'COUPON', `cpn_${cleanCode}`);
    db.coupon_usages.push({
      id: `cpu_${Date.now()}`,
      userId,
      code: cleanCode,
      usedAt: new Date().toISOString(),
    });
    saveDatabase(db);

    return {
      success: true,
      message: `Coupon ${cleanCode} applied! Pro tier unlocked.`,
      subscription: sub,
    };
  }
}

module.exports = {
  DatabaseManager,
  hashPassword,
  verifyPassword,
  loadDatabase,
  saveDatabase,
};
