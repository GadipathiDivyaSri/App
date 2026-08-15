-- WrindhaOS Admin & Backoffice Management Supabase Schema Migration
-- Migration 002: Admin Users, Roles, Audit Logs, Moderation, and Feature Flags

-- -----------------------------------------------------------------------------
-- 1. ADMIN USERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'SUPPORT_AGENT', -- SUPER_ADMIN | SUPPORT_AGENT | FINANCE_ADMIN | MODERATOR
  permissions JSONB NOT NULL DEFAULT '["READ_USERS"]',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default Super Admin account
INSERT INTO public.admin_users (email, full_name, role, permissions)
VALUES (
  'admin@wrindhaos.com',
  'WrindhaOS System Administrator',
  'SUPER_ADMIN',
  '["ALL"]'
)
ON CONFLICT (email) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. ADMIN AUDIT LOGS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  target_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- PLAN_OVERRIDE | USER_BAN | USER_UNBAN | FEATURE_FLAG_UPDATE | SYSTEM_BROADCAST
  details JSONB,
  ip_address VARCHAR(50),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. USER MODERATION & BANS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_moderation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_banned BOOLEAN NOT NULL DEFAULT TRUE,
  ban_reason TEXT,
  banned_by UUID REFERENCES public.admin_users(id),
  banned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unbanned_at TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- 4. SYSTEM APP SETTINGS & FEATURE FLAGS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES public.admin_users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.app_settings (key, value, description)
VALUES 
  ('maintenance_mode', '{"enabled": false, "message": "WrindhaOS is undergoing scheduled maintenance."}', 'Global system maintenance toggle'),
  ('system_broadcast', '{"enabled": false, "text": "Welcome to WrindhaOS!"}', 'System-wide announcement banner'),
  ('max_free_habits', '{"limit": 2}', 'Max habits allowed for free plan'),
  ('max_free_subjects', '{"limit": 2}', 'Max subjects allowed for free plan')
ON CONFLICT (key) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 5. DAILY ANALYTICS SNAPSHOTS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.analytics_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  snapshot_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
  total_users INT NOT NULL DEFAULT 0,
  free_users INT NOT NULL DEFAULT 0,
  premium_users INT NOT NULL DEFAULT 0,
  active_subscriptions INT NOT NULL DEFAULT 0,
  mrr_estimate_inr DECIMAL(10,2) DEFAULT 0.00,
  dau_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 6. INDEXES & RLS POLICIES FOR ADMIN TABLES
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_admin_role ON public.admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target ON public.admin_audit_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_user ON public.user_moderation(user_id);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;

-- Strict Admin RLS Policy: Only authenticated super admins or service role keys can read/modify admin tables
CREATE POLICY admin_users_policy ON public.admin_users
  FOR ALL USING (auth.role() = 'service_role' OR auth.uid() IN (SELECT user_id FROM public.admin_users WHERE role = 'SUPER_ADMIN'));

CREATE POLICY admin_audit_policy ON public.admin_audit_logs
  FOR ALL USING (auth.role() = 'service_role' OR auth.uid() IN (SELECT user_id FROM public.admin_users));

CREATE POLICY app_settings_policy ON public.app_settings
  FOR SELECT USING (TRUE); -- Public read allowed for feature flags check
