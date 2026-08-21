export const SUPABASE_SQL_SCHEMA = `-- =============================================================================
-- WRINDHAOS COMPLETE PRODUCTION DATABASE SCHEMA (POSTGRESQL / SUPABASE)
-- Migration Script: 003_complete_wrindhaos_schema.sql
-- Description: Complete Relational Schema aligning Frontend Application Modules,
-- Pricing Strategies (Google Play Billing), and Admin Backoffice Management
-- =============================================================================

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. USERS & PROFILES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) DEFAULT 'Student User',
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    subscription_plan VARCHAR(20) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_sub_plan ON public.user_profiles(subscription_plan);

CREATE TABLE IF NOT EXISTS public.notification_settings (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    push_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,
    preferred_reminder_time TIME DEFAULT '08:00:00',
    habit_reminders_enabled BOOLEAN DEFAULT true,
    expense_alerts_enabled BOOLEAN DEFAULT true,
    study_reminders_enabled BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    referee_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'EXPIRED')),
    reward_xp INT DEFAULT 100,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. HABITS, STREAKS & REWARDS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) DEFAULT 'DAILY' CHECK (frequency IN ('DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM')),
    preferred_time TIME DEFAULT '08:00:00',
    icon_name VARCHAR(50) DEFAULT 'auto_awesome_rounded',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    completed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
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
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('EARLY_BIRD', 'ON_FIRE', 'CONSISTENT_MASTER')),
    badge_icon VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 3. EXPENSES & FINANCIAL HEALTH MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    budget_month DATE NOT NULL,
    total_budget_amount NUMERIC(12, 2) NOT NULL DEFAULT 10000.00,
    currency VARCHAR(10) DEFAULT 'INR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 4. GOALS HIERARCHY & MILESTONES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goals_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    goal_title VARCHAR(150) NOT NULL,
    pyramid_level VARCHAR(20) NOT NULL CHECK (pyramid_level IN ('SHORT_TERM', 'MEDIUM_TERM', 'LONG_TERM')),
    target_date DATE,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.goals_hierarchy(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'CAREER',
    target_date DATE,
    status VARCHAR(20) DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
    completion_percentage INT DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 5. EISENHOWER MATRIX & PRIORITY MATRIX MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.eisenhower_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    quadrant VARCHAR(20) NOT NULL CHECK (quadrant IN ('DO_FIRST', 'SCHEDULE', 'DELEGATE', 'DONT_DO')),
    due_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.priority_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    priority_level VARCHAR(20) NOT NULL CHECK (priority_level IN ('HIGH_PRIORITY', 'MEDIUM_PRIORITY', 'LOW_PRIORITY')),
    due_date DATE,
    preferred_time TIME,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 6. JOURNAL MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body_content TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mood_rating VARCHAR(20) DEFAULT 'NEUTRAL' CHECK (mood_rating IN ('GREAT', 'GOOD', 'NEUTRAL', 'STRESSED', 'LOW')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 7. CAREER DASHBOARD & LEVEL-WISE ROADMAP MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.career_levels (
    level_number INT PRIMARY KEY CHECK (level_number >= 0),
    level_title VARCHAR(100) NOT NULL,
    xp_required INT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS public.career_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    node_title VARCHAR(150) NOT NULL,
    level_number INT NOT NULL REFERENCES public.career_levels(level_number) ON DELETE CASCADE,
    node_order INT NOT NULL DEFAULT 1,
    description TEXT,
    skills_unlocked TEXT,
    status VARCHAR(20) DEFAULT 'LOCKED' CHECK (status IN ('LOCKED', 'AVAILABLE', 'COMPLETED')),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 8. ACADEMIC MODULE (SUBJECTS, UNITS, TOPICS & STUDY SESSIONS)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(20),
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    unit_title VARCHAR(150) NOT NULL,
    unit_order INT DEFAULT 1,
    description TEXT,
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    topic_title VARCHAR(150) NOT NULL,
    topic_order INT DEFAULT 1,
    resource_url TEXT,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    focus_xp_earned INT DEFAULT 0,
    session_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 9. TIME TABLE & CALENDAR SCHEDULE MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.time_table_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity_title VARCHAR(150) NOT NULL,
    activity_type VARCHAR(20) DEFAULT 'STUDY' CHECK (activity_type IN ('STUDY', 'WORK', 'BREAK', 'REVISION')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL DEFAULT '09:00:00',
    end_time TIME NOT NULL DEFAULT '10:30:00',
    location VARCHAR(150) DEFAULT 'Workspace',
    event_type VARCHAR(30) DEFAULT 'FOCUS_SESSION' CHECK (event_type IN ('FOCUS_SESSION', 'MEETING', 'TASK', 'STUDY')),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 10. TO-DO TASKS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.todo_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'Studies',
    due_date DATE,
    preferred_time TIME DEFAULT '08:00:00',
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 11. ANALYTICS & DAILY PERFORMANCE TRACKING MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_daily_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    tasks_completed_count INT DEFAULT 0,
    habits_completed_count INT DEFAULT 0,
    study_duration_minutes INT DEFAULT 0,
    total_expense_amount NUMERIC(12, 2) DEFAULT 0.00,
    daily_focus_score INT DEFAULT 0,
    CONSTRAINT unique_user_daily_analytic UNIQUE (user_id, record_date)
);

-- -----------------------------------------------------------------------------
-- 12. PAYMENTS & GOOGLE PLAY SUBSCRIPTIONS MODULE (PRICING STRATEGY)
-- -----------------------------------------------------------------------------
-- STRICT MANDATE: Google Play Billing ONLY. No Razorpay, Stripe, or PayPal.
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    package_name VARCHAR(150) NOT NULL DEFAULT 'com.wrindhaos.productivity',
    subscription_id VARCHAR(100) NOT NULL, -- Google Play Subscription Product ID
    purchase_token TEXT NOT NULL UNIQUE,     -- Google Play Purchase Token
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELED', 'EXPIRED', 'PAUSED')),
    auto_renewing BOOLEAN DEFAULT true,
    expiry_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    google_order_id VARCHAR(100) NOT NULL UNIQUE,
    amount_micros BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_state VARCHAR(30) DEFAULT 'PAYMENT_RECEIVED',
    purchase_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 13. SUPER ADMIN & BACKOFFICE MANAGEMENT MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'SUPER_ADMIN'
        CHECK (role IN ('SUPER_ADMIN', 'SUPPORT_AGENT', 'FINANCE_ADMIN', 'MODERATOR')),
    permissions JSONB NOT NULL DEFAULT '["READ_USERS", "MANAGE_PLANS", "MANAGE_CONTENT", "MODERATE_USERS"]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

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
    unbanned_at TIMESTAMPTZ,
    CONSTRAINT moderation_dates_valid CHECK (
        (is_banned = TRUE AND unbanned_at IS NULL)
        OR
        (is_banned = FALSE AND unbanned_at IS NOT NULL)
    )
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
    total_users INT NOT NULL DEFAULT 0 CHECK (total_users >= 0),
    free_users INT NOT NULL DEFAULT 0 CHECK (free_users >= 0),
    premium_users INT NOT NULL DEFAULT 0 CHECK (premium_users >= 0),
    active_users INT NOT NULL DEFAULT 0 CHECK (active_users >= 0),
    revenue_inr NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 14. INDEXES FOR MAXIMUM QUERY PERFORMANCE
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 15. ROW LEVEL SECURITY POLICIES
-- -----------------------------------------------------------------------------
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals_hierarchy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE (user_id = auth.uid() OR email = auth.email()) AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin access policies
CREATE POLICY "Admins have full access to user_profiles" ON public.user_profiles FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to subscriptions" ON public.subscriptions FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to payment_history" ON public.payment_history FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to admin_audit_logs" ON public.admin_audit_logs FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to user_moderation" ON public.user_moderation FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to app_settings" ON public.app_settings FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Admins have full access to analytics_snapshots" ON public.analytics_snapshots FOR ALL TO authenticated USING (public.is_admin());

-- User self access policies
CREATE POLICY "Users can view and update own profile" ON public.user_profiles FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Users can view own payment history" ON public.payment_history FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Public read app_settings" ON public.app_settings FOR SELECT USING (true);
`;



