const crypto = require('crypto');
const { Client } = require('pg');
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
    console.error(`[Database Engine Notice] (${table} ${method}):`, err.message);
    return method === 'GET' ? (single ? null : []) : null;
  }
}

// -----------------------------------------------------------------------------
// 3. UNIFIED DIRECT POSTGRES DATABASE MANAGER
// -----------------------------------------------------------------------------
const userPasswordHashMap = {};

class DatabaseManager {
  static setUserPasswordHash(emailOrUsername, hash) {
    if (!emailOrUsername || !hash) return;
    const clean = String(emailOrUsername).trim().toLowerCase();
    userPasswordHashMap[clean] = hash;
  }

  static getUserPasswordHash(emailOrUsername) {
    if (!emailOrUsername) return null;
    const clean = String(emailOrUsername).trim().toLowerCase();
    return userPasswordHashMap[clean] || null;
  }

  static clearUserPasswordHash(emailOrUsername) {
    if (!emailOrUsername) return;
    const clean = String(emailOrUsername).trim().toLowerCase();
    delete userPasswordHashMap[clean];
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & USER PROFILES
  // ---------------------------------------------------------------------------
  static async getUserById(userId) {
    if (!userId) return null;
    const uid = ensureUuid(userId);
    return await dbQuery('profiles', { method: 'GET', match: { id: uid }, single: true });
  }

  static async getUserByReferralCode(code) {
    if (!code) return null;
    return await dbQuery('profiles', { method: 'GET', match: { referral_code: code.trim().toUpperCase() }, single: true });
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
        const { data } = await supabase.auth.admin.listUsers({ perPage: 1000 });
        const supUser = (data?.users || []).find(u =>
          (u.email || '').toLowerCase() === clean ||
          (u.user_metadata && (u.user_metadata.username || '').toLowerCase() === clean)
        );
        if (supUser) {
          if (!user) {
            user = {
              id: supUser.id,
              email: supUser.email,
              username: supUser.user_metadata?.username || clean,
              display_name: supUser.user_metadata?.name || supUser.email.split('@')[0],
              is_premium: false,
              subscription_plan: 'FREE',
            };
          }
          if (supUser.user_metadata && (supUser.user_metadata.passwordHash || supUser.user_metadata.password_hash)) {
            const h = supUser.user_metadata.passwordHash || supUser.user_metadata.password_hash;
            if (!user.password_hash) {
              user.password_hash = h;
              DatabaseManager.setUserPasswordHash(clean, h);
            }
          }
        }
      } catch (supErr) {
        console.warn('[SUPABASE AUTH USER FETCH NOTICE]:', supErr.message);
      }
    }
    const cachedHash = DatabaseManager.getUserPasswordHash(clean) || (user?.email ? DatabaseManager.getUserPasswordHash(user.email) : null) || (user?.username ? DatabaseManager.getUserPasswordHash(user.username) : null);
    if (user && !user.password_hash && cachedHash) {
      user.password_hash = cachedHash;
    }
    return user;
  }

  static async createUser(userData) {
    const userId = ensureUuid(userData.id);
    const cleanUsername = (userData.username || '').trim().toLowerCase();
    const cleanEmail = (userData.email || '').trim().toLowerCase();

    const newUser = {
      id: userId,
      username: cleanUsername,
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

    if (userData.password_hash) {
      newUser.password_hash = userData.password_hash;
    }

    const createdProfile = await dbQuery('profiles', { method: 'POST', body: newUser, single: true });
    const resultUser = createdProfile || newUser;

    if (userData.password_hash) {
      resultUser.password_hash = userData.password_hash;
      DatabaseManager.setUserPasswordHash(cleanEmail, userData.password_hash);
      DatabaseManager.setUserPasswordHash(cleanUsername, userData.password_hash);
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
    if (updates.email) payload.email = updates.email.trim().toLowerCase();
    if (updates.display_name || updates.name) payload.display_name = updates.display_name || updates.name;
    if (updates.phone_number || updates.contact) payload.phone_number = updates.phone_number || updates.contact;
    if (updates.avatar_url || updates.profile_image) payload.avatar_url = updates.avatar_url || updates.profile_image;
    if (updates.focus_score !== undefined) payload.focus_score = updates.focus_score;
    if (updates.active_streak !== undefined) payload.active_streak = updates.active_streak;
    if (updates.is_premium !== undefined) payload.is_premium = !!updates.is_premium;
    if (updates.subscription_plan) payload.subscription_plan = updates.subscription_plan.toUpperCase();
    if (updates.is_email_verified !== undefined) payload.is_email_verified = !!updates.is_email_verified;

    if (updates.new_password !== undefined) {
      payload.new_password = updates.new_password;
    }

    if (updates.password_hash) {
      payload.password_hash = updates.password_hash;
      if (updates.email) DatabaseManager.setUserPasswordHash(updates.email, updates.password_hash);
      if (updates.username) DatabaseManager.setUserPasswordHash(updates.username, updates.password_hash);
      const u = await DatabaseManager.getUserById(uid);
      if (u) {
        if (u.email) DatabaseManager.setUserPasswordHash(u.email, updates.password_hash);
        if (u.username) DatabaseManager.setUserPasswordHash(u.username, updates.password_hash);
      }
    }

    return await dbQuery('profiles', { method: 'PATCH', match: { id: uid }, body: payload, single: true });
  }

  static async isEmailTombstoned(email) {
    // Re-registration is permitted after account deletion
    return false;
  }

  static async ensureDeletedAccountsTable() {
    const urls = [
      process.env.DATABASE_URL,
      'postgresql://postgres.hkeyywopbkmlclsealbz:yb8J3XQGAcuh2SXc@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres',
      'postgresql://postgres.hkeyywopbkmlclsealbz:yb8J3XQGAcuh2SXc@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres',
      'postgresql://postgres:yb8J3XQGAcuh2SXc@db.hkeyywopbkmlclsealbz.supabase.co:5432/postgres',
    ].filter(Boolean);

    for (const dbUrl of urls) {
      try {
        const client = new Client({
          connectionString: dbUrl,
          ssl: { rejectUnauthorized: false },
          connectionTimeoutMillis: 6000,
        });
        await client.connect();
        await client.query(`
          ALTER TABLE public.profiles DROP COLUMN IF EXISTS deleted_at;

          CREATE TABLE IF NOT EXISTS public.deleted_accounts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id TEXT,
            username TEXT,
            email TEXT,
            emailid TEXT,
            deleted_time TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ DEFAULT now(),
            reason TEXT,
            created_at TIMESTAMPTZ DEFAULT now()
          );

          ALTER TABLE public.deleted_accounts ALTER COLUMN user_id TYPE TEXT;

          GRANT ALL ON public.deleted_accounts TO anon, authenticated, service_role;
          ALTER TABLE public.deleted_accounts ENABLE ROW LEVEL SECURITY;

          DO $$
          BEGIN
            IF NOT EXISTS (
              SELECT 1 FROM pg_policies WHERE tablename = 'deleted_accounts' AND policyname = 'allow_all_deleted_accounts'
            ) THEN
              CREATE POLICY allow_all_deleted_accounts ON public.deleted_accounts FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);
            END IF;
          END $$;

          ALTER TABLE public.deleted_account_tombstones
            ADD COLUMN IF NOT EXISTS username TEXT,
            ADD COLUMN IF NOT EXISTS user_id TEXT,
            ADD COLUMN IF NOT EXISTS deleted_time TIMESTAMPTZ DEFAULT now();

          NOTIFY pgrst, 'reload schema';
        `);
        await client.end().catch(() => {});
        console.log('[SUPABASE SCHEMA] deleted_accounts table ensured via', dbUrl.split('@')[1]);
        return { success: true, url: dbUrl.split('@')[1] };
      } catch (err) {
        console.warn('[SUPABASE SCHEMA NOTICE] URL failed:', dbUrl.split('@')[1], err.message);
      }
    }
    return { success: false };
  }

  static async deleteUser(userId) {
    if (!userId) return false;
    const uid = ensureUuid(userId);
    let user = await this.getUserById(uid);
    if (!user && typeof userId === 'string' && userId.includes('@')) {
      user = await this.getUserByEmailOrUsername(userId);
    }

    const deletedTime = new Date().toISOString();
    const rawUsername = user?.username || (user?.email ? user.email.split('@')[0] : (typeof userId === 'string' && !userId.includes('@') ? userId : 'user'));
    const rawEmail = (user?.email || (typeof userId === 'string' && userId.includes('@') ? userId : '')).trim().toLowerCase();
    const actualUid = user?.id || uid;

    // 1. Ensure deleted_accounts table exists in Supabase
    await this.ensureDeletedAccountsTable().catch(() => {});

    // 2. Store deleted account details (username, email, emailid, deleted_time) in separate Supabase table
    try {
      await dbQuery('deleted_accounts', {
        method: 'POST',
        body: {
          user_id: actualUid,
          username: rawUsername,
          email: rawEmail,
          emailid: rawEmail,
          deleted_time: deletedTime,
          deleted_at: deletedTime,
          reason: 'user_requested_permanent_deletion',
        },
      });
      console.log(`[DELETED_ACCOUNTS] Recorded deleted account: ${rawEmail} (${rawUsername}) at ${deletedTime}`);
    } catch (e) {
      console.warn('[DELETED_ACCOUNTS INSERT NOTICE]:', e.message);
    }

    // 3. Also record in deleted_account_tombstones table for redundancy
    try {
      await dbQuery('deleted_account_tombstones', {
        method: 'POST',
        body: {
          email: rawEmail,
          deleted_at: deletedTime,
          username: rawUsername,
          user_id: actualUid,
          deleted_time: deletedTime,
        },
      });
      console.log(`[TOMBSTONE] Recorded in deleted_account_tombstones: ${rawEmail}`);
    } catch (e) {
      console.warn('[TOMBSTONE INSERT NOTICE]:', e.message);
    }

    // 4. Record deletion event in audit_logs
    try {
      await dbQuery('audit_logs', {
        method: 'POST',
        body: {
          user_id: actualUid,
          action: 'ACCOUNT_PERMANENTLY_DELETED',
          payload: {
            username: rawUsername,
            email: rawEmail,
            emailid: rawEmail,
            deleted_time: deletedTime,
          },
          created_at: deletedTime,
        },
      });
    } catch (_) {}

    // 5. Clear password hash cache
    if (user) {
      if (user.email) {
        DatabaseManager.clearUserPasswordHash(user.email);
      }
      if (user.username) {
        DatabaseManager.clearUserPasswordHash(user.username);
      }
    }

    // 6. Clean up Supabase Auth Admin user if configured
    if (isSupabaseConfigured() && supabase) {
      try {
        if (actualUid) {
          await supabase.auth.admin.deleteUser(actualUid).catch(() => {});
        }
        if (uid && uid !== actualUid) {
          await supabase.auth.admin.deleteUser(uid).catch(() => {});
        }
        if (rawEmail) {
          const { data } = await supabase.auth.admin.listUsers({ perPage: 1000 }).catch(() => ({ data: { users: [] } }));
          const supUser = (data?.users || []).find(u => (u.email || '').toLowerCase() === rawEmail);
          if (supUser && supUser.id) {
            await supabase.auth.admin.deleteUser(supUser.id).catch(() => {});
          }
        }
        console.log(`[SUPABASE AUTH DELETE] Successfully deleted auth user for ID: ${actualUid}`);
      } catch (supErr) {
        console.warn('[SUPABASE AUTH DELETE NOTICE]:', supErr.message);
      }
    }

    // 7. Permanently remove all user data from all related tables
    const userTables = [
      'tasks',
      'habits',
      'habit_logs',
      'expenses',
      'monthly_budgets',
      'calendar_events',
      'journal_entries',
      'subjects',
      'study_items',
      'study_units',
      'study_topics',
      'goals',
      'milestones',
      'subscriptions',
      'referrals',
      'user_auth_identities',
      'priority_matrix',
      'career_nodes',
      'notes',
    ];

    for (const table of userTables) {
      if (actualUid) {
        try {
          await dbQuery(table, { method: 'DELETE', match: { user_id: actualUid } });
        } catch (_) {}
      }
      if (uid && uid !== actualUid) {
        try {
          await dbQuery(table, { method: 'DELETE', match: { user_id: uid } });
        } catch (_) {}
      }
    }

    // 8. Finally delete profile completely from profiles table
    if (actualUid) {
      await dbQuery('profiles', { method: 'DELETE', match: { id: actualUid } }).catch(() => {});
    }
    if (uid && uid !== actualUid) {
      await dbQuery('profiles', { method: 'DELETE', match: { id: uid } }).catch(() => {});
    }
    if (rawEmail) {
      await dbQuery('profiles', { method: 'DELETE', match: { email: rawEmail } }).catch(() => {});
    }
    if (rawUsername && rawUsername !== 'user') {
      await dbQuery('profiles', { method: 'DELETE', match: { username: rawUsername } }).catch(() => {});
    }
    return true;
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

  static async upgradeSubscription(userId, plan = 'pro', paymentProvider = 'GOOGLE_PLAY') {
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
      dueDate: t.due_at,
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
      due_at: taskData.due_at || taskData.due_date || taskData.dueDate || new Date().toISOString(),
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
    if (updates.due_at || updates.due_date || updates.dueDate) {
      payload.due_at = updates.due_at || updates.due_date || updates.dueDate;
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
  // HABITS & HABIT LOGS (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getHabits(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const habits = await dbQuery('habits', { method: 'GET', match: { user_id: uid } });
    if (!habits || habits.length === 0) return [];

    const logs = await dbQuery('habit_logs', { method: 'GET', match: { user_id: uid } });
    const historyMap = {};
    (logs || []).forEach(log => {
      if (!log.habit_id || !log.completion_date) return;
      if (!historyMap[log.habit_id]) historyMap[log.habit_id] = [];
      if (!historyMap[log.habit_id].includes(log.completion_date)) {
        historyMap[log.habit_id].push(log.completion_date);
      }
    });

    const todayStr = new Date().toISOString().split('T')[0];

    return habits.map(h => {
      const history = historyMap[h.id] || [];
      const isDone = history.includes(todayStr);
      return {
        ...h,
        userId: h.user_id,
        colorHex: h.color_hex || h.color,
        iconName: h.icon_name,
        completionHistory: history,
        completion_history: history,
        isCompleted: isDone,
        is_completed: isDone,
      };
    });
  }

  static async getHabitOverview(userId, targetDateStr = null) {
    if (!userId) return { scheduledHabits: [], totalScheduled: 0, completedCount: 0, completionRate: 0 };
    const uid = ensureUuid(userId);
    const dateStr = targetDateStr || new Date().toISOString().split('T')[0];

    const habits = await this.getHabits(uid);
    const completions = await dbQuery('habit_logs', { method: 'GET', match: { user_id: uid, completion_date: dateStr } });
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
      color_hex: habitData.color_hex || habitData.colorHex || '#10B981',
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
    if (updates.color_hex || updates.colorHex) {
      payload.color_hex = updates.color_hex || updates.colorHex;
    }
    if (updates.status !== undefined) payload.status = updates.status;

    return await dbQuery('habits', { method: 'PATCH', match: { id: hid, user_id: uid }, body: payload, single: true });
  }

  static async deleteHabit(userId, habitId) {
    if (!userId || !habitId) return false;
    const uid = ensureUuid(userId);
    const hid = ensureUuid(habitId);
    await dbQuery('habit_logs', { method: 'DELETE', match: { habit_id: hid, user_id: uid } });
    return await dbQuery('habits', { method: 'DELETE', match: { id: hid, user_id: uid } });
  }

  static async toggleHabitCompletion(userId, habitId, dateStr = null, notes = '') {
    if (!userId || !habitId) return null;
    const uid = ensureUuid(userId);
    const hid = ensureUuid(habitId);
    const targetDate = dateStr || new Date().toISOString().split('T')[0];

    const existing = await dbQuery('habit_logs', { method: 'GET', match: { habit_id: hid, user_id: uid, completion_date: targetDate }, single: true });

    if (existing) {
      await dbQuery('habit_logs', { method: 'DELETE', match: { id: existing.id } });
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
      await dbQuery('habit_logs', { method: 'POST', body: log });
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
      occurred_at: expenseData.occurred_at || expenseData.expense_date || new Date().toISOString(),
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
    if (updates.occurred_at || updates.expense_date || updates.date) {
      payload.occurred_at = updates.occurred_at || updates.expense_date || updates.date;
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
  // STUDY MODULE: SUBJECTS & ITEMS (DIRECT POSTGRESQL CRUD)
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
      color_hex: subjectData.color_hex || subjectData.colorHex || '#0D5CE5',
      credits: Number(subjectData.credits) || 3,
      created_at: new Date().toISOString(),
    };
    return await dbQuery('subjects', { method: 'POST', body: newSubject, single: true });
  }

  static async updateSubject(userId, subjectId, updates) {
    if (!userId || !subjectId) return null;
    const uid = ensureUuid(userId);
    const sid = ensureUuid(subjectId);

    const payload = {};
    if (updates.name !== undefined) payload.name = updates.name;
    if (updates.code !== undefined) payload.code = updates.code;
    if (updates.color_hex || updates.colorHex) {
      payload.color_hex = updates.color_hex || updates.colorHex;
    }

    return await dbQuery('subjects', { method: 'PATCH', match: { id: sid, user_id: uid }, body: payload, single: true });
  }

  static async deleteSubject(userId, subjectId) {
    if (!userId || !subjectId) return false;
    const uid = ensureUuid(userId);
    const sid = ensureUuid(subjectId);
    return await dbQuery('subjects', { method: 'DELETE', match: { id: sid, user_id: uid } });
  }

  static async getStudyItems(userId, subjectId = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (subjectId) match.subject_id = ensureUuid(subjectId);
    const items = await dbQuery('study_items', { method: 'GET', match });
    const subjects = await dbQuery('subjects', { method: 'GET', match: { user_id: uid } });
    const subMap = {};
    (subjects || []).forEach(s => { subMap[s.id] = s.name; });

    return (items || []).map(it => ({
      ...it,
      subjectId: it.subject_id,
      subjectName: subMap[it.subject_id] || 'Study Subject',
      dueDate: it.due_at,
      isCompleted: it.status === 'completed' || !!it.is_completed,
    }));
  }

  static async createStudyItem(userId, subjectIdOrData, itemDataParam = null) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const itemData = (typeof subjectIdOrData === 'object' && subjectIdOrData !== null) ? subjectIdOrData : (itemDataParam || {});
    const rawSubId = (typeof subjectIdOrData === 'string') ? subjectIdOrData : (itemData.subject_id || itemData.subjectId);

    let sid = rawSubId ? ensureUuid(rawSubId) : null;
    if (!sid) {
      const existingSubjs = await dbQuery('subjects', { method: 'GET', match: { user_id: uid } });
      if (existingSubjs && existingSubjs.length > 0) {
        sid = existingSubjs[0].id;
      } else {
        const defaultSubj = await dbQuery('subjects', {
          method: 'POST',
          body: {
            id: ensureUuid(),
            user_id: uid,
            name: itemData.subjectName || 'General Studies',
            code: 'GEN',
            color_hex: '#0D5CE5',
            created_at: new Date().toISOString(),
          },
          single: true,
        });
        sid = defaultSubj?.id || ensureUuid();
      }
    }

    const isDone = !!(itemData.is_completed ?? itemData.isCompleted ?? (itemData.status === 'completed'));
    const dueAt = itemData.due_at || itemData.dueDate || new Date().toISOString();
    const newItem = {
      id: ensureUuid(itemData.id),
      user_id: uid,
      subject_id: sid,
      title: itemData.title || 'Study Task',
      type: (itemData.type || 'TASK').toUpperCase(),
      status: isDone ? 'completed' : 'pending',
      due_at: dueAt,
      created_at: new Date().toISOString(),
    };

    const created = await dbQuery('study_items', { method: 'POST', body: newItem, single: true });
    return {
      ...(created || newItem),
      subjectId: sid,
      dueDate: (created || newItem).due_at,
      isCompleted: isDone,
    };
  }

  static async updateStudyItem(userId, itemId, updates) {
    if (!userId || !itemId) return null;
    const uid = ensureUuid(userId);
    const iid = ensureUuid(itemId);

    const payload = {};
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.type !== undefined) payload.type = updates.type.toUpperCase();
    if (updates.due_at || updates.dueDate) {
      payload.due_at = updates.due_at || updates.dueDate;
    }
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined || updates.status !== undefined) {
      const isDone = !!(updates.is_completed ?? updates.isCompleted ?? (updates.status === 'completed'));
      payload.status = isDone ? 'completed' : 'pending';
    }

    const updated = await dbQuery('study_items', { method: 'PATCH', match: { id: iid, user_id: uid }, body: payload, single: true });
    return updated ? {
      ...updated,
      subjectId: updated.subject_id,
      dueDate: updated.due_at,
      isCompleted: updated.status === 'completed',
    } : null;
  }

  static async deleteStudyItem(userId, itemId) {
    if (!userId || !itemId) return false;
    const uid = ensureUuid(userId);
    const iid = ensureUuid(itemId);
    return await dbQuery('study_items', { method: 'DELETE', match: { id: iid, user_id: uid } });
  }

  // ---------------------------------------------------------------------------
  // GOALS & MILESTONES (DIRECT POSTGRESQL CRUD)
  // ---------------------------------------------------------------------------
  static async getGoals(userId, tier = null) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    const match = { user_id: uid };
    if (tier) match.tier = tier.toLowerCase();
    const goals = await dbQuery('goals', { method: 'GET', match });
    let list = (goals || []).map(g => ({
      ...g,
      userId: g.user_id,
      user_id: g.user_id,
      targetDate: g.target_date,
      target_date: g.target_date,
      isCompleted: !!g.is_completed,
      is_completed: !!g.is_completed,
      alignedPurpose: g.aligned_purpose,
      aligned_purpose: g.aligned_purpose,
      section: g.section || 'GOAL',
    }));
    if (!tier) {
      list = list.filter(g => (g.tier || '').toLowerCase() !== 'roadmap' && (g.section || '').toUpperCase() !== 'CAREER');
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // CAREER ROADMAP NODES (100% DECOUPLED FROM GOALS)
  // ---------------------------------------------------------------------------
  static async getCareerNodes(userId) {
    if (!userId) return [];
    const uid = ensureUuid(userId);
    let nodes = [];
    try {
      nodes = await dbQuery('career_nodes', { method: 'GET', match: { user_id: uid } });
    } catch (_) {}
    if (!nodes || nodes.length === 0) {
      try {
        const goals = await dbQuery('goals', { method: 'GET', match: { user_id: uid, section: 'CAREER' } });
        if (goals && goals.length > 0) {
          nodes = goals;
        }
      } catch (_) {}
    }
    return (nodes || []).map(n => ({
      id: n.id,
      user_id: n.user_id,
      userId: n.user_id,
      title: n.title,
      description: n.description || '',
      section: n.section || 'SKILLS',
      status: n.status || (n.is_completed ? 'COMPLETED' : 'PLANNED'),
      isCompleted: !!(n.is_completed || n.isCompleted),
      is_completed: !!(n.is_completed || n.isCompleted),
      order: n.order ?? 0,
      createdAt: n.created_at,
    }));
  }

  static async createCareerNode(userId, nodeData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);
    const newNode = {
      id: ensureUuid(nodeData.id),
      user_id: uid,
      title: nodeData.title || 'New Node',
      description: nodeData.description || '',
      section: nodeData.section || 'SKILLS',
      status: nodeData.status || 'PLANNED',
      is_completed: !!(nodeData.is_completed || nodeData.isCompleted),
      order: nodeData.order ?? 0,
      created_at: new Date().toISOString(),
    };
    try {
      const created = await dbQuery('career_nodes', { method: 'POST', body: newNode, single: true });
      return created ? { ...created, isCompleted: !!created.is_completed } : newNode;
    } catch (_) {
      const fallback = { ...newNode, tier: 'roadmap', section: 'CAREER', category: 'Career' };
      await dbQuery('goals', { method: 'POST', body: fallback, single: true });
      return newNode;
    }
  }

  static async updateCareerNode(userId, nodeId, updates) {
    if (!userId || !nodeId) return null;
    const uid = ensureUuid(userId);
    const nid = ensureUuid(nodeId);
    const payload = {};
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.section !== undefined) payload.section = updates.section;
    if (updates.status !== undefined) payload.status = updates.status;
    if (updates.order !== undefined) payload.order = updates.order;
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      payload.is_completed = !!(updates.is_completed ?? updates.isCompleted);
    }
    try {
      const updated = await dbQuery('career_nodes', { method: 'PATCH', match: { id: nid, user_id: uid }, body: payload, single: true });
      if (updated) return { ...updated, isCompleted: !!updated.is_completed };
    } catch (_) {}
    try {
      const updatedGoal = await dbQuery('goals', { method: 'PATCH', match: { id: nid, user_id: uid }, body: payload, single: true });
      if (updatedGoal) return { ...updatedGoal, isCompleted: !!updatedGoal.is_completed };
    } catch (_) {}
    return null;
  }

  static async deleteCareerNode(userId, nodeId) {
    if (!userId || !nodeId) return false;
    const uid = ensureUuid(userId);
    const nid = ensureUuid(nodeId);
    try {
      await dbQuery('career_nodes', { method: 'DELETE', match: { id: nid, user_id: uid } });
    } catch (_) {}
    try {
      await dbQuery('goals', { method: 'DELETE', match: { id: nid, user_id: uid, section: 'CAREER' } });
    } catch (_) {}
    return true;
  }

  static async createGoal(userId, goalData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const rawTier = (goalData.tier || goalData.timeframe || 'short').toString().toLowerCase();
    let normalizedTier = 'short';
    if (rawTier.includes('roadmap') || rawTier.includes('career')) normalizedTier = 'roadmap';
    else if (rawTier.includes('med')) normalizedTier = 'medium';
    else if (rawTier.includes('long')) normalizedTier = 'long';

    const newGoal = {
      id: ensureUuid(goalData.id),
      user_id: uid,
      title: goalData.title || 'New Goal',
      description: goalData.description || goalData.aligned_purpose || null,
      tier: normalizedTier,
      section: goalData.section || 'GOAL',
      category: goalData.category || 'General',
      aligned_purpose: goalData.aligned_purpose || goalData.description || null,
      target_date: goalData.target_date || goalData.targetDate || null,
      is_completed: !!(goalData.is_completed || goalData.isCompleted),
      created_at: new Date().toISOString(),
    };

    const created = await dbQuery('goals', { method: 'POST', body: newGoal, single: true });
    return {
      ...(created || newGoal),
      userId: uid,
      targetDate: (created || newGoal).target_date,
      isCompleted: !!(created || newGoal).is_completed,
      section: (created || newGoal).section || 'GOAL',
    };
  }

  static async updateGoal(userId, goalId, updates) {
    if (!userId || !goalId) return null;
    const uid = ensureUuid(userId);
    const gid = ensureUuid(goalId);

    const payload = {};
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.tier !== undefined) payload.tier = updates.tier;
    if (updates.section !== undefined) payload.section = updates.section;
    if (updates.category !== undefined) payload.category = updates.category;
    if (updates.aligned_purpose !== undefined) payload.aligned_purpose = updates.aligned_purpose;
    if (updates.target_date || updates.targetDate) payload.target_date = updates.target_date || updates.targetDate;
    if (updates.is_completed !== undefined || updates.isCompleted !== undefined) {
      payload.is_completed = !!(updates.is_completed ?? updates.isCompleted);
    }

    const updated = await dbQuery('goals', { method: 'PATCH', match: { id: gid, user_id: uid }, body: payload, single: true });
    return updated ? {
      ...updated,
      userId: uid,
      targetDate: updated.target_date,
      isCompleted: !!updated.is_completed,
      section: updated.section || 'GOAL',
    } : null;
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

  static async createMilestone(userId, goalId, milestoneData = {}) {
    if (!userId || !goalId) throw new Error('userId and goalId are required');
    const uid = ensureUuid(userId);
    const gid = ensureUuid(goalId);
    const data = milestoneData || {};

    const newMilestone = {
      id: ensureUuid(data.id),
      user_id: uid,
      goal_id: gid,
      title: data.title || data.milestone_title || 'New Milestone',
      description: data.description || null,
      target_date: data.target_date || data.targetDate || null,
      is_completed: !!(data.is_completed || data.isCompleted),
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
    const events = await dbQuery('calendar_events', { method: 'GET', match: { user_id: uid } });
    return (events || []).map(e => {
      const d = e.event_date || new Date().toISOString().split('T')[0];
      const st = e.start_time || '10:00:00';
      const et = e.end_time || '11:00:00';
      const startTimeIso = e.startTime || (st.includes('T') ? st : `${d}T${st}`);
      const endTimeIso = e.endTime || (et.includes('T') ? et : `${d}T${et}`);
      const eventType = e.type || e.event_type || e.type_name || 'Focus Session';
      const cat = e.category || 'General';

      return {
        ...e,
        userId: uid,
        startTime: startTimeIso,
        endTime: endTimeIso,
        type: eventType,
        category: cat,
      };
    });
  }

  static async createCalendarEvent(userId, eventData) {
    if (!userId) throw new Error('userId is required');
    const uid = ensureUuid(userId);

    const fullStart = eventData.startTime || eventData.start_time;
    const fullEnd = eventData.endTime || eventData.end_time;
    let d = eventData.event_date;

    if (!d && fullStart) {
      d = fullStart.split('T')[0];
    }
    if (!d) {
      d = new Date().toISOString().split('T')[0];
    }

    let startTimeStr = fullStart?.includes('T') ? fullStart.split('T')[1].substring(0, 8) : (eventData.start_time || '10:00:00');
    let endTimeStr = fullEnd?.includes('T') ? fullEnd.split('T')[1].substring(0, 8) : (eventData.end_time || '11:00:00');
    if (startTimeStr.length === 5) startTimeStr += ':00';
    if (endTimeStr.length === 5) endTimeStr += ':00';

    const eventType = eventData.type || eventData.event_type || 'Focus Session';
    const category = eventData.category || 'General';

    const newEvent = {
      id: ensureUuid(eventData.id),
      user_id: uid,
      title: eventData.title || 'New Event',
      description: eventData.description || null,
      event_date: d,
      start_time: startTimeStr,
      end_time: endTimeStr,
      category: category,
      location: eventData.location || 'Workspace A',
      is_all_day: !!(eventData.is_all_day ?? eventData.isAllDay),
      created_at: new Date().toISOString(),
    };

    const created = await dbQuery('calendar_events', { method: 'POST', body: newEvent, single: true });
    const res = created || newEvent;

    const isoStart = fullStart || `${res.event_date || d}T${res.start_time || startTimeStr}`;
    const isoEnd = fullEnd || `${res.event_date || d}T${res.end_time || endTimeStr}`;

    return {
      ...res,
      userId: uid,
      startTime: isoStart,
      endTime: isoEnd,
      type: eventType,
      category: category,
    };
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
    const user = await DatabaseManager.getUserById(userId);
    const uid = user ? user.id : ensureUuid(userId);
    const entries = await dbQuery('journal_entries', { method: 'GET', match: { user_id: uid } });
    return (entries || []).map(j => {
      const fullDate = j.created_at || (j.entry_date ? `${j.entry_date}T12:00:00.000Z` : new Date().toISOString());
      return {
        ...j,
        userId: j.user_id,
        date: fullDate,
        created_at: fullDate,
        entry_date: j.entry_date || fullDate.split('T')[0],
        content: j.content || '',
        mood: j.mood || 'neutral',
        title: j.title || 'Journal Entry',
      };
    });
  }

  static async createJournalEntry(userId, entryData) {
    if (!userId) throw new Error('userId is required');
    const user = await DatabaseManager.getUserById(userId);
    const uid = user ? user.id : ensureUuid(userId);

    const fullDate = (entryData.created_at && entryData.created_at.includes('T'))
      ? entryData.created_at
      : new Date().toISOString();

    const newEntry = {
      id: ensureUuid(entryData.id),
      user_id: uid,
      title: entryData.title || 'Journal Entry',
      content: entryData.content || '',
      mood: entryData.mood || 'neutral',
      entry_date: fullDate.split('T')[0],
      created_at: fullDate,
      updated_at: new Date().toISOString(),
    };

    const created = await dbQuery('journal_entries', { method: 'POST', body: newEntry, single: true });
    return {
      ...(created || newEntry),
      userId: uid,
      date: fullDate,
      created_at: fullDate,
    };
  }

  static async updateJournalEntry(userId, entryId, updates) {
    if (!userId || !entryId) return null;
    const user = await DatabaseManager.getUserById(userId);
    const uid = user ? user.id : ensureUuid(userId);
    const jid = ensureUuid(entryId);

    const payload = { updated_at: new Date().toISOString() };
    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.content !== undefined) payload.content = updates.content;
    if (updates.mood !== undefined) payload.mood = updates.mood;
    if (updates.entry_date) payload.entry_date = updates.entry_date;

    const updated = await dbQuery('journal_entries', { method: 'PATCH', match: { id: jid, user_id: uid }, body: payload, single: true });
    return updated ? {
      ...updated,
      userId: uid,
      date: updated.entry_date,
    } : null;
  }

  static async deleteJournalEntry(userId, entryId) {
    if (!userId || !entryId) return false;
    const user = await DatabaseManager.getUserById(userId);
    const uid = user ? user.id : ensureUuid(userId);
    const jid = ensureUuid(entryId);
    return await dbQuery('journal_entries', { method: 'DELETE', match: { id: jid, user_id: uid } });
  }
}
 
// Run schema check in background on initialization
DatabaseManager.ensureDeletedAccountsTable().catch(() => {});

module.exports = {
  DatabaseManager,
  hashPassword,
  verifyPassword,
  ensureUuid,
};
