import { createClient, SupabaseClient } from '@supabase/supabase-js';
import {
  WrindhaUser,
  AdminUser,
  UserActivityLog,
  AccountDeletionRequest,
  AdminAuditLog,
  SubscriptionPlan,
  UserSubscription,
  CareerCategory,
  CareerPath,
  CareerMilestone,
  AppNotification,
  AppSettings,
  LegalDocument,
  WebsiteSettings,
  AppEvent,
} from '../types';
import { INITIAL_PLANS } from './defaultPlanData';
import {
  INITIAL_CAREER_CATEGORIES,
  INITIAL_CAREER_PATHS,
  INITIAL_CAREER_MILESTONES,
} from './defaultContentData';
import { INITIAL_APP_SETTINGS, INITIAL_NOTIFICATIONS } from './defaultSettingsData';
import { INITIAL_WEBSITE_SETTINGS, INITIAL_LEGAL_DOCUMENTS } from './defaultWebsiteAndLegalData';
import { INITIAL_APP_EVENTS } from './defaultAnalyticsData';

// Default environment variables
const ENV_SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || '';
const ENV_SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

// Local storage keys for runtime persistence (v_clean represents unseeded fresh state)
const LS_SUPABASE_URL_KEY = 'wrindha_supabase_url';
const LS_SUPABASE_ANON_KEY = 'wrindha_supabase_anon_key';
const LS_DEMO_USERS_KEY = 'wrindha_demo_users_clean_v1';
const LS_DEMO_AUDIT_LOGS_KEY = 'wrindha_demo_audit_logs_clean_v1';
const LS_DEMO_DELETION_REQ_KEY = 'wrindha_demo_deletion_reqs_clean_v1';
const LS_DEMO_PLANS_KEY = 'wrindha_demo_plans_clean_v1';
const LS_DEMO_SUBSCRIPTIONS_KEY = 'wrindha_demo_subscriptions_clean_v1';

// Phase 4: App Content Keys
const LS_DEMO_CAREER_CATS_KEY = 'wrindha_demo_career_cats_clean_v1';
const LS_DEMO_CAREER_PATHS_KEY = 'wrindha_demo_career_paths_clean_v1';
const LS_DEMO_CAREER_MILESTONES_KEY = 'wrindha_demo_career_milestones_clean_v1';

// Phase 5: Notifications & App Settings Keys
const LS_DEMO_NOTIFICATIONS_KEY = 'wrindha_demo_notifications_clean_v1';
const LS_DEMO_APP_SETTINGS_KEY = 'wrindha_demo_app_settings_clean_v1';
const LS_DEMO_FCM_CONFIG_KEY = 'wrindha_demo_fcm_config_clean_v1';

// Phase 6: Website & Legal Keys
const LS_DEMO_WEBSITE_SETTINGS_KEY = 'wrindha_demo_website_settings_clean_v1';
const LS_DEMO_LEGAL_DOCS_KEY = 'wrindha_demo_legal_docs_clean_v1';

// Phase 7: Analytics Events Keys
const LS_DEMO_APP_EVENTS_KEY = 'wrindha_demo_app_events_clean_v1';

// Purge legacy seeded local storage keys once on module load
try {
  const legacyKeys = [
    'wrindha_demo_users_v2',
    'wrindha_demo_audit_logs',
    'wrindha_demo_deletion_reqs',
    'wrindha_demo_plans_v3',
    'wrindha_demo_subscriptions_v3',
    'wrindha_demo_boards_v1',
    'wrindha_demo_classes_v1',
    'wrindha_demo_subjects_v1',
    'wrindha_demo_units_v1',
    'wrindha_demo_topics_v1',
    'wrindha_demo_career_cats_v1',
    'wrindha_demo_career_paths_v1',
    'wrindha_demo_career_milestones_v1',
    'wrindha_demo_notifications_v1',
    'wrindha_demo_app_settings_v1',
    'wrindha_demo_fcm_config_v1',
    'wrindha_demo_website_settings_v1',
    'wrindha_demo_legal_docs_v1',
    'wrindha_demo_app_events_v1',
  ];
  legacyKeys.forEach((k) => localStorage.removeItem(k));
} catch {
  // ignore storage errors in restricted contexts
}


export function getSupabaseCredentials(): { url: string; anonKey: string; isConfigured: boolean; isCustom: boolean } {
  const customUrl = localStorage.getItem(LS_SUPABASE_URL_KEY) || '';
  const customKey = localStorage.getItem(LS_SUPABASE_ANON_KEY) || '';

  const url = customUrl || ENV_SUPABASE_URL;
  const anonKey = customKey || ENV_SUPABASE_ANON_KEY;

  const isConfigured = Boolean(
    url && 
    anonKey && 
    url !== 'https://your-project.supabase.co' && 
    anonKey !== 'your-anon-public-key' &&
    url.startsWith('https://')
  );

  return {
    url,
    anonKey,
    isConfigured,
    isCustom: Boolean(customUrl && customKey),
  };
}

export function saveCustomCredentials(url: string, anonKey: string) {
  if (!url || !anonKey) {
    localStorage.removeItem(LS_SUPABASE_URL_KEY);
    localStorage.removeItem(LS_SUPABASE_ANON_KEY);
  } else {
    localStorage.setItem(LS_SUPABASE_URL_KEY, url.trim());
    localStorage.setItem(LS_SUPABASE_ANON_KEY, anonKey.trim());
  }
  initClient();
}

let supabaseInstance: SupabaseClient | null = null;

function initClient(): SupabaseClient | null {
  const { url, anonKey, isConfigured } = getSupabaseCredentials();
  if (isConfigured) {
    try {
      supabaseInstance = createClient(url, anonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      });
      return supabaseInstance;
    } catch (err) {
      console.error('Failed to initialize Supabase client:', err);
      supabaseInstance = null;
      return null;
    }
  }
  supabaseInstance = null;
  return null;
}

initClient();

export function getSupabaseClient(): SupabaseClient | null {
  if (!supabaseInstance) {
    return initClient();
  }
  return supabaseInstance;
}

// ==========================================
// SEEDED DEMO DATA STORE FOR LOCAL TESTING
// (When live Supabase credentials are not connected)
// ==========================================

export const DEMO_ADMIN: AdminUser = {
  id: 'adm-001',
  user_id: 'auth-usr-001',
  name: 'Wrindha Lead Admin',
  email: 'admin@wrindhaos.com',
  role: 'SUPER_ADMIN',
  is_active: true,
  created_at: new Date(Date.now() - 90 * 86400000).toISOString(),
  updated_at: new Date().toISOString(),
};

const BASE_DEMO_USERS: WrindhaUser[] = [];

export function getDemoUsers(): WrindhaUser[] {
  const stored = localStorage.getItem(LS_DEMO_USERS_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      return BASE_DEMO_USERS;
    }
  }
  localStorage.setItem(LS_DEMO_USERS_KEY, JSON.stringify(BASE_DEMO_USERS));
  return BASE_DEMO_USERS;
}

export function saveDemoUsers(users: WrindhaUser[]) {
  localStorage.setItem(LS_DEMO_USERS_KEY, JSON.stringify(users));
}

export function getDemoAuditLogs(): AdminAuditLog[] {
  const stored = localStorage.getItem(LS_DEMO_AUDIT_LOGS_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      return [];
    }
  }
  return [];
}

export function addDemoAuditLog(log: AdminAuditLog) {
  const logs = getDemoAuditLogs();
  logs.unshift(log);
  localStorage.setItem(LS_DEMO_AUDIT_LOGS_KEY, JSON.stringify(logs));
}

export function getDemoDeletionRequests(): AccountDeletionRequest[] {
  const stored = localStorage.getItem(LS_DEMO_DELETION_REQ_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      return [];
    }
  }
  return [];
}

export function addDemoDeletionRequest(req: AccountDeletionRequest) {
  const reqs = getDemoDeletionRequests();
  reqs.unshift(req);
  localStorage.setItem(LS_DEMO_DELETION_REQ_KEY, JSON.stringify(reqs));
}

// ==========================================
// PHASE 3: DEMO PLANS & SUBSCRIPTIONS DATA
// ==========================================

export function getDemoPlans(): SubscriptionPlan[] {
  const stored = localStorage.getItem(LS_DEMO_PLANS_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      return INITIAL_PLANS;
    }
  }
  localStorage.setItem(LS_DEMO_PLANS_KEY, JSON.stringify(INITIAL_PLANS));
  return INITIAL_PLANS;
}

export function saveDemoPlans(plans: SubscriptionPlan[]) {
  localStorage.setItem(LS_DEMO_PLANS_KEY, JSON.stringify(plans));
}

export function getDemoSubscriptions(): UserSubscription[] {
  const stored = localStorage.getItem(LS_DEMO_SUBSCRIPTIONS_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      // fallback to generated
    }
  }

  // Generate initial default FREE subscriptions for users who don't have one
  const users = getDemoUsers();
  const plans = getDemoPlans();
  const freePlan = plans.find((p) => p.slug === 'free') || INITIAL_PLANS[0];

  const initialSubs: UserSubscription[] = users.map((u, i) => {
    return {
      id: `sub-wrindha-${i + 101}`,
      user_id: u.id,
      plan_id: freePlan.id,
      status: 'ACTIVE' as const,
      started_at: u.created_at,
      current_period_start: null,
      current_period_end: null,
      trial_started_at: null,
      trial_ends_at: null,
      cancelled_at: null,
      ended_at: null,
      created_at: u.created_at,
      updated_at: u.updated_at || u.created_at,
    };
  });

  localStorage.setItem(LS_DEMO_SUBSCRIPTIONS_KEY, JSON.stringify(initialSubs));
  return initialSubs;
}

export function saveDemoSubscriptions(subs: UserSubscription[]) {
  localStorage.setItem(LS_DEMO_SUBSCRIPTIONS_KEY, JSON.stringify(subs));
}

// ==========================================
// PHASE 4: APP CONTENT DEMO STORE HELPERS
// ==========================================

export function getDemoCareerCategories(): CareerCategory[] {
  const cached = localStorage.getItem(LS_DEMO_CAREER_CATS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_CAREER_CATS_KEY, JSON.stringify(INITIAL_CAREER_CATEGORIES));
  return INITIAL_CAREER_CATEGORIES;
}

export function saveDemoCareerCategories(cats: CareerCategory[]) {
  localStorage.setItem(LS_DEMO_CAREER_CATS_KEY, JSON.stringify(cats));
}

export function getDemoCareerPaths(): CareerPath[] {
  const cached = localStorage.getItem(LS_DEMO_CAREER_PATHS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_CAREER_PATHS_KEY, JSON.stringify(INITIAL_CAREER_PATHS));
  return INITIAL_CAREER_PATHS;
}

export function saveDemoCareerPaths(paths: CareerPath[]) {
  localStorage.setItem(LS_DEMO_CAREER_PATHS_KEY, JSON.stringify(paths));
}

export function getDemoCareerMilestones(): CareerMilestone[] {
  const cached = localStorage.getItem(LS_DEMO_CAREER_MILESTONES_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_CAREER_MILESTONES_KEY, JSON.stringify(INITIAL_CAREER_MILESTONES));
  return INITIAL_CAREER_MILESTONES;
}

export function saveDemoCareerMilestones(milestones: CareerMilestone[]) {
  localStorage.setItem(LS_DEMO_CAREER_MILESTONES_KEY, JSON.stringify(milestones));
}

// Phase 5: Notifications & App Settings Demo Helpers
export function getDemoNotifications(): AppNotification[] {
  const cached = localStorage.getItem(LS_DEMO_NOTIFICATIONS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_NOTIFICATIONS_KEY, JSON.stringify(INITIAL_NOTIFICATIONS));
  return INITIAL_NOTIFICATIONS;
}

export function saveDemoNotifications(notifications: AppNotification[]) {
  localStorage.setItem(LS_DEMO_NOTIFICATIONS_KEY, JSON.stringify(notifications));
}

export function addDemoNotification(notification: AppNotification) {
  const list = getDemoNotifications();
  saveDemoNotifications([notification, ...list]);
}

export function getDemoAppSettings(): AppSettings {
  const cached = localStorage.getItem(LS_DEMO_APP_SETTINGS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_APP_SETTINGS_KEY, JSON.stringify(INITIAL_APP_SETTINGS));
  return INITIAL_APP_SETTINGS;
}

export function saveDemoAppSettings(settings: AppSettings) {
  localStorage.setItem(LS_DEMO_APP_SETTINGS_KEY, JSON.stringify(settings));
}

export function getFCMConfigStatus(): { isConfigured: boolean; details: string; configuredAt?: string | null } {
  // Check if custom FCM config is in storage or server env
  const cached = localStorage.getItem(LS_DEMO_FCM_CONFIG_KEY);
  if (cached) {
    try {
      const parsed = JSON.parse(cached);
      return parsed;
    } catch {
      // fallback
    }
  }
  // By default in unconfigured environment:
  return {
    isConfigured: false,
    details: 'FCM is not configured. Firebase server credentials must be set in server-side environment variables.',
    configuredAt: null,
  };
}

export function setFCMConfigStatus(isConfigured: boolean, details: string) {
  localStorage.setItem(
    LS_DEMO_FCM_CONFIG_KEY,
    JSON.stringify({
      isConfigured,
      details,
      configuredAt: isConfigured ? new Date().toISOString() : null,
    })
  );
}

// Phase 6: Website & Legal Demo Helpers
export function getDemoWebsiteSettings(): WebsiteSettings {
  const cached = localStorage.getItem(LS_DEMO_WEBSITE_SETTINGS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_WEBSITE_SETTINGS_KEY, JSON.stringify(INITIAL_WEBSITE_SETTINGS));
  return INITIAL_WEBSITE_SETTINGS;
}

export function saveDemoWebsiteSettings(settings: WebsiteSettings) {
  localStorage.setItem(LS_DEMO_WEBSITE_SETTINGS_KEY, JSON.stringify(settings));
}

export function getDemoLegalDocuments(): LegalDocument[] {
  const cached = localStorage.getItem(LS_DEMO_LEGAL_DOCS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_LEGAL_DOCS_KEY, JSON.stringify(INITIAL_LEGAL_DOCUMENTS));
  return INITIAL_LEGAL_DOCUMENTS;
}

export function saveDemoLegalDocuments(docs: LegalDocument[]) {
  localStorage.setItem(LS_DEMO_LEGAL_DOCS_KEY, JSON.stringify(docs));
}

// Phase 7: Analytics App Events Demo Store Helpers
export function getDemoAppEvents(): AppEvent[] {
  const cached = localStorage.getItem(LS_DEMO_APP_EVENTS_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      // fallback
    }
  }
  localStorage.setItem(LS_DEMO_APP_EVENTS_KEY, JSON.stringify(INITIAL_APP_EVENTS));
  return INITIAL_APP_EVENTS;
}

export function saveDemoAppEvents(events: AppEvent[]) {
  localStorage.setItem(LS_DEMO_APP_EVENTS_KEY, JSON.stringify(events));
}

export function addDemoAppEvent(event: Omit<AppEvent, 'id' | 'created_at'> & { id?: string; created_at?: string }): AppEvent {
  const events = getDemoAppEvents();
  const newEvt: AppEvent = {
    id: event.id || `evt-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
    user_id: event.user_id,
    event_name: event.event_name,
    metadata: event.metadata || null,
    created_at: event.created_at || new Date().toISOString(),
  };
  events.unshift(newEvt);
  saveDemoAppEvents(events);
  return newEvt;
}





export const DEMO_USER_ACTIVITIES: Record<string, UserActivityLog[]> = {};
