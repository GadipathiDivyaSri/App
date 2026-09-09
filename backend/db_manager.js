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
// 1. CRYPTOGRAPHIC SECURITY HELPERS
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

function ensureUuid(id) {
  if (id && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
    return id;
  }
  return crypto.randomUUID();
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
    milestones: [],
    study_subjects: [],
    study_units: [],
    study_items: [],
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
// 3. PERSISTENT STORAGE ENGINE
// -----------------------------------------------------------------------------
function loadDatabase() {
  try {
    if (!fs.existsSync(DB_FILE)) {
      const initial = getEmptyDatabaseSchema();
      saveDatabase(initial);
      return initial;
    }
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    const schema = getEmptyDatabaseSchema();
    return Object.assign(schema, parsed);
  } catch (err) {
    console.error('[DB LOAD ERROR]:', err.message);
    return getEmptyDatabaseSchema();
  }
}

function saveDatabase(db) {
  try {
    const jsonStr = JSON.stringify(db, null, 2);
    fs.writeFileSync(DB_TMP_FILE, jsonStr, 'utf8');
    fs.renameSync(DB_TMP_FILE, DB_FILE);
  } catch (err) {
    console.error('[DB SAVE ERROR]:', err.message);
  }
}

// -----------------------------------------------------------------------------
// 4. SUPABASE CLOUD POSTGRESQL SYNC ENGINE (ALL 12 CLOUD TABLES)
// -----------------------------------------------------------------------------
async function syncToSupabase(entityType, record) {
  if (!isSupabaseConfigured() || !supabase) return;
  try {
    const uid = ensureUuid(record.user_id || record.userId);
    if (!uid) return;

    if (entityType === 'profiles' || entityType === 'user_profiles') {
      try {
        const { data: authUser } = await supabase.auth.admin.getUserById(uid);
        if (!authUser || !authUser.user) {
          const userEmail = record.email || `${record.username || 'user'}_${Date.now()}@wrindhaos.in`;
          await supabase.auth.admin.createUser({
            id: uid,
            email: userEmail,
            email_confirm: true,
            user_metadata: { username: record.username, name: record.name }
          });
        }
      } catch (authCreateErr) {
        console.warn('[Supabase Auth Provisioning Notice]:', authCreateErr.message);
      }

      await supabase.from('profiles').upsert({
        id: uid,
        username: record.username || 'user',
        name: record.name || record.display_name || 'Student User',
        email: record.email || '',
        referral_code: record.referral_code || record.referralCode || 'WRINDHA',
      }, { onConflict: 'id' });
    } else if (entityType === 'subscriptions' || entityType === 'user_subscriptions') {
      try {
        const { data: existingSub } = await supabase.from('subscriptions').select('id').eq('user_id', uid).maybeSingle();
        const subPayload = {
          user_id: uid,
          plan: (record.plan || '').toLowerCase() === 'pro' || (record.plan || '').toLowerCase() === 'premium' ? 'premium' : 'free',
          status: record.status || 'active',
          billing_provider: record.payment_provider || record.paymentProvider || 'NONE',
          started_at: record.started_at || record.startedAt || new Date().toISOString(),
        };
        if (existingSub && existingSub.id) {
          subPayload.id = existingSub.id;
        }
        await supabase.from('subscriptions').upsert(subPayload);
      } catch (subUpsertErr) {
        console.warn('[Supabase Subscription Sync Notice]:', subUpsertErr.message);
      }
    } else if (entityType === 'tasks') {
      await supabase.from('tasks').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        title: record.title || 'Task',
        description: record.description || null,
        category: record.category || 'Studies',
        priority: Number(record.priority) || 1,
        is_completed: !!(record.is_completed ?? record.isCompleted),
        due_at: record.due_date || record.dueDate || null,
      }, { onConflict: 'id' });
    } else if (entityType === 'habits') {
      const freq = (record.frequency || 'daily').toLowerCase();
      const validFreq = ['daily', 'weekly', 'custom'].includes(freq) ? freq : 'daily';
      await supabase.from('habits').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        title: record.title || 'Habit',
        category: record.category || 'General',
        frequency: validFreq,
        status: record.status || 'active',
        description: record.description || '',
        icon_name: record.icon_name || record.iconName || 'repeat',
        color: record.color_hex || record.colorHex || '#10B981',
      }, { onConflict: 'id' });
    } else if (entityType === 'habit_completions' || entityType === 'habit_logs') {
      await supabase.from('habit_completions').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        habit_id: ensureUuid(record.habit_id || record.habitId),
        completion_date: record.completion_date || record.date || new Date().toISOString().split('T')[0],
        status: 'completed',
        completed_at: record.completed_at || new Date().toISOString(),
      }, { onConflict: 'id' });
    } else if (entityType === 'expenses') {
      const isInc = !!(record.is_income ?? record.isIncome ?? (record.transaction_type === 'income'));
      await supabase.from('expenses').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        title: record.title || 'Expense',
        amount: Number(record.amount) || 0,
        category: record.category || 'General',
        transaction_type: isInc ? 'income' : 'expense',
        payment_method: record.payment_method || record.paymentMethod || 'UPI',
        occurred_at: record.expense_date || record.occurred_at || record.date || new Date().toISOString(),
      }, { onConflict: 'id' });
    } else if (entityType === 'subjects' || entityType === 'study_subjects') {
      await supabase.from('subjects').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        name: record.name || record.subject_name || 'Subject',
        code: record.code || '',
        color: record.color_hex || record.colorHex || record.color || '#0D5CE5',
      }, { onConflict: 'id' });
    } else if (entityType === 'study_units') {
      await supabase.from('study_units').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        subject_id: ensureUuid(record.subject_id || record.subjectId),
        unit_number: Number(record.unit_number || record.order) || 1,
        title: record.title || record.unit_title || 'Unit',
        status: (record.is_completed || record.isCompleted || record.status === 'completed') ? 'completed' : ((record.status === 'in_progress') ? 'in_progress' : 'pending'),
      }, { onConflict: 'id' });
    } else if (entityType === 'study_items') {
      await supabase.from('study_items').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        subject_id: ensureUuid(record.subject_id || record.subjectId),
        title: record.title || 'Study Item',
        status: (record.is_completed || record.isCompleted || record.status === 'completed') ? 'completed' : ((record.status === 'in_progress') ? 'in_progress' : 'pending'),
      }, { onConflict: 'id' });
    } else if (entityType === 'goals' || entityType === 'career_roadmap') {
      const rawTier = (record.tier || record.timeframe || record.section || 'short').toString().toLowerCase().trim();
      let normalizedTier = 'short';
      if (rawTier.includes('med')) normalizedTier = 'medium';
      else if (rawTier.includes('long') || rawTier.includes('career') || rawTier.includes('goal') || rawTier.includes('skill') || rawTier.includes('project') || rawTier.includes('learn') || rawTier.includes('exp') || rawTier.includes('opp')) normalizedTier = 'long';

      await supabase.from('goals').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        title: record.title || 'Goal',
        description: record.description || record.aligned_purpose || null,
        tier: normalizedTier,
        is_completed: !!(record.is_completed || record.isCompleted || record.isAchieved || record.status === 'COMPLETED'),
        target_date: record.target_date || record.targetDate || null,
      }, { onConflict: 'id' });
    } else if (entityType === 'milestones') {
      await supabase.from('milestones').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        goal_id: ensureUuid(record.goal_id || record.goalId),
        title: record.title || record.milestone_title || 'Milestone',
        description: record.description || null,
        is_completed: !!(record.is_completed || record.isCompleted),
        target_date: record.target_date || record.targetDate || null,
      }, { onConflict: 'id' });
    } else if (entityType === 'calendar_events') {
      const d = record.event_date || record.date || (record.start_time ? record.start_time.split('T')[0] : new Date().toISOString().split('T')[0]);
      let startTime = record.start_time?.includes('T') ? record.start_time.split('T')[1].substring(0, 8) : (record.start_time || '10:00:00');
      let endTime = record.end_time?.includes('T') ? record.end_time.split('T')[1].substring(0, 8) : (record.end_time || '11:00:00');
      if (startTime.length === 5) startTime += ':00';
      if (endTime.length === 5) endTime += ':00';

      await supabase.from('calendar_events').upsert({
        id: ensureUuid(record.id),
        user_id: uid,
        title: record.title || 'Event',
        description: record.description || null,
        event_date: d,
        start_time: startTime,
        end_time: endTime,
        category: record.category || record.event_type || record.eventType || 'General',
        is_all_day: !!(record.is_all_day ?? record.isAllDay),
      }, { onConflict: 'id' });
    }
  } catch (err) {
    console.warn(`[Supabase Sync Notice] (${entityType}):`, err.message);
  }
}

async function deleteFromSupabase(table, matchObj) {
  if (!isSupabaseConfigured() || !supabase) return;
  try {
    const tableName = table === 'user_profiles' ? 'profiles' : (table === 'user_subscriptions' ? 'subscriptions' : (table === 'study_subjects' ? 'subjects' : (table === 'habit_logs' ? 'habit_completions' : table)));
    const cleanMatch = {};
    for (const [k, v] of Object.entries(matchObj)) {
      if (k === 'id' || k.endsWith('_id')) {
        cleanMatch[k] = ensureUuid(v);
      } else {
        cleanMatch[k] = v;
      }
    }
    await supabase.from(tableName).delete().match(cleanMatch);
  } catch (err) {
    console.warn(`[Supabase Delete Notice] (${table}):`, err.message);
  }
}

// -----------------------------------------------------------------------------
// 5. UNIFIED DATABASE ACCESS LAYER
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
    const userId = ensureUuid(userData.id);
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

    const newSub = {
      id: ensureUuid(),
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

    syncToSupabase('user_profiles', newUser);
    syncToSupabase('user_subscriptions', newSub);

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
    if (updates.password || updates.password_hash) {
      user.password = updates.password_hash || hashPassword(updates.password);
      user.password_hash = updates.password_hash || hashPassword(updates.password);
    }
    user.updated_at = new Date().toISOString();

    saveDatabase(db);
    syncToSupabase('user_profiles', user);

    return user;
  }

  static deleteUser(userId) {
    if (!userId) return false;
    const db = loadDatabase();
    db.user_profiles = db.user_profiles.filter(u => u.id !== userId && u.user_id !== userId);
    db.user_subscriptions = db.user_subscriptions.filter(s => s.user_id !== userId && s.userId !== userId);
    db.tasks = db.tasks.filter(t => t.user_id !== userId && t.userId !== userId);
    db.habits = db.habits.filter(h => h.user_id !== userId && h.userId !== userId);
    db.habit_logs = db.habit_logs.filter(hl => hl.user_id !== userId && hl.userId !== userId);
    db.expenses = db.expenses.filter(e => e.user_id !== userId && e.userId !== userId);
    db.goals = db.goals.filter(g => g.user_id !== userId && g.userId !== userId);
    db.milestones = db.milestones.filter(m => m.user_id !== userId && m.userId !== userId);
    db.study_subjects = db.study_subjects.filter(s => s.user_id !== userId && s.userId !== userId);
    db.study_units = db.study_units.filter(u => u.user_id !== userId && u.userId !== userId);
    db.study_items = db.study_items.filter(i => i.user_id !== userId && i.userId !== userId);
    db.calendar_events = db.calendar_events.filter(ce => ce.user_id !== userId && ce.userId !== userId);
    saveDatabase(db);

    deleteFromSupabase('user_profiles', { id: userId });
    deleteFromSupabase('user_subscriptions', { user_id: userId });
    deleteFromSupabase('tasks', { user_id: userId });
    deleteFromSupabase('habits', { user_id: userId });
    deleteFromSupabase('habit_logs', { user_id: userId });
    deleteFromSupabase('expenses', { user_id: userId });
    deleteFromSupabase('goals', { user_id: userId });
    deleteFromSupabase('milestones', { user_id: userId });
    deleteFromSupabase('study_subjects', { user_id: userId });
    deleteFromSupabase('study_units', { user_id: userId });
    deleteFromSupabase('study_items', { user_id: userId });
    deleteFromSupabase('calendar_events', { user_id: userId });

    return true;
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS & BILLING
  // ---------------------------------------------------------------------------
  static getUserSubscription(userId) {
    if (!userId) return { plan: 'free', isPro: false, isFree: true, status: 'active' };
    const db = loadDatabase();
    const sub = db.user_subscriptions.find(s => s.user_id === userId || s.userId === userId);
    const user = this.getUserById(userId);

    const isPro = (sub && sub.plan === 'pro') || (user && user.is_premium) || (user && user.subscription_plan === 'PRO');
    return {
      id: sub ? sub.id : `sub_${userId}`,
      userId,
      user_id: userId,
      plan: isPro ? 'pro' : 'free',
      isPro,
      isPremium: isPro,
      isFree: !isPro,
      status: sub ? sub.status : 'active',
      started_at: sub ? sub.started_at : new Date().toISOString(),
      expires_at: sub ? sub.expires_at : null,
      payment_provider: sub ? sub.payment_provider : 'NONE',
    };
  }

  static upgradeSubscription(userId, plan = 'pro', paymentProvider = 'GOOGLE_PLAY', transactionId = null) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    let sub = db.user_subscriptions.find(s => s.user_id === userId || s.userId === userId);

    if (!sub) {
      sub = {
        id: ensureUuid(),
        user_id: userId,
        userId: userId,
        plan: plan.toLowerCase(),
        status: 'active',
        started_at: new Date().toISOString(),
        expires_at: '2030-12-31T23:59:59.000Z',
        payment_provider: paymentProvider,
        transaction_id: transactionId,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      db.user_subscriptions.push(sub);
    } else {
      sub.plan = plan.toLowerCase();
      sub.status = 'active';
      sub.expires_at = '2030-12-31T23:59:59.000Z';
      sub.payment_provider = paymentProvider;
      sub.transaction_id = transactionId;
      sub.updated_at = new Date().toISOString();
    }

    const userIdx = db.user_profiles.findIndex(u => u.id === userId || u.user_id === userId);
    if (userIdx !== -1) {
      db.user_profiles[userIdx].is_premium = true;
      db.user_profiles[userIdx].isPremium = true;
      db.user_profiles[userIdx].subscription_plan = 'PRO';
      db.user_profiles[userIdx].subscriptionPlan = 'PRO';
      db.user_profiles[userIdx].updated_at = new Date().toISOString();
      syncToSupabase('user_profiles', db.user_profiles[userIdx]);
    }

    saveDatabase(db);
    syncToSupabase('user_subscriptions', sub);

    return this.getUserSubscription(userId);
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
    const taskId = ensureUuid(taskData.id);

    const isDone = !!(taskData.is_completed ?? taskData.isCompleted);
    const newTask = {
      id: taskId,
      user_id: userId,
      userId: userId,
      title: taskData.title || 'New Task',
      description: taskData.description || '',
      category: taskData.category || 'Studies',
      priority: Number(taskData.priority) || 1,
      is_completed: isDone,
      isCompleted: isDone,
      due_date: taskData.due_date || taskData.dueDate || new Date().toISOString(),
      dueDate: taskData.due_date || taskData.dueDate || new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.tasks.push(newTask);
    saveDatabase(db);
    syncToSupabase('tasks', newTask);

    return newTask;
  }

  static updateTask(userId, taskId, updates) {
    if (!userId || !taskId) return null;
    const db = loadDatabase();
    const idx = db.tasks.findIndex(t => (t.id === taskId) && (t.user_id === userId || t.userId === userId));
    if (idx === -1) return null;

    const task = db.tasks[idx];
    if (updates.title !== undefined) task.title = updates.title;
    if (updates.description !== undefined) task.description = updates.description;
    if (updates.category !== undefined) task.category = updates.category;
    if (updates.priority !== undefined) task.priority = Number(updates.priority) || 1;
    if (updates.due_date || updates.dueDate) {
      const d = updates.due_date || updates.dueDate;
      task.due_date = d;
      task.dueDate = d;
    }
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      const done = !!(updates.is_completed ?? updates.isCompleted);
      task.is_completed = done;
      task.isCompleted = done;
      task.completed_at = done ? (task.completed_at || new Date().toISOString()) : null;
    }

    task.updated_at = new Date().toISOString();
    saveDatabase(db);
    syncToSupabase('tasks', task);

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
  // HABITS & HABIT COMPLETIONS (PLAN LIMITS ENFORCED)
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

    const habitId = ensureUuid(habitData.id);
    const newHabit = {
      id: habitId,
      user_id: userId,
      userId: userId,
      title: habitData.title || 'New Habit',
      description: habitData.description || '',
      category: habitData.category || 'General',
      frequency: (habitData.frequency || 'daily').toLowerCase(),
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
    syncToSupabase('habits', newHabit);

    return newHabit;
  }

  static updateHabit(userId, habitId, updates) {
    if (!userId || !habitId) return null;
    const db = loadDatabase();
    const idx = db.habits.findIndex(h => (h.id === habitId) && (h.user_id === userId || h.userId === userId));
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
    if (updates.color_hex || updates.colorHex) {
      const cl = updates.color_hex || updates.colorHex;
      habit.color_hex = cl;
      habit.colorHex = cl;
    }
    if (updates.status !== undefined) habit.status = updates.status;

    habit.updated_at = new Date().toISOString();
    saveDatabase(db);
    syncToSupabase('habits', habit);

    return habit;
  }

  static deleteHabit(userId, habitId) {
    if (!userId || !habitId) return false;
    const db = loadDatabase();
    const initialLen = db.habits.length;
    db.habits = db.habits.filter(h => !(h.id === habitId && (h.user_id === userId || h.userId === userId)));
    db.habit_logs = db.habit_logs.filter(hl => !((hl.habit_id === habitId || hl.habitId === habitId) && (hl.user_id === userId || hl.userId === userId)));
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
      const removed = db.habit_logs.splice(existingIdx, 1)[0];
      isCompleted = false;
      deleteFromSupabase('habit_logs', { id: removed.id });
    } else {
      const log = {
        id: ensureUuid(),
        habit_id: habitId,
        habitId: habitId,
        user_id: userId,
        userId: userId,
        completion_date: targetDate,
        completed_date: targetDate,
        date: targetDate,
        status: 'completed',
        completed_at: new Date().toISOString(),
      };
      db.habit_logs.push(log);
      isCompleted = true;
      syncToSupabase('habit_completions', log);
    }

    saveDatabase(db);
    return { habitId, date: targetDate, isCompleted };
  }

  // ---------------------------------------------------------------------------
  // EXPENSES (PRO TIER GATED)
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
    const expenseId = ensureUuid(expenseData.id);
    const newExp = {
      id: expenseId,
      user_id: userId,
      userId: userId,
      title: expenseData.title || 'Expense',
      amount: Number(expenseData.amount) || 0,
      category: expenseData.category || 'General',
      is_income: !!(expenseData.is_income ?? expenseData.isIncome ?? (expenseData.transaction_type === 'income')),
      isIncome: !!(expenseData.is_income ?? expenseData.isIncome ?? (expenseData.transaction_type === 'income')),
      transaction_type: (expenseData.is_income || expenseData.isIncome || expenseData.transaction_type === 'income') ? 'income' : 'expense',
      payment_method: expenseData.payment_method || expenseData.paymentMethod || 'UPI',
      expense_date: expenseData.expense_date || expenseData.date || new Date().toISOString(),
      date: expenseData.expense_date || expenseData.date || new Date().toISOString(),
      created_at: new Date().toISOString(),
    };

    db.expenses.push(newExp);
    saveDatabase(db);
    syncToSupabase('expenses', newExp);

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
  // STUDY SUBJECTS, UNITS & ITEMS
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

    const subjId = ensureUuid(subjectData.id);
    const name = subjectData.subject_name || subjectData.name || 'Subject';
    const color = subjectData.color_hex || subjectData.colorHex || subjectData.color || '#0D5CE5';

    const newSubj = {
      id: subjId,
      user_id: userId,
      userId: userId,
      subject_name: name,
      name: name,
      code: subjectData.code || '',
      color_hex: color,
      colorHex: color,
      color: color,
      created_at: new Date().toISOString(),
    };

    db.study_subjects.push(newSubj);
    saveDatabase(db);
    syncToSupabase('subjects', newSubj);

    return newSubj;
  }

  static deleteSubject(userId, subjectId) {
    if (!userId || !subjectId) return false;
    const db = loadDatabase();
    db.study_subjects = db.study_subjects.filter(s => !(s.id === subjectId && (s.user_id === userId || s.userId === userId)));
    db.study_units = db.study_units.filter(u => !(u.subject_id === subjectId && (u.user_id === userId || u.userId === userId)));
    db.study_items = db.study_items.filter(i => !(i.subject_id === subjectId && (i.user_id === userId || i.userId === userId)));
    saveDatabase(db);

    deleteFromSupabase('subjects', { id: subjectId, user_id: userId });
    deleteFromSupabase('study_units', { subject_id: subjectId, user_id: userId });
    deleteFromSupabase('study_items', { subject_id: subjectId, user_id: userId });
    return true;
  }

  static getStudyUnits(userId, subjectId = null) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.study_units.filter(u => (u.user_id === userId || u.userId === userId) && (!subjectId || u.subject_id === subjectId || u.subjectId === subjectId));
  }

  static createStudyUnit(userId, unitData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const unitId = ensureUuid(unitData.id);
    const subId = ensureUuid(unitData.subject_id || unitData.subjectId);

    const newUnit = {
      id: unitId,
      user_id: userId,
      userId: userId,
      subject_id: subId,
      subjectId: subId,
      unit_number: Number(unitData.unit_number || unitData.order) || 1,
      title: unitData.title || unitData.unit_title || 'Unit',
      description: unitData.description || '',
      status: unitData.status || 'pending',
      created_at: new Date().toISOString(),
    };

    db.study_units.push(newUnit);
    saveDatabase(db);
    syncToSupabase('study_units', newUnit);

    return newUnit;
  }

  static deleteStudyUnit(userId, unitId) {
    if (!userId || !unitId) return false;
    const db = loadDatabase();
    db.study_units = db.study_units.filter(u => !(u.id === unitId && (u.user_id === userId || u.userId === userId)));
    saveDatabase(db);
    deleteFromSupabase('study_units', { id: unitId, user_id: userId });
    return true;
  }

  static getStudyItems(userId, subjectId = null) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.study_items.filter(i => (i.user_id === userId || i.userId === userId) && (!subjectId || i.subject_id === subjectId || i.subjectId === subjectId));
  }

  static createStudyItem(userId, itemData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const itemId = ensureUuid(itemData.id);
    const subId = ensureUuid(itemData.subject_id || itemData.subjectId);

    const newItem = {
      id: itemId,
      user_id: userId,
      userId: userId,
      subject_id: subId,
      subjectId: subId,
      title: itemData.title || 'Study Task',
      description: itemData.description || '',
      status: itemData.status || 'pending',
      is_completed: itemData.status === 'completed' || !!itemData.isCompleted,
      created_at: new Date().toISOString(),
    };

    db.study_items.push(newItem);
    saveDatabase(db);
    syncToSupabase('study_items', newItem);

    return newItem;
  }

  static deleteStudyItem(userId, itemId) {
    if (!userId || !itemId) return false;
    const db = loadDatabase();
    db.study_items = db.study_items.filter(i => !(i.id === itemId && (i.user_id === userId || i.userId === userId)));
    saveDatabase(db);
    deleteFromSupabase('study_items', { id: itemId, user_id: userId });
    return true;
  }

  // ---------------------------------------------------------------------------
  // GOALS & MILESTONES (PRO CAREER ROADMAP & HIERARCHY)
  // ---------------------------------------------------------------------------
  static getGoals(userId, tierFilter = null) {
    if (!userId) return [];
    const db = loadDatabase();
    let userGoals = db.goals.filter(g => g.user_id === userId || g.userId === userId);
    if (tierFilter) {
      const cleanFilter = tierFilter.toLowerCase();
      userGoals = userGoals.filter(g => (g.tier || g.timeframe || '').toLowerCase().includes(cleanFilter));
    }
    return userGoals;
  }

  static createGoal(userId, goalData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const goalId = ensureUuid(goalData.id);
    const isDone = !!(goalData.is_completed || goalData.isCompleted || goalData.is_achieved || goalData.isAchieved || goalData.status === 'COMPLETED');

    const rawTier = (goalData.tier || goalData.timeframe || goalData.section || 'short').toString().toLowerCase().trim();
    let normalizedTier = 'short';
    if (rawTier.includes('med')) normalizedTier = 'medium';
    else if (rawTier.includes('long') || rawTier.includes('career') || rawTier.includes('goal') || rawTier.includes('skill') || rawTier.includes('project') || rawTier.includes('learn') || rawTier.includes('exp') || rawTier.includes('opp')) normalizedTier = 'long';

    const newGoal = {
      id: goalId,
      user_id: userId,
      userId: userId,
      title: goalData.title || 'Goal',
      description: goalData.description || goalData.aligned_purpose || goalData.alignedPurpose || '',
      tier: normalizedTier,
      timeframe: normalizedTier,
      section: goalData.section || 'GOAL',
      target_date: goalData.target_date || goalData.targetDate || null,
      aligned_purpose: goalData.aligned_purpose || goalData.alignedPurpose || '',
      progress_percentage: Number(goalData.progress_percentage || goalData.progress || 0),
      is_completed: isDone,
      isCompleted: isDone,
      status: isDone ? 'COMPLETED' : 'PLANNED',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.goals.push(newGoal);
    saveDatabase(db);
    syncToSupabase('goals', newGoal);

    return newGoal;
  }

  static updateGoal(userId, goalId, updates) {
    if (!userId || !goalId) return null;
    const db = loadDatabase();
    const idx = db.goals.findIndex(g => (g.id === goalId) && (g.user_id === userId || g.userId === userId));
    if (idx === -1) return null;

    const goal = db.goals[idx];
    if (updates.title !== undefined) goal.title = updates.title;
    if (updates.description !== undefined) goal.description = updates.description;
    if (updates.tier !== undefined || updates.timeframe !== undefined || updates.section !== undefined) {
      const rawTier = (updates.tier || updates.timeframe || updates.section || goal.tier).toString().toLowerCase().trim();
      let normalizedTier = 'short';
      if (rawTier.includes('med')) normalizedTier = 'medium';
      else if (rawTier.includes('long') || rawTier.includes('career') || rawTier.includes('goal') || rawTier.includes('skill') || rawTier.includes('project') || rawTier.includes('learn') || rawTier.includes('exp') || rawTier.includes('opp')) normalizedTier = 'long';
      goal.tier = normalizedTier;
      goal.timeframe = normalizedTier;
    }
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined || updates.status !== undefined) {
      const isDone = !!(updates.is_completed ?? updates.isCompleted ?? (updates.status === 'COMPLETED'));
      goal.is_completed = isDone;
      goal.isCompleted = isDone;
      goal.status = isDone ? 'COMPLETED' : 'PLANNED';
      goal.completed_at = isDone ? new Date().toISOString() : null;
    }
    if (updates.progress_percentage !== undefined || updates.progress !== undefined) {
      goal.progress_percentage = Number(updates.progress_percentage || updates.progress || 0);
    }
    goal.updated_at = new Date().toISOString();

    saveDatabase(db);
    syncToSupabase('goals', goal);

    return goal;
  }

  static deleteGoal(userId, goalId) {
    if (!userId || !goalId) return false;
    const db = loadDatabase();
    const initialLen = db.goals.length;
    db.goals = db.goals.filter(g => !(g.id === goalId && (g.user_id === userId || g.userId === userId)));
    db.milestones = db.milestones.filter(m => !(m.goal_id === goalId && (m.user_id === userId || m.userId === userId)));
    if (db.goals.length !== initialLen) {
      saveDatabase(db);
      deleteFromSupabase('goals', { id: goalId, user_id: userId });
      deleteFromSupabase('milestones', { goal_id: goalId, user_id: userId });
      return true;
    }
    return false;
  }

  static getMilestones(userId, goalId = null) {
    if (!userId) return [];
    const db = loadDatabase();
    return db.milestones.filter(m => (m.user_id === userId || m.userId === userId) && (!goalId || m.goal_id === goalId || m.goalId === goalId));
  }

  static createMilestone(userId, milestoneData) {
    if (!userId) throw new Error('userId is required');
    const db = loadDatabase();
    const msId = ensureUuid(milestoneData.id);
    const goalId = ensureUuid(milestoneData.goal_id || milestoneData.goalId);

    const isDone = !!(milestoneData.is_completed || milestoneData.isCompleted);
    const newMs = {
      id: msId,
      user_id: userId,
      userId: userId,
      goal_id: goalId,
      goalId: goalId,
      title: milestoneData.title || milestoneData.milestone_title || 'Milestone',
      description: milestoneData.description || '',
      is_completed: isDone,
      isCompleted: isDone,
      target_date: milestoneData.target_date || milestoneData.targetDate || null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    db.milestones.push(newMs);
    saveDatabase(db);
    syncToSupabase('milestones', newMs);

    return newMs;
  }

  static deleteMilestone(userId, milestoneId) {
    if (!userId || !milestoneId) return false;
    const db = loadDatabase();
    db.milestones = db.milestones.filter(m => !(m.id === milestoneId && (m.user_id === userId || m.userId === userId)));
    saveDatabase(db);
    deleteFromSupabase('milestones', { id: milestoneId, user_id: userId });
    return true;
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
    const eventId = ensureUuid(eventData.id);

    const newEvent = {
      id: eventId,
      user_id: userId,
      userId: userId,
      title: eventData.title || 'Event',
      description: eventData.description || '',
      start_time: eventData.start_time || eventData.startTime || new Date().toISOString(),
      end_time: eventData.end_time || eventData.endTime || new Date().toISOString(),
      event_date: eventData.event_date || eventData.date || (eventData.start_time ? eventData.start_time.split('T')[0] : new Date().toISOString().split('T')[0]),
      category: eventData.category || eventData.event_type || eventData.eventType || 'General',
      is_all_day: !!(eventData.is_all_day ?? eventData.isAllDay),
      created_at: new Date().toISOString(),
    };

    db.calendar_events.push(newEvent);
    saveDatabase(db);
    syncToSupabase('calendar_events', newEvent);

    return newEvent;
  }

  static deleteCalendarEvent(userId, eventId) {
    if (!userId || !eventId) return false;
    const db = loadDatabase();
    db.calendar_events = db.calendar_events.filter(ce => !(ce.id === eventId && (ce.user_id === userId || ce.userId === userId)));
    saveDatabase(db);
    deleteFromSupabase('calendar_events', { id: eventId, user_id: userId });
    return true;
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

    const sub = this.upgradeSubscription(userId, coupon.plan || 'pro', 'COUPON', `cpn_${cleanCode}`);
    db.coupon_usages.push({
      id: ensureUuid(),
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
  ensureUuid,
};
