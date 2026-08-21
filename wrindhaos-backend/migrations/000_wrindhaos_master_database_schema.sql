-- =============================================================================
-- WRINDHAOS COMPLETE MASTER DATABASE SCHEMA (POSTGRESQL / SUPABASE)
-- Architecture: Multi-Module Student OS & Super Admin Backoffice Portal
-- Security: Zero-Admin-Access Data Isolation + Row Level Security (RLS)
-- Version: 2.0.0 (Cleaned Production Schema - No Unwanted Columns)
-- =============================================================================

-- Enable Required PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. USERS & PROFILES MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) DEFAULT 'Student User',
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    subscription_plan VARCHAR(20) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_sub_plan ON public.user_profiles(subscription_plan);

-- Notification Settings
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

-- Referral Rewards System
CREATE TABLE IF NOT EXISTS public.user_referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    referee_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'EXPIRED')),
    reward_xp INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. HABITS, STREAKS & REWARDS MODULE
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    completed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_habit_log_per_day UNIQUE (habit_id, completed_date)
);

CREATE TABLE IF NOT EXISTS public.habit_streaks (
    habit_id UUID PRIMARY KEY REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    last_completed_date DATE
);

CREATE TABLE IF NOT EXISTS public.habit_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    reward_title VARCHAR(100) NOT NULL,
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('EARLY_BIRD', 'ON_FIRE', 'CONSISTENT_MASTER', 'CENTURION')),
    badge_icon VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. EXPENSES & FINANCIAL MANAGEMENT MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    budget_month DATE NOT NULL,
    total_budget_amount NUMERIC(12, 2) NOT NULL DEFAULT 10000.00,
    currency VARCHAR(10) DEFAULT 'INR',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_monthly_budget UNIQUE (user_id, budget_month)
);

CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    category_name VARCHAR(50) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'category',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5'
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
    category_name VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(30) DEFAULT 'UPI',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. GOALS HIERARCHY & MILESTONES MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.goals_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    goal_title VARCHAR(150) NOT NULL,
    pyramid_level VARCHAR(20) NOT NULL CHECK (pyramid_level IN ('SHORT_TERM', 'MEDIUM_TERM', 'LONG_TERM')),
    target_date DATE,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.goals_hierarchy(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'STUDIES',
    target_date DATE,
    status VARCHAR(20) DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
    completion_percentage INT DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.milestone_action_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    milestone_id UUID NOT NULL REFERENCES public.milestones(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    item_title VARCHAR(200) NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. CAREER PATHWAYS & CONTENT CMS MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.career_roadmaps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_type VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    eligibility TEXT,
    exam_pattern JSONB,
    important_dates JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.career_milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    roadmap_id UUID NOT NULL REFERENCES public.career_roadmaps(id) ON DELETE CASCADE,
    phase_title VARCHAR(150) NOT NULL,
    stage_order INT NOT NULL DEFAULT 1,
    duration_months INT DEFAULT 3,
    description TEXT,
    deliverables JSONB DEFAULT '[]'::jsonb
);

-- =============================================================================
-- 6. STUDY TRACKER & SUBJECT MASTERY MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject_name VARCHAR(100) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'menu_book',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    syllabus_progress INT DEFAULT 0 CHECK (syllabus_progress BETWEEN 0 AND 100),
    target_hours NUMERIC(6, 1) DEFAULT 100.0,
    completed_hours NUMERIC(6, 1) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_title VARCHAR(150) NOT NULL,
    unit_order INT DEFAULT 1,
    is_completed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    topic_title VARCHAR(150) NOT NULL,
    mastery_level VARCHAR(20) DEFAULT 'UNTOUCHED' CHECK (mastery_level IN ('UNTOUCHED', 'LEARNING', 'REVISED', 'MASTERED')),
    revision_count INT DEFAULT 0,
    last_revised_at TIMESTAMPTZ,
    next_revision_due DATE
);

CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    focus_xp_earned INT DEFAULT 0,
    session_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. TIME TABLE, CALENDAR & EISENHOWER PRIORITY MATRIX
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.time_table_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity_title VARCHAR(150) NOT NULL,
    activity_type VARCHAR(20) DEFAULT 'STUDY' CHECK (activity_type IN ('STUDY', 'WORK', 'BREAK', 'REVISION')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL DEFAULT '09:00:00',
    end_time TIME NOT NULL DEFAULT '10:30:00',
    event_type VARCHAR(30) DEFAULT 'FOCUS_SESSION' CHECK (event_type IN ('FOCUS_SESSION', 'MEETING', 'TASK', 'STUDY')),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.todo_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'Studies',
    due_date DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    priority_quadrant VARCHAR(20) DEFAULT 'Q2' CHECK (priority_quadrant IN ('Q1_DO_FIRST', 'Q2_SCHEDULE', 'Q3_DELEGATE', 'Q4_DONT_DO')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. PRIVATE ENCRYPTED JOURNAL (OWNER-ONLY ZERO-ADMIN ACCESS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content_encrypted TEXT NOT NULL,
    mood_rating VARCHAR(30) DEFAULT 'Productive',
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. PRICING PLANS & GOOGLE PLAY BILLING MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_inr NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    billing_period VARCHAR(20) NOT NULL CHECK (billing_period IN ('FREE', 'MONTHLY', 'YEARLY')),
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    limits JSONB NOT NULL DEFAULT '{"max_habits": 5, "max_subjects": 3, "journal_cloud_backup": false}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO public.subscription_plans (slug, name, description, price_inr, billing_period, features, limits)
VALUES
('free', 'Free Student Plan', 'Essential discipline tools for exam prep', 0.00, 'FREE', '["Daily habit tracking (5 habits)", "3 subjects mastery", "Eisenhower matrix", "Basic calendar"]'::jsonb, '{"max_habits": 5, "max_subjects": 3, "journal_cloud_backup": false}'::jsonb),
('premium_monthly', 'WrindhaOS Pro Monthly', 'Unlimited mastery, encrypted journal & detailed analytics', 199.00, 'MONTHLY', '["Unlimited habits & subjects", "Encrypted private journal backup", "Advanced cohort analytics", "Custom notification broadcasts"]'::jsonb, '{"max_habits": -1, "max_subjects": -1, "journal_cloud_backup": true}'::jsonb),
('premium_yearly', 'WrindhaOS Pro Yearly', 'Best value for serious competitive exam aspirants', 1499.00, 'YEARLY', '["All Pro features", "Full syllabus roadmap packs", "Priority support"]'::jsonb, '{"max_habits": -1, "max_subjects": -1, "journal_cloud_backup": true}'::jsonb)
ON CONFLICT (slug) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    package_name VARCHAR(150) NOT NULL DEFAULT 'com.wrindhaos.productivity',
    subscription_id VARCHAR(100) NOT NULL,
    purchase_token TEXT NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELED', 'EXPIRED', 'PAUSED')),
    auto_renewing BOOLEAN DEFAULT TRUE,
    expiry_timestamp TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    google_order_id VARCHAR(100) NOT NULL UNIQUE,
    amount_micros BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_state VARCHAR(30) DEFAULT 'PAYMENT_RECEIVED',
    purchase_timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. SUPER ADMIN & BACKOFFICE MANAGEMENT MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'SUPER_ADMIN'
        CHECK (role IN ('SUPER_ADMIN', 'SUPPORT_AGENT', 'FINANCE_ADMIN', 'MODERATOR')),
    permissions JSONB NOT NULL DEFAULT '["READ_USERS", "MANAGE_PLANS", "MANAGE_CONTENT", "MODERATE_USERS", "BROADCAST_NOTIFICATIONS"]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO public.admin_users (email, full_name, role, permissions, is_active)
VALUES ('admin@wrindhaos.com', 'WrindhaOS System Administrator', 'SUPER_ADMIN', '["READ_USERS", "MANAGE_PLANS", "MANAGE_CONTENT", "MODERATE_USERS", "BROADCAST_NOTIFICATIONS"]'::jsonb, TRUE)
ON CONFLICT (email) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    target_user_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
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

CREATE TABLE IF NOT EXISTS public.user_moderation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    is_banned BOOLEAN NOT NULL DEFAULT TRUE,
    ban_reason TEXT,
    banned_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    banned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unbanned_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.analytics_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
    total_users INT NOT NULL DEFAULT 0,
    free_users INT NOT NULL DEFAULT 0,
    premium_users INT NOT NULL DEFAULT 0,
    active_users INT NOT NULL DEFAULT 0,
    revenue_inr NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'ALL' CHECK (target_audience IN ('ALL', 'FREE', 'PREMIUM')),
    sent_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    scheduled_for TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    delivered_count INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.legal_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES public.admin_users(id) ON DELETE SET NULL
);

-- =============================================================================
-- 11. INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON public.habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON public.habit_logs(user_id, completed_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON public.calendar_events(user_id, event_date);
CREATE INDEX IF NOT EXISTS idx_todo_tasks_user ON public.todo_tasks(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_units_subject ON public.units(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_unit ON public.topics(unit_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON public.subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payment_history_user ON public.payment_history(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action ON public.admin_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_user_moderation_user ON public.user_moderation(user_id);

-- =============================================================================
-- 12. ROW LEVEL SECURITY (RLS) & ACCESS POLICIES
-- =============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals_hierarchy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;

-- Helper function for Admin verification
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE (user_id = auth.uid() OR email = auth.email()) AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User Row-Level Isolation Policies
CREATE POLICY "Users can manage own profile" ON public.user_profiles FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can manage own habits" ON public.habits FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can manage own habit logs" ON public.habit_logs FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can manage own expenses" ON public.expenses FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can manage own goals" ON public.goals_hierarchy FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can manage own subjects" ON public.subjects FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Zero Admin Access on Private Journal (Strictly Owner-Only)
CREATE POLICY "Owner-Only Journal Access" ON public.journal_entries FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Admin Operational Access Policies
CREATE POLICY "Admins have full access to user_profiles metadata" ON public.user_profiles FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to subscriptions" ON public.subscriptions FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to payment_history" ON public.payment_history FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to admin_audit_logs" ON public.admin_audit_logs FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to user_moderation" ON public.user_moderation FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to app_settings" ON public.app_settings FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to analytics_snapshots" ON public.analytics_snapshots FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Public read app_settings" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "Public read legal_documents" ON public.legal_documents FOR SELECT USING (true);
