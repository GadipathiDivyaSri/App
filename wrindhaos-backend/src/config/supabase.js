const { createClient } = require('@supabase/supabase-js');
const config = require('./env');

let supabase = null;
let supabaseAdmin = null;

if (config.supabase.url && config.supabase.anonKey) {
  try {
    supabase = createClient(config.supabase.url, config.supabase.anonKey);
    if (config.supabase.serviceRoleKey) {
      supabaseAdmin = createClient(config.supabase.url, config.supabase.serviceRoleKey);
    }
  } catch (err) {
    console.warn('[SUPABASE] Could not initialize live Supabase client. Operating in safe fallback mode.');
  }
}

// Memory database cache fallback
const mockStore = {
  users: new Map(),
  identities: new Map(),
  subscriptions: new Map(),
  todos: new Map(),
  habits: new Map(),
  habitLogs: new Map(),
  subjects: new Map(),
  calendarEvents: new Map(),
  eisenhowerTasks: new Map(),
  expenses: new Map(),
  monthlyBudgets: new Map(),
  referrals: new Map(),
  referralRewards: new Map(),
  deviceTokens: new Map(),
  auditLogs: [],
  otps: new Map(),
};

module.exports = {
  supabase,
  supabaseAdmin,
  mockStore,
};
