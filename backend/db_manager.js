const crypto = require('crypto');
const { supabase, isConfigured: isSupabaseConfigured } = require('./supabase_client');

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://hkeyywopbkmlclsealbz.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg';

// -----------------------------------------------------------------------------
// 1. CRYPTOGRAPHIC SECURITY HELPERS & UUID GENERATOR
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
  if (!id) return crypto.randomUUID();
  const str = String(id).trim();
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str)) {
    return str;
  }
  const hash = crypto.createHash('sha256').update(str).digest('hex');
  return `${hash.substring(0, 8)}-${hash.substring(8, 12)}-4${hash.substring(13, 16)}-a${hash.substring(17, 20)}-${hash.substring(20, 32)}`;
}

// -----------------------------------------------------------------------------
// 2. DIRECT SUPABASE POSTGRES HTTP REST FALLBACK CLIENT
// -----------------------------------------------------------------------------
async function dbQuery(table, options = {}) {
  const { method = 'GET', body = null, select = '*', match = {}, single = false } = options;
  try {
    if (supabase && typeof supabase.from === 'function') {
      let query = supabase.from(table);
      if (method === 'GET') {
        query = query.select(select);
        for (const [k, v] of Object.entries(match)) query = query.eq(k, v);
        const { data, error } = single ? await query.maybeSingle() : await query;
        if (error) throw error;
        return data;
      }
      if (method === 'POST') {
        const { data, error } = await query.upsert(body).select();
        if (error) throw error;
        return single ? (data ? data[0] : null) : data;
      }
      if (method === 'PATCH' || method === 'PUT') {
        let q = query.update(body);
        for (const [k, v] of Object.entries(match)) q = q.eq(k, v);
        const { data, error } = await q.select();
        if (error) throw error;
        return single ? (data ? data[0] : null) : data;
      }
      if (method === 'DELETE') {
        let q = query.delete();
        for (const [k, v] of Object.entries(match)) q = q.eq(k, v);
        const { data, error } = await q;
        if (error) throw error;
        return true;
      }
    }

    // Direct REST API Fallback
    let endpoint = `${SUPABASE_URL}/rest/v1/${table}`;
    if (method === 'GET') {
      const params = new URLSearchParams({ select });
      for (const [k, v] of Object.entries(match)) params.append(k, `eq.${v}`);
      endpoint += `?${params.toString()}`;
    } else if (method === 'DELETE') {
      const params = new URLSearchParams();
      for (const [k, v] of Object.entries(match)) params.append(k, `eq.${v}`);
      endpoint += `?${params.toString()}`;
    }

    const res = await fetch(endpoint, {
      method: method === 'PATCH' ? 'POST' : method,
      headers: {
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'apikey': SUPABASE_KEY,
        'Content-Type': 'application/json',
        'Prefer': method === 'POST' ? 'return=representation, resolution=merge-duplicates' : 'return=representation',
      },
      body: body ? JSON.stringify(body) : null,
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`[Postgres ${table} ${method} Error ${res.status}]: ${errText}`);
    }

    if (method === 'DELETE') return true;
    const data = await res.json();
    return single ? (Array.isArray(data) ? data[0] : data) : data;
  } catch (err) {
    console.error(`[Database Engine Error] (${table} ${method}):`, err.message);
    return method === 'GET' ? (single ? null : []) : null;
  }
}

// -----------------------------------------------------------------------------
// 3. UNIFIED DIRECT POSTGRES DATABASE MANAGER
// -----------------------------------------------------------------------------
class DatabaseManager {
  // ---------------------------------------------------------------------------
  // AUTHENTICATION & USER PROFILES
  // ---------------------------------------------------------------------------
  static async getUserById(userId) {
    if (!userId) return null;
    const uid = ensureUuid(userId);
    return await dbQuery('profiles', { method: 'GET', match: { id: uid }, single: true });
  }

  static async getUserByEmailOrUsername(identifier) {
    if (!identifier) return null;
    const clean = identifier.trim().toLowerCase();
    let user = await dbQuery('profiles', { method: 'GET', match: { email: clean }, single: true });
    if (!user) {
      user = await dbQuery('profiles', { method: 'GET', match: { username: clean }, single: true });
    }

    // Merge Supabase Auth metadata (passwordHash) if user or password_hash is missing
    if (isSupabaseConfigured() && supabase) {
      try {
        const { data } = await supabase.auth.admin.listUsers();
        const supUser = (data?.users || []).find(u =>
          (u.email || '').toLowerCase() === clean ||
          (u.user_metadata && (u.user_metadata.username || '').toLowerCase() === clean)
        );
        if (supUser) {
          if (!user) {
            user = {
              id: supUser.id,
              user_id: supUser.id,
              email: supUser.email,
              username: supUser.user_metadata?.username || clean,
              name: supUser.user_metadata?.name || supUser.email.split('@')[0],
              display_name: supUser.user_metadata?.name || supUser.email.split('@')[0],
              is_premium: false,
              subscription_plan: 'FREE',
            };
          }
          if (supUser.user_metadata && supUser.user_metadata.passwordHash) {
            user.password_hash = supUser.user_metadata.passwordHash;
          }
        }
      } catch (supErr) {
        console.warn('[SUPABASE AUTH USER FETCH NOTICE]:', supErr.message);
      }
    }
    return user;
  }

  static async createUser(userData) {
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
      is_premium: !!userData.is_premium,
      subscription_plan: (userData.subscription_plan || 'FREE').toUpperCase(),
      focus_score: userData.focus_score ?? 85,
      active_streak: userData.active_streak ?? 1,
      referral_code: userData.referral_code || ('WRINDHA_' + Math.floor(100000 + Math.random() * 900000)),
      is_email_verified: !!userData.is_email_verified,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const createdProfile = await dbQuery('profiles', { method: 'POST', body: newUser, single: true });
    const resultUser = createdProfile || newUser;

    // Attach password_hash for caller authentication flows
    if (userData.password_hash) {
      resultUser.password_hash = userData.password_hash;
    }

    // Initialize Default Subscription Row
    const newSub = {
      id: ensureUuid(),
      user_id: userId,
      plan: resultUser.is_premium ? 'premium' : 'free',
      status: 'active',
      started_at: new Date().toISOString(),
      payment_provider: resultUser.is_premium ? 'SEED_VIP' : 'NONE',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    await dbQuery('subscriptions', { method: 'POST', body: newSub });

    return resultUser;
  }

  static async updateUser(userId, updates) {
    if (!userId) return null;
    const uid = ensureUuid(userId);
    const payload = { updated_at: new Date().toISOString() };

    if (updates.username) payload.username = updates.username.trim().toLowerCase();
    if (updates.name) payload.name = updates.name;
    if (updates.display_name) payload.display_name = updates.display_name;
    if (updates.focus_score !== undefined) payload.focus_score = updates.focus_score;
    if (updates.active_streak !== undefined) payload.active_streak = updates.active_streak;
    if (updates.is_premium !== undefined) payload.is_premium = !!updates.is_premium;
    if (updates.subscription_plan) payload.subscription_plan = updates.subscription_plan.toUpperCase();

    return await dbQuery('profiles', { method: 'PATCH', match: { id: uid }, body: payload, single: true });
  }

  static async deleteUser(userId) {
    if (!userId) return false;
    const uid = ensureUuid(userId);
    return await dbQuery('profiles', { method: 'DELETE', match: { id: uid } });
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS & BILLING
  // ---------------------------------------------------------------------------
  static async getUserSubscription(userId) {
    if (!userId) return { plan: 'free', isPro: false, isFree: true, status: 'active' };
    const uid = ensureUuid(userId);
    const sub = await dbQuery('subscriptions', { method: 'GET', match: { user_id: uid }, single: true });
    const user = await this.getUserById(uid);

    const isPro = (sub && (sub.plan === 'pro' || sub.plan === 'premium')) || (user && (user.is_premium || user.subscription_plan === 'PRO' || user.subscription_plan === 'PREMIUM'));
    return {
      id: sub ? sub.id : `sub_${uid}`,
      userId: uid,
      user_id: uid,
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

  static async upgradeSubscription(userId, plan = 'pro', paymentProvider = 'GOOGLE_PLAY', transactionId = null) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const planName = plan.toLowerCase() === 'pro' || plan.toLowerCase() === 'premium' ? 'premium' : 'free';

    const subPayload = {
      user_id: uid,
      plan: planName,
      status: 'active',
      started_at: new Date().toISOString(),
      expires_at: '2030-12-31T23:59:59.000Z',
      payment_provider: paymentProvider,
      updated_at: new Date().toISOString(),
    };

    await dbQuery('subscriptions', { method: 'POST', body: subPayload });
    await this.updateUser(uid, { is_premium: true, subscription_plan: 'PRO' });

    return await this.getUserSubscription(uid);
  }

  // ---------------------------------------------------------------------------
  // TASKS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getTasks(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const tasks = await dbQuery('tasks', { method: 'GET', match: { user_id: uid } });
    return (tasks || []).map(t => ({
      ...t,
      userId: t.user_id,
      isCompleted: t.is_completed,
      dueDate: t.due_at || t.due_date,
    }));
  }

  static async createTask(userId, taskData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const taskId = ensureUuid(taskData.id);

    const isDone = !!(taskData.is_completed ?? taskData.isCompleted);
    const newTask = {
      id: taskId,
      user_id: uid,
      title: taskData.title || 'New Task',
      description: taskData.description || '',
      category: taskData.category || 'Studies',
      priority: Number(taskData.priority) || 1,
      quadrant: taskData.quadrant || 'q1_do_first',
      is_completed: isDone,
      due_at: taskData.due_date || taskData.dueDate || taskData.due_at || new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const created = await dbQuery('tasks', { method: 'POST', body: newTask, single: true });
    return { ...created, userId: uid, isCompleted: isDone };
  }

  static async updateTask(userId, taskId, updates) {
    if (!userId || !taskId) return null;
    const uid = ensureUuid(userId);
    const tid = ensureUuid(taskId);

    const payload = { updated_at: new Date().toISOString() };
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.category !== undefined) payload.category = updates.category;
    if (updates.priority !== undefined) payload.priority = Number(updates.priority) || 1;
    if (updates.quadrant !== undefined) payload.quadrant = updates.quadrant;
    if (updates.due_date || updates.dueDate || updates.due_at) {
      payload.due_at = updates.due_date || updates.dueDate || updates.due_at;
    }
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      payload.is_completed = !!(updates.is_completed ?? updates.isCompleted);
    }

    const updated = await dbQuery('tasks', { method: 'PATCH', match: { id: tid, user_id: uid }, body: payload, single: true });
    return updated ? { ...updated, userId: uid, isCompleted: updated.is_completed } : null;
  }

  static async deleteTask(userId, taskId) {
    if (!userId || !taskId) return false;
    const uid = ensureUuid(userId);
    const tid = ensureUuid(taskId);
    return await dbQuery('tasks', { method: 'DELETE', match: { id: tid, user_id: uid } });
  }

  // ---------------------------------------------------------------------------
  // HABITS & HABIT COMPLETIONS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getHabits(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const habits = await dbQuery('habits', { method: 'GET', match: { user_id: uid } });
    return (habits || []).map(h => ({
      ...h,
      userId: h.user_id,
      colorHex: h.color_hex || h.color,
      iconName: h.icon_name,
    }));
  }

  static async getHabitOverview(userId, targetDateStr = null) {
    if (!userId) return { scheduledHabits: [], totalScheduled: 0, completedCount: 0, completionRate: 0 };
    const uid = ensureUuid(userId);
    const dateStr = targetDateStr || new Date().toISOString().split('T')[0];

    const habits = await this.getHabits(uid);
    const completions = await dbQuery('habit_completions', { method: 'GET', match: { user_id: uid, completion_date: dateStr } });
    const completedSet = new Set((completions || []).map(c => c.habit_id));

    const scheduled = habits.map(h => {
      const isDone = completedSet.has(h.id);
      return { ...h, isCompleted: isDone, is_completed: isDone };
    });

    const completedCount = scheduled.filter(h => h.isCompleted).length;
    const totalScheduled = scheduled.length;
    const completionRate = totalScheduled > 0 ? completedCount / totalScheduled : 0;

    return { date: dateStr, scheduledHabits: scheduled, totalScheduled, completedCount, completionRate };
  }

  static async createHabit(userId, habitData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const habitId = ensureUuid(habitData.id);

    const newHabit = {
      id: habitId,
      user_id: uid,
      title: habitData.title || 'New Habit',
      description: habitData.description || '',
      category: habitData.category || 'General',
      frequency: (habitData.frequency || 'daily').toLowerCase(),
      icon_name: habitData.icon_name || habitData.iconName || 'repeat',
      color_hex: habitData.color_hex || habitData.colorHex || habitData.color || '#10B981',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const created = await dbQuery('habits', { method: 'POST', body: newHabit, single: true });
    return { ...created, userId: uid, colorHex: newHabit.color_hex, iconName: newHabit.icon_name };
  }

  static async updateHabit(userId, habitId, updates) {
    if (!userId || !habitId) return null;
    const uid = ensureUuid(userId);
    const hid = ensureUuid(habitId);

    const payload = { updated_at: new Date().toISOString() };
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.category !== undefined) payload.category = updates.category;
    if (updates.frequency !== undefined) payload.frequency = updates.frequency;
    if (updates.color_hex || updates.colorHex || updates.color) {
      payload.color_hex = updates.color_hex || updates.colorHex || updates.color;
    }
    if (updates.status !== undefined) payload.status = updates.status;

    return await dbQuery('habits', { method: 'PATCH', match: { id: hid, user_id: uid }, body: payload, single: true });
  }

  static async deleteHabit(userId, habitId) {
    if (!userId || !habitId) return false;
    const uid = ensureUuid(userId);
    const hid = ensureUuid(habitId);
    await dbQuery('habit_completions', { method: 'DELETE', match: { habit_id: hid, user_id: uid } });
    return await dbQuery('habits', { method: 'DELETE', match: { id: hid, user_id: uid } });
  }

  static async toggleHabitCompletion(userId, habitId, dateStr = null, notes = '') {
    if (!userId || !habitId) return null;
    const uid = ensureUuid(userId);
    const hid = ensureUuid(habitId);
    const targetDate = dateStr || new Date().toISOString().split('T')[0];

    const existing = await dbQuery('habit_completions', { method: 'GET', match: { habit_id: hid, user_id: uid, completion_date: targetDate }, single: true });

    if (existing) {
      await dbQuery('habit_completions', { method: 'DELETE', match: { id: existing.id } });
      return { isCompleted: false, habitId: hid, date: targetDate };
    } else {
      const log = {
        id: ensureUuid(),
        habit_id: hid,
        user_id: uid,
        completion_date: targetDate,
        status: 'completed',
        notes: notes || '',
        completed_at: new Date().toISOString(),
      };
      await dbQuery('habit_completions', { method: 'POST', body: log });
      return { isCompleted: true, habitId: hid, date: targetDate };
    }
  }

  // ---------------------------------------------------------------------------
  // EXPENSES & BUDGETS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getExpenses(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const expenses = await dbQuery('expenses', { method: 'GET', match: { user_id: uid } });
    return (expenses || []).map(e => ({
      ...e,
      userId: e.user_id,
      isIncome: e.transaction_type === 'income',
      expenseDate: e.occurred_at,
    }));
  }

  static async createExpense(userId, expenseData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const expId = ensureUuid(expenseData.id);
    const isInc = !!(expenseData.is_income ?? expenseData.isIncome ?? (expenseData.transaction_type === 'income'));

    const newExpense = {
      id: expId,
      user_id: uid,
      title: expenseData.title || 'Expense',
      amount: Number(expenseData.amount) || 0.00,
      category: expenseData.category || 'General',
      transaction_type: isInc ? 'income' : 'expense',
      payment_method: expenseData.payment_method || expenseData.paymentMethod || 'UPI',
      occurred_at: expenseData.expense_date || expenseData.occurred_at || new Date().toISOString(),
      created_at: new Date().toISOString(),
    };

    const created = await dbQuery('expenses', { method: 'POST', body: newExpense, single: true });
    return { ...created, userId: uid, isIncome: isInc };
  }

  static async updateExpense(userId, expenseId, updates) {
    if (!userId || !expenseId) return null;
    const uid = ensureUuid(userId);
    const eid = ensureUuid(expenseId);
    const isInc = !!(updates.is_income ?? updates.isIncome ?? (updates.transaction_type === 'income'));

    const payload = {};
    if (updates.title) payload.title = updates.title;
    if (updates.amount !== undefined) payload.amount = Number(updates.amount);
    if (updates.category) payload.category = updates.category;
    if (updates.isIncome !== undefined || updates.is_income !== undefined || updates.transaction_type) {
      payload.transaction_type = isInc ? 'income' : 'expense';
    }
    if (updates.paymentMethod || updates.payment_method) {
      payload.payment_method = updates.paymentMethod || updates.payment_method;
    }
    if (updates.date || updates.occurred_at || updates.expense_date) {
      payload.occurred_at = updates.date || updates.occurred_at || updates.expense_date;
    }

    const updated = await dbQuery('expenses', { method: 'PATCH', match: { id: eid, user_id: uid }, body: payload, single: true });
    return updated ? { ...updated, userId: uid, isIncome: isInc } : null;
  }

  static async deleteExpense(userId, expenseId) {
    if (!userId || !expenseId) return false;
    const uid = ensureUuid(userId);
    const eid = ensureUuid(expenseId);
    return await dbQuery('expenses', { method: 'DELETE', match: { id: eid, user_id: uid } });
  }

  static async getMonthlyBudget(userId, month = null, year = null) {
    if (!userId) return { amount: 0, month: new Date().getMonth() + 1, year: new Date().getFullYear() };
    const uid = ensureUuid(userId);
    const m = month || (new Date().getMonth() + 1);
    const y = year || new Date().getFullYear();
    const budget = await dbQuery('monthly_budgets', { method: 'GET', match: { user_id: uid, month: m, year: y }, single: true });
    return budget || { amount: 0, month: m, year: y };
  }

  static async setMonthlyBudget(userId, amount, month = null, year = null) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const m = month || (new Date().getMonth() + 1);
    const y = year || new Date().getFullYear();

    const payload = {
      id: ensureUuid(),
      user_id: uid,
      amount: Number(amount) || 0.00,
      month: m,
      year: y,
      created_at: new Date().toISOString(),
    };

    return await dbQuery('monthly_budgets', { method: 'POST', body: payload, single: true });
  }

  // ---------------------------------------------------------------------------
  // STUDY MODULE: SUBJECTS, UNITS & ITEMS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getSubjects(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    return await dbQuery('subjects', { method: 'GET', match: { user_id: uid } });
  }

  static async createSubject(userId, subjectData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const newSubject = {
      id: ensureUuid(subjectData.id),
      user_id: uid,
      name: subjectData.name || subjectData.subject_name || 'New Subject',
      code: subjectData.code || '',
      instructor: subjectData.instructor || '',
      color: subjectData.color_hex || subjectData.colorHex || subjectData.color || '#0D5CE5',
      credits: Number(subjectData.credits) || 3,
      created_at: new Date().toISOString(),
    };
    return await dbQuery('subjects', { method: 'POST', body: newSubject, single: true });
  }

  static async deleteSubject(userId, subjectId) {
    if (!userId || !subjectId) return false;
    const uid = ensureUuid(userId);
    const sid = ensureUuid(subjectId);
    return await dbQuery('subjects', { method: 'DELETE', match: { id: sid, user_id: uid } });
  }

  static async getStudyUnits(userId, subjectId = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (subjectId) match.subject_id = ensureUuid(subjectId);
    return await dbQuery('study_units', { method: 'GET', match });
  }

  static async createStudyUnit(userId, arg1, arg2) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const unitData = typeof arg1 === 'object' ? arg1 : (arg2 || {});
    const sid = ensureUuid(unitData.subject_id || unitData.subjectId || (typeof arg1 === 'string' ? arg1 : ''));

    const newUnit = {
      id: ensureUuid(unitData.id),
      user_id: uid,
      subject_id: sid,
      unit_number: Number(unitData.unit_number || unitData.unitNumber || unitData.order) || 1,
      title: unitData.title || unitData.unit_title || 'Unit',
      description: unitData.description || unitData.desc || '',
      status: (unitData.is_completed || unitData.isCompleted) ? 'completed' : 'pending',
      created_at: new Date().toISOString(),
    };

    return await dbQuery('study_units', { method: 'POST', body: newUnit, single: true });
  }

  static async updateStudyUnit(userId, unitId, updates) {
    if (!userId || !unitId) return null;
    const uid = ensureUuid(userId);
    const uid_unit = ensureUuid(unitId);

    const payload = {};
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.unit_number !== undefined) payload.unit_number = Number(updates.unit_number);
    if (updates.status !== undefined) payload.status = updates.status;
    if (updates.is_completed !== undefined) payload.is_completed = !!updates.is_completed;

    return await dbQuery('study_units', { method: 'PATCH', match: { id: uid_unit, user_id: uid }, body: payload, single: true });
  }

  static async deleteStudyUnit(userId, unitId) {
    if (!userId || !unitId) return false;
    const uid = ensureUuid(userId);
    const uid_unit = ensureUuid(unitId);
    await dbQuery('study_topics', { method: 'DELETE', match: { unit_id: uid_unit, user_id: uid } });
    return await dbQuery('study_units', { method: 'DELETE', match: { id: uid_unit, user_id: uid } });
  }

  // STUDY TOPICS (TOPICS INSIDE UNITS)
  static async getStudyTopics(userId, unitId = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (unitId) match.unit_id = ensureUuid(unitId);
    return await dbQuery('study_topics', { method: 'GET', match });
  }

  static async createStudyTopic(userId, topicData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const newTopic = {
      id: ensureUuid(topicData.id),
      user_id: uid,
      unit_id: ensureUuid(topicData.unit_id || topicData.unitId),
      subject_id: topicData.subject_id || topicData.subjectId ? ensureUuid(topicData.subject_id || topicData.subjectId) : null,
      title: topicData.title || 'Topic',
      description: topicData.description || '',
      is_completed: !!(topicData.is_completed || topicData.isCompleted),
      created_at: new Date().toISOString(),
    };

    return await dbQuery('study_topics', { method: 'POST', body: newTopic, single: true });
  }

  static async toggleStudyTopic(userId, topicId) {
    if (!userId || !topicId) return null;
    const uid = ensureUuid(userId);
    const tid = ensureUuid(topicId);
    const existing = await dbQuery('study_topics', { method: 'GET', match: { id: tid, user_id: uid }, single: true });
    if (!existing) return null;
    const isCompleted = !existing.is_completed;
    return await dbQuery('study_topics', { method: 'PATCH', match: { id: tid, user_id: uid }, body: { is_completed: isCompleted }, single: true });
  }

  static async deleteStudyTopic(userId, topicId) {
    if (!userId || !topicId) return false;
    const uid = ensureUuid(userId);
    const tid = ensureUuid(topicId);
    return await dbQuery('study_topics', { method: 'DELETE', match: { id: tid, user_id: uid } });
  }

  static async getStudyItems(userId, subjectId = null, unitId = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (subjectId) match.subject_id = ensureUuid(subjectId);
    if (unitId) match.unit_id = ensureUuid(unitId);
    return await dbQuery('study_items', { method: 'GET', match });
  }

  static async createStudyItem(userId, arg1, arg2) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const itemData = typeof arg1 === 'object' ? arg1 : (arg2 || {});
    const sid = ensureUuid(itemData.subject_id || itemData.subjectId || (typeof arg1 === 'string' ? arg1 : ''));

    const newItem = {
      id: ensureUuid(itemData.id),
      user_id: uid,
      subject_id: sid,
      unit_id: itemData.unit_id || itemData.unitId ? ensureUuid(itemData.unit_id || itemData.unitId) : null,
      title: itemData.title || 'Study Task',
      type: itemData.type || 'TASK',
      status: (itemData.is_completed || itemData.isCompleted) ? 'completed' : 'pending',
      created_at: new Date().toISOString(),
    };

    return await dbQuery('study_items', { method: 'POST', body: newItem, single: true });
  }

  // ---------------------------------------------------------------------------
  // GOALS & MILESTONES (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getGoals(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    return await dbQuery('goals', { method: 'GET', match: { user_id: uid } });
  }

  static async createGoal(userId, goalData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const rawTier = (goalData.tier || goalData.timeframe || 'short').toString().toLowerCase();
    let normalizedTier = 'short';
    if (rawTier.includes('med')) normalizedTier = 'medium';
    else if (rawTier.includes('long') || rawTier.includes('career')) normalizedTier = 'long';

    const newGoal = {
      id: ensureUuid(goalData.id),
      user_id: uid,
      title: goalData.title || 'New Goal',
      description: goalData.description || goalData.aligned_purpose || null,
      tier: normalizedTier,
      category: goalData.category || 'General',
      aligned_purpose: goalData.aligned_purpose || goalData.description || null,
      target_date: goalData.target_date || goalData.targetDate || null,
      is_completed: !!(goalData.is_completed || goalData.isCompleted),
      created_at: new Date().toISOString(),
    };

    return await dbQuery('goals', { method: 'POST', body: newGoal, single: true });
  }

  static async updateGoal(userId, goalId, updates) {
    if (!userId || !goalId) return null;
    const uid = ensureUuid(userId);
    const gid = ensureUuid(goalId);

    const payload = {};
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.tier !== undefined) payload.tier = updates.tier;
    if (updates.category !== undefined) payload.category = updates.category;
    if (updates.aligned_purpose !== undefined) payload.aligned_purpose = updates.aligned_purpose;
    if (updates.target_date || updates.targetDate) payload.target_date = updates.target_date || updates.targetDate;
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      payload.is_completed = !!(updates.is_completed ?? updates.isCompleted);
    }

    return await dbQuery('goals', { method: 'PATCH', match: { id: gid, user_id: uid }, body: payload, single: true });
  }

  static async deleteGoal(userId, goalId) {
    if (!userId || !goalId) return false;
    const uid = ensureUuid(userId);
    const gid = ensureUuid(goalId);
    await dbQuery('milestones', { method: 'DELETE', match: { goal_id: gid, user_id: uid } });
    return await dbQuery('goals', { method: 'DELETE', match: { id: gid, user_id: uid } });
  }

  static async getMilestones(userId, goalId = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (goalId) match.goal_id = ensureUuid(goalId);
    return await dbQuery('milestones', { method: 'GET', match });
  }

  static async createMilestone(userId, goalId, milestoneData) {
    if (!userId || !goalId) throw new Error('userId and goalId are required');
    const uid = ensureUuid(userId);
    const gid = ensureUuid(goalId);

    const newMilestone = {
      id: ensureUuid(milestoneData.id),
      user_id: uid,
      goal_id: gid,
      title: milestoneData.title || milestoneData.milestone_title || 'New Milestone',
      description: milestoneData.description || null,
      target_date: milestoneData.target_date || milestoneData.targetDate || null,
      is_completed: !!(milestoneData.is_completed || milestoneData.isCompleted),
      created_at: new Date().toISOString(),
    };

    return await dbQuery('milestones', { method: 'POST', body: newMilestone, single: true });
  }

  // ---------------------------------------------------------------------------
  // CALENDAR EVENTS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getCalendarEvents(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    return await dbQuery('calendar_events', { method: 'GET', match: { user_id: uid } });
  }

  static async createCalendarEvent(userId, eventData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const d = eventData.event_date || eventData.date || new Date().toISOString().split('T')[0];
    let startTime = eventData.start_time?.includes('T') ? eventData.start_time.split('T')[1].substring(0, 8) : (eventData.start_time || '10:00:00');
    let endTime = eventData.end_time?.includes('T') ? eventData.end_time.split('T')[1].substring(0, 8) : (eventData.end_time || '11:00:00');
    if (startTime.length === 5) startTime += ':00';
    if (endTime.length === 5) endTime += ':00';

    const newEvent = {
      id: ensureUuid(eventData.id),
      user_id: uid,
      title: eventData.title || 'New Event',
      description: eventData.description || null,
      event_date: d,
      start_time: startTime,
      end_time: endTime,
      category: eventData.category || eventData.event_type || 'General',
      location: eventData.location || 'Workspace A',
      is_all_day: !!(eventData.is_all_day ?? eventData.isAllDay),
      created_at: new Date().toISOString(),
    };

    return await dbQuery('calendar_events', { method: 'POST', body: newEvent, single: true });
  }

  static async deleteCalendarEvent(userId, eventId) {
    if (!userId || !eventId) return false;
    const uid = ensureUuid(userId);
    const eid = ensureUuid(eventId);
    return await dbQuery('calendar_events', { method: 'DELETE', match: { id: eid, user_id: uid } });
  }

  // ---------------------------------------------------------------------------
  // JOURNAL ENTRIES (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getJournalEntries(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    return await dbQuery('journal_entries', { method: 'GET', match: { user_id: uid } });
  }

  static async createJournalEntry(userId, entryData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const newEntry = {
      id: ensureUuid(entryData.id),
      user_id: uid,
      title: entryData.title || 'Journal Entry',
      content: entryData.content || entryData.content_ciphertext || '',
      content_ciphertext: entryData.content_ciphertext || entryData.content || '',
      mood: entryData.mood || 'neutral',
      entry_date: entryData.entry_date || entryData.date || new Date().toISOString().split('T')[0],
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    return await dbQuery('journal_entries', { method: 'POST', body: newEntry, single: true });
  }

  static async deleteJournalEntry(userId, entryId) {
    if (!userId || !entryId) return false;
    const uid = ensureUuid(userId);
    const jid = ensureUuid(entryId);
    return await dbQuery('journal_entries', { method: 'DELETE', match: { id: jid, user_id: uid } });
  }
}

module.exports = {
  DatabaseManager,
  hashPassword,
  verifyPassword,
  ensureUuid,
};
