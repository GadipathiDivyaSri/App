-- =============================================================================
-- WRINDHAOS COMPLETE UPDATED SUPABASE PRODUCTION DATABASE SCHEMA
-- Version: 2.1.0 (Includes Email OTP Verification, Task Priority Matrix, 
--                 Direct Date & Deadline Scheduling, 2FA, and Admin Backoffice)
-- =============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. USERS & PROFILES MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) DEFAULT 'Student User',
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN', 'SUPER_ADMIN', 'MODERATOR', 'SUPPORT_AGENT')),
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_2fa_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(64),
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_plan VARCHAR(20) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PRO_MONTHLY', 'ELITE_ANNUAL')),
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    xp INT DEFAULT 0 CHECK (xp >= 0),
    referral_code VARCHAR(20) UNIQUE NOT NULL,
    referred_by_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    fcm_device_token TEXT,
    account_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'SUSPENDED', 'BANNED', 'DELETED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_referral ON public.user_profiles(referral_code);

-- User Notification Preferences
CREATE TABLE IF NOT EXISTS public.notification_settings (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    email_notifications_enabled BOOLEAN DEFAULT TRUE,
    preferred_reminder_time TIME DEFAULT '08:00:00',
    habit_reminders_enabled BOOLEAN DEFAULT TRUE,
    expense_alerts_enabled BOOLEAN DEFAULT TRUE,
    study_reminders_enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Email Verification & 2FA OTP Store
CREATE TABLE IF NOT EXISTS public.auth_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- Email address or User ID
    otp_code VARCHAR(10) NOT NULL,
    type VARCHAR(30) NOT NULL CHECK (type IN ('REGISTRATION_EMAIL', 'PASSWORD_RESET', '2FA_LOGIN')),
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auth_otps_lookup ON public.auth_otps(identifier, type, is_used);

-- =============================================================================
-- 2. TASKS & SMART PRIORITY MATRIX MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'Studies' CHECK (category IN ('Studies', 'Career Roadmap', 'Personal Growth', 'Work', 'Others')),
    tag VARCHAR(30) DEFAULT 'STUDY' CHECK (tag IN ('STUDY', 'EXAM', 'WORK', 'PLANNING', 'PERSONAL')),
    priority INT NOT NULL DEFAULT 1 CHECK (priority IN (1, 2, 3, 4)),
    -- P1: High/Urgent (Today), P2: Medium/Schedule (1-3d), P3: Low/Delegate (Later), P4: Eliminate
    quadrant VARCHAR(30) DEFAULT 'Q1_DO_FIRST' CHECK (quadrant IN ('Q1_DO_FIRST', 'Q2_SCHEDULE', 'Q3_DELEGATE', 'Q4_ELIMINATE')),
    due_date DATE NOT NULL,
    due_time TIME DEFAULT '18:00:00',
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_priority ON public.tasks(user_id, priority, is_completed);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON public.tasks(user_id, due_date, due_time);

-- =============================================================================
-- 3. HABITS, STREAKS & REWARDS MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) DEFAULT 'DAILY' CHECK (frequency IN ('DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM')),
    preferred_time TIME DEFAULT '08:00:00',
    icon_name VARCHAR(50) DEFAULT 'auto_awesome_rounded',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    completed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_habit_log_per_day UNIQUE (habit_id, completed_date)
);

CREATE TABLE IF NOT EXISTS public.habit_streaks (
    habit_id UUID PRIMARY KEY REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    current_streak_days INT DEFAULT 0 CHECK (current_streak_days >= 0),
    longest_streak_days INT DEFAULT 0 CHECK (longest_streak_days >= 0),
    last_completed_date DATE
);

CREATE TABLE IF NOT EXISTS public.habit_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    reward_title VARCHAR(100) NOT NULL,
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('EARLY_BIRD', 'ON_FIRE', 'CONSISTENT_MASTER', '7_DAY_STREAK')),
    badge_icon VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. EXPENSES & FINANCIAL TRACKING MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    budget_month DATE NOT NULL,
    total_budget_limit NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_monthly_budget UNIQUE (user_id, budget_month)
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100) NOT NULL, -- 'Food & Drinks', 'Education', 'Transport', 'Shopping', 'Others'
    is_income BOOLEAN DEFAULT FALSE,
    payment_method VARCHAR(50) DEFAULT 'UPI',
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date);

-- =============================================================================
-- 5. CAREER ROADMAP & GOAL HIERARCHY MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    timeframe VARCHAR(20) NOT NULL CHECK (timeframe IN ('SHORT', 'MEDIUM', 'LONG')),
    target_date DATE,
    aligned_purpose TEXT,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_achieved BOOLEAN DEFAULT FALSE,
    achieved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.career_milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    milestone_title VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    target_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    impact_badge VARCHAR(50) DEFAULT 'High Impact',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. STUDY CURRICULUM & PLANNER MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.study_subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject_name VARCHAR(150) NOT NULL,
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    total_hours_logged NUMERIC(6, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.study_units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID NOT NULL REFERENCES public.study_subjects(id) ON DELETE CASCADE,
    unit_title VARCHAR(200) NOT NULL,
    target_hours NUMERIC(5, 2) DEFAULT 10.00,
    completed_hours NUMERIC(5, 2) DEFAULT 0.00,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. CALENDAR EVENTS & FOCUS SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location VARCHAR(150) DEFAULT 'Workspace A',
    event_type VARCHAR(50) DEFAULT 'Focus Session' CHECK (event_type IN ('Focus Session', 'Exam', 'Meeting', 'Task', 'Review')),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_time ON public.calendar_events(user_id, start_time, end_time);

-- =============================================================================
-- 8. REFERRALS & SUBSCRIPTIONS MODULE (Google Play Billing)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL,
    discount_percentage INT DEFAULT 10,
    status VARCHAR(20) DEFAULT 'SUCCESSFUL' CHECK (status IN ('PENDING', 'SUCCESSFUL', 'EXPIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    package_name VARCHAR(150) NOT NULL DEFAULT 'com.wrindhaos.productivity',
    subscription_id VARCHAR(100) NOT NULL, -- Google Play SKU / Product ID
    purchase_token TEXT NOT NULL UNIQUE,     -- Google Play Purchase Token
    plan_tier VARCHAR(20) NOT NULL CHECK (plan_tier IN ('PRO_MONTHLY', 'ELITE_ANNUAL')),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELED', 'EXPIRED', 'PAUSED')),
    auto_renewing BOOLEAN DEFAULT TRUE,
    expiry_timestamp TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    google_order_id VARCHAR(100) NOT NULL UNIQUE,
    amount_inr NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_state VARCHAR(30) DEFAULT 'PAYMENT_RECEIVED',
    purchase_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. ADMIN BACKOFFICE & GOVERNANCE MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'MODERATOR'
        CHECK (role IN ('SUPER_ADMIN', 'FINANCE_ADMIN', 'MODERATOR', 'SUPPORT_AGENT')),
    permissions JSONB NOT NULL DEFAULT '["READ_USERS", "VIEW_ANALYTICS"]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    last_login_ip VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Immutable Audit Log
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    target_user_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- e.g. 'USER_BANNED', 'PRICE_CHANGED', 'NOTIFICATION_BROADCAST'
    resource_type VARCHAR(100),
    resource_id UUID,
    details JSONB,
    old_value JSONB,
    new_value JSONB,
    reason TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_action ON public.admin_audit_logs(action, created_at);

-- User Moderation & Suspension
CREATE TABLE IF NOT EXISTS public.user_moderation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    is_banned BOOLEAN NOT NULL DEFAULT TRUE,
    ban_type VARCHAR(50) DEFAULT 'PERMANENT' CHECK (ban_type IN ('TEMPORARY', 'PERMANENT', 'WARNING_STRIKE')),
    ban_reason TEXT NOT NULL,
    banned_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    banned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    unbanned_at TIMESTAMPTZ,
    unban_reason TEXT
);

-- App Settings & Remote Feature Flags
CREATE TABLE IF NOT EXISTS public.app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    updated_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Push Notification Broadcast Campaigns
CREATE TABLE IF NOT EXISTS public.broadcast_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'ALL' CHECK (target_audience IN ('ALL', 'FREE_TIER', 'PREMIUM_TIER', 'INACTIVE_7D')),
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    delivery_count INT DEFAULT 0,
    click_count INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Daily Analytics Snapshot for Admin Executive Dashboard
CREATE TABLE IF NOT EXISTS public.analytics_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
    total_users INT NOT NULL DEFAULT 0 CHECK (total_users >= 0),
    active_daily_users INT NOT NULL DEFAULT 0 CHECK (active_daily_users >= 0),
    new_signups_today INT NOT NULL DEFAULT 0 CHECK (new_signups_today >= 0),
    premium_conversions INT NOT NULL DEFAULT 0 CHECK (premium_conversions >= 0),
    gross_revenue_inr NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_study_hours_logged NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;

-- Helper Function: Check Admin Permission
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE (user_id = auth.uid() OR email = auth.jwt()->>'email') 
      AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User Policies: Read/Write Own Data Only
CREATE POLICY "Users access own profile" ON public.user_profiles 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own tasks" ON public.tasks 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own habits" ON public.habits 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own expenses" ON public.expenses 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own goals" ON public.goals 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own subjects" ON public.study_subjects 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users access own calendar" ON public.calendar_events 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users view own subscriptions" ON public.subscriptions 
    FOR SELECT TO authenticated 
    USING (user_id = auth.uid());

CREATE POLICY "Users view public app settings" ON public.app_settings 
    FOR SELECT 
    USING (is_public = TRUE);

-- Admin Policies: Full Access to all tables for authenticated Admins
CREATE POLICY "Admins full user_profiles" ON public.user_profiles FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full tasks" ON public.tasks FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full expenses" ON public.expenses FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full subscriptions" ON public.subscriptions FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full audit_logs" ON public.admin_audit_logs FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full moderation" ON public.user_moderation FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full app_settings" ON public.app_settings FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full analytics_snapshots" ON public.analytics_snapshots FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins full broadcast_campaigns" ON public.broadcast_campaigns FOR ALL TO authenticated USING (public.is_admin());
