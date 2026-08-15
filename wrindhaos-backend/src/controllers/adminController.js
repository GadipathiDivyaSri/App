const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');

// In-Memory Admin State Store Fallback
const adminStore = {
  settings: {
    maintenance_mode: { enabled: false, message: 'WrindhaOS is undergoing scheduled maintenance.' },
    system_broadcast: { enabled: true, text: 'Welcome to WrindhaOS Student Platform!' },
    max_free_habits: { limit: 2 },
    max_free_subjects: { limit: 2 },
  },
  bans: new Map(),
};

/**
 * Executive Admin Dashboard Statistics
 */
async function getAdminDashboardStats(req, res, next) {
  try {
    const allUsers = Array.from(mockStore.users.values());
    const totalUsers = allUsers.length;
    const freeUsers = allUsers.filter((u) => u.subscription_plan === 'FREE').length;
    const premiumUsers = allUsers.filter((u) => u.subscription_plan === 'PREMIUM').length;
    const activeSubscriptions = Array.from(mockStore.subscriptions.values()).filter(
      (s) => s.status === 'ACTIVE'
    ).length;

    const estimatedMRR = activeSubscriptions * 299;

    sendSuccess(
      res,
      {
        metrics: {
          totalUsers,
          freeUsers,
          premiumUsers,
          activeSubscriptions,
          estimatedMRR: `₹${estimatedMRR.toLocaleString('en-IN')}`,
          dauToday: Math.max(1, Math.floor(totalUsers * 0.8)),
          systemUptime: '99.98%',
        },
        settings: adminStore.settings,
      },
      'Admin Dashboard statistics retrieved.'
    );
  } catch (err) {
    next(err);
  }
}

/**
 * Get Users List with Search & Filtering
 */
async function getUsersList(req, res, next) {
  try {
    let users = Array.from(mockStore.users.values());
    const { search, plan, status } = req.query;

    if (search) {
      const q = search.toLowerCase();
      users = users.filter(
        (u) =>
          (u.full_name && u.full_name.toLowerCase().includes(q)) ||
          (u.email && u.email.toLowerCase().includes(q)) ||
          (u.phone_number && u.phone_number.includes(q))
      );
    }

    if (plan) {
      users = users.filter((u) => u.subscription_plan === plan.toUpperCase());
    }

    if (status) {
      users = users.filter((u) => u.subscription_status === status.toUpperCase());
    }

    sendSuccess(res, { users, count: users.length }, 'User list retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get User Operational Metadata Breakdown (Zero Admin Access Compliant)
 */
async function getUserDetails(req, res, next) {
  try {
    const userId = req.params.id;
    const user = mockStore.users.get(userId);
    if (!user) {
      return sendError(res, 'User not found.', 'NOT_FOUND', 404);
    }

    const userTodosCount = Array.from(mockStore.todos.values()).filter((t) => t.user_id === userId).length;
    const userHabitsCount = Array.from(mockStore.habits.values()).filter((h) => h.user_id === userId).length;
    const userSubjectsCount = Array.from(mockStore.subjects.values()).filter((s) => s.user_id === userId).length;
    const userSub = Array.from(mockStore.subscriptions.values()).find((s) => s.user_id === userId);

    sendSuccess(
      res,
      {
        account: {
          id: user.id,
          email: user.email,
          phone_number: user.phone_number,
          subscription_plan: user.subscription_plan,
          subscription_status: user.subscription_status,
          created_at: user.created_at || new Date().toISOString(),
        },
        subscription: userSub || null,
        operational_metrics: {
          total_todos_count: userTodosCount,
          total_habits_count: userHabitsCount,
          total_subjects_count: userSubjectsCount,
        },
        private_data: 'NOT_ACCESSIBLE',
        isBanned: adminStore.bans.has(userId),
      },
      'User operational metadata profile retrieved.'
    );
  } catch (err) {
    next(err);
  }
}

/**
 * Super Admin Override Plan (Manual Premium Grant or Reset)
 */
async function overrideUserPlan(req, res, next) {
  try {
    const userId = req.params.id;
    const { plan, reason } = req.body; // FREE or PREMIUM

    const user = mockStore.users.get(userId);
    if (!user) {
      return sendError(res, 'User not found.', 'NOT_FOUND', 404);
    }

    const targetPlan = plan.toUpperCase() === 'PREMIUM' ? 'PREMIUM' : 'FREE';
    user.subscription_plan = targetPlan;
    user.subscription_status = 'ACTIVE';
    user.ads_enabled = targetPlan === 'FREE';
    user.updated_at = new Date().toISOString();

    mockStore.users.set(userId, user);

    await logAuditEvent(
      req.user.id,
      'ADMIN_PLAN_OVERRIDE',
      { targetUserId: userId, plan: targetPlan, reason: reason || 'Manual Admin Override' },
      req.ip
    );

    sendSuccess(res, { user }, `User plan successfully overridden to ${targetPlan}.`);
  } catch (err) {
    next(err);
  }
}

/**
 * Ban / Suspend User Account
 */
async function banUserAccount(req, res, next) {
  try {
    const userId = req.params.id;
    const { reason } = req.body;

    const user = mockStore.users.get(userId);
    if (!user) {
      return sendError(res, 'User not found.', 'NOT_FOUND', 404);
    }

    adminStore.bans.set(userId, {
      reason: reason || 'Violation of terms of service',
      bannedAt: new Date().toISOString(),
    });

    user.subscription_status = 'SUSPENDED';
    mockStore.users.set(userId, user);

    await logAuditEvent(req.user.id, 'ADMIN_USER_BAN', { targetUserId: userId, reason }, req.ip);

    sendSuccess(res, { userId, isBanned: true }, 'User account successfully suspended.');
  } catch (err) {
    next(err);
  }
}

/**
 * Unban / Restore User Account
 */
async function unbanUserAccount(req, res, next) {
  try {
    const userId = req.params.id;
    const user = mockStore.users.get(userId);
    if (!user) {
      return sendError(res, 'User not found.', 'NOT_FOUND', 404);
    }

    adminStore.bans.delete(userId);
    user.subscription_status = 'ACTIVE';
    mockStore.users.set(userId, user);

    await logAuditEvent(req.user.id, 'ADMIN_USER_UNBAN', { targetUserId: userId }, req.ip);

    sendSuccess(res, { userId, isBanned: false }, 'User account successfully restored.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get Subscriptions Monitor List
 */
async function getSubscriptionsList(req, res, next) {
  try {
    const subscriptions = Array.from(mockStore.subscriptions.values());
    sendSuccess(res, { subscriptions, count: subscriptions.length }, 'Subscription list retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get Security Audit Trail Logs
 */
async function getAdminAuditLogs(req, res, next) {
  try {
    sendSuccess(res, { auditLogs: mockStore.auditLogs }, 'Security audit logs retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get System Settings & Feature Flags
 */
async function getAppSettings(req, res, next) {
  try {
    sendSuccess(res, { settings: adminStore.settings }, 'App settings retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Update System Settings & Feature Flags
 */
async function updateAppSettings(req, res, next) {
  try {
    const { maintenance_mode, system_broadcast } = req.body;

    if (maintenance_mode !== undefined) {
      adminStore.settings.maintenance_mode = maintenance_mode;
    }
    if (system_broadcast !== undefined) {
      adminStore.settings.system_broadcast = system_broadcast;
    }

    await logAuditEvent(req.user.id, 'ADMIN_FEATURE_FLAGS_UPDATED', { settings: adminStore.settings }, req.ip);

    sendSuccess(res, { settings: adminStore.settings }, 'System app settings updated.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getAdminDashboardStats,
  getUsersList,
  getUserDetails,
  overrideUserPlan,
  banUserAccount,
  unbanUserAccount,
  getSubscriptionsList,
  getAdminAuditLogs,
  getAppSettings,
  updateAppSettings,
};
